import Foundation

@MainActor
final class ServerSettings: ObservableObject {
    @Published var serverBaseURLString: String {
        didSet {
            UserDefaults.standard.set(serverBaseURLString, forKey: Self.baseURLKey)
        }
    }

    @Published private(set) var serverAccessToken: String {
        didSet {
            UserDefaults.standard.set(serverAccessToken, forKey: Self.accessTokenKey)
        }
    }

    @Published private(set) var associatedServerID: String {
        didSet {
            UserDefaults.standard.set(associatedServerID, forKey: Self.serverIDKey)
        }
    }

    @Published var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: Self.languageKey)
        }
    }

    var serverBaseURL: URL? {
        let value = serverBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !value.isEmpty,
            let components = URLComponents(string: value),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            components.host?.isEmpty == false
        else {
            return nil
        }
        return components.url
    }

    var hasServerAddress: Bool {
        !serverBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        let savedURL = UserDefaults.standard.string(forKey: Self.baseURLKey) ?? ""
        serverBaseURLString = ProcessInfo.processInfo.environment["YTB_MUSIC_TV_SERVER_URL"] ?? savedURL
        serverAccessToken = UserDefaults.standard.string(forKey: Self.accessTokenKey) ?? ""
        associatedServerID = UserDefaults.standard.string(forKey: Self.serverIDKey) ?? ""
        languageCode = UserDefaults.standard.string(forKey: Self.languageKey) ?? "system"
    }

    func selectServer(_ url: URL) {
        serverBaseURLString = url.absoluteString
    }

    func saveAssociation(_ result: PairingResult, serverID: String) {
        serverAccessToken = result.token
        associatedServerID = serverID
    }

    func clearAssociation() {
        serverAccessToken = ""
        associatedServerID = ""
    }

    private static let baseURLKey = "YTBMusicTV.serverBaseURL"
    private static let accessTokenKey = "YTBMusicTV.serverAccessToken"
    private static let serverIDKey = "YTBMusicTV.serverID"
    private static let languageKey = "YTBMusicTV.languageCode"
}
