import Darwin
import Foundation

struct DiscoveredServer: Identifiable, Equatable {
    let id: String
    let name: String
    let url: URL
}

@MainActor
final class ServerDiscovery: ObservableObject {
    @Published private(set) var servers: [DiscoveredServer] = []
    @Published private(set) var isSearching = false

    private let discoveryPort: UInt16 = 4175
    private let requestMessage = Data("ytb-music-tv:discover:v1".utf8)
    private let socketQueue = DispatchQueue(label: "YTBMusicTV.ServerDiscovery")
    private var socketFD: Int32 = -1
    private var readSource: DispatchSourceRead?
    private var searchTask: Task<Void, Never>?

    deinit {
        searchTask?.cancel()
        if let readSource {
            readSource.cancel()
        } else if socketFD >= 0 {
            Darwin.close(socketFD)
        }
    }

    func start() {
        guard socketFD < 0 else {
            refresh()
            return
        }

        let descriptor = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard descriptor >= 0 else { return }

        var enabled: Int32 = 1
        guard setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_BROADCAST,
            &enabled,
            socklen_t(MemoryLayout<Int32>.size)
        ) == 0 else {
            Darwin.close(descriptor)
            return
        }

        var localAddress = sockaddr_in()
        localAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        localAddress.sin_family = sa_family_t(AF_INET)
        localAddress.sin_port = 0
        localAddress.sin_addr = in_addr(s_addr: INADDR_ANY)

        let bindResult = withUnsafePointer(to: &localAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            Darwin.close(descriptor)
            return
        }

        socketFD = descriptor
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: socketQueue)
        source.setEventHandler { [weak self] in
            self?.receiveResponses(from: descriptor)
        }
        source.setCancelHandler {
            Darwin.close(descriptor)
        }
        readSource = source
        source.resume()
        refresh()
    }

    func refresh() {
        guard socketFD >= 0 else {
            start()
            return
        }

        searchTask?.cancel()
        isSearching = true
        searchTask = Task { [weak self] in
            guard let self else { return }
            for _ in 0 ..< 3 {
                sendDiscoveryRequest()
                try? await Task.sleep(for: .milliseconds(450))
                if Task.isCancelled { return }
            }
            isSearching = false
        }
    }

    private func sendDiscoveryRequest() {
        var destination = sockaddr_in()
        destination.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        destination.sin_family = sa_family_t(AF_INET)
        destination.sin_port = discoveryPort.bigEndian
        inet_pton(AF_INET, "255.255.255.255", &destination.sin_addr)

        requestMessage.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            withUnsafePointer(to: &destination) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    _ = Darwin.sendto(
                        socketFD,
                        baseAddress,
                        bytes.count,
                        0,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }
    }

    nonisolated private func receiveResponses(from descriptor: Int32) {
        var buffer = [UInt8](repeating: 0, count: 2048)
        var remoteAddress = sockaddr_in()
        var remoteLength = socklen_t(MemoryLayout<sockaddr_in>.size)

        let count = withUnsafeMutablePointer(to: &remoteAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.recvfrom(descriptor, &buffer, buffer.count, 0, $0, &remoteLength)
            }
        }
        guard count > 0 else { return }

        var address = remoteAddress.sin_addr
        var addressBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &address, &addressBuffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
            return
        }

        let host = String(cString: addressBuffer)
        let data = Data(buffer.prefix(count))
        guard let payload = try? JSONDecoder().decode(DiscoveryPayload.self, from: data),
              payload.service == "ytb-music-tv-server",
              (1 ... 65_535).contains(payload.port),
              let url = URL(string: "http://\(host):\(payload.port)")
        else {
            return
        }

        let server = DiscoveredServer(id: payload.id, name: payload.name, url: url)
        Task { @MainActor [weak self] in
            self?.upsert(server)
        }
    }

    private func upsert(_ server: DiscoveredServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
            servers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

private struct DiscoveryPayload: Decodable {
    let service: String
    let id: String
    let name: String
    let port: Int
}
