import AppIntents
import Foundation

enum YTBMusicTVDestination: String, AppEnum {
    case home
    case search
    case nowPlaying
    case settings

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "YTB Music TV Destination"

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .home: "Home",
        .search: "Search",
        .nowPlaying: "Now Playing",
        .settings: "Settings",
    ]
}

@MainActor
final class AppIntentRouter: ObservableObject {
    static let shared = AppIntentRouter()

    @Published private(set) var requestedDestination: YTBMusicTVDestination?
    @Published private(set) var requestID = UUID()

    private init() {}

    func request(_ destination: YTBMusicTVDestination) {
        requestedDestination = destination
        requestID = UUID()
    }
}

struct OpenYTBMusicTVDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open YTB Music TV"
    static let description = IntentDescription("Open YTB Music TV at Home, Search, Now Playing, or Settings.")
    static let openAppWhenRun = true

    @Parameter(title: "Destination", default: .home)
    var destination: YTBMusicTVDestination

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.request(destination)
        return .result()
    }
}

struct YTBMusicTVAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenYTBMusicTVDestinationIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Open a destination in \(.applicationName)",
            ],
            shortTitle: "Open YTB Music TV",
            systemImageName: "play.tv.fill"
        )
    }
}
