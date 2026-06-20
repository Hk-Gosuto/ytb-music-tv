import Foundation

struct L10n {
    let languageCode: String

    var resolvedLanguage: String {
        if languageCode == "zh" || languageCode == "en" {
            return languageCode
        }
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        return preferred.lowercased().hasPrefix("zh") ? "zh" : "en"
    }

    func text(_ key: String) -> String {
        Self.values[resolvedLanguage]?[key] ?? Self.values["en"]?[key] ?? key
    }

    static let languageOptions = [
        LanguageOption(id: "system", en: "System", zh: "跟随系统"),
        LanguageOption(id: "en", en: "English", zh: "English"),
        LanguageOption(id: "zh", en: "中文", zh: "中文"),
    ]

    private static let values: [String: [String: String]] = [
        "en": [
            "app.name": "YTB Music TV",
            "nav.home": "Home",
            "nav.search": "Search",
            "nav.settings": "Settings",
            "nav.nowPlaying": "Now Playing",
            "home.title": "Home",
            "home.subtitle": "Library, recommendations and trending music",
            "home.relisten": "Listen Again",
            "home.library": "Your Library",
            "home.recommended": "Recommended",
            "home.trending": "Trending Now",
            "home.empty": "Connect the server and load your library.",
            "home.loading": "Loading your music…",
            "search.placeholder": "Search songs, albums, artists",
            "search.button": "Search",
            "settings.title": "Settings",
            "settings.connection": "Connection",
            "settings.association": "Device Association",
            "settings.features": "Features",
            "settings.language": "Language",
            "settings.system": "System",
            "settings.serverURL": "Server URL",
            "settings.connect": "Connect",
            "settings.connected": "Connected",
            "settings.disconnected": "Disconnected",
            "settings.notLoggedIn": "Not logged in",
            "settings.notAssociated": "Not associated",
            "settings.associated": "Associated",
            "settings.deviceCode": "6-digit device code",
            "settings.associate": "Associate",
            "settings.discoveredServers": "Nearby servers",
            "settings.refreshDiscovery": "Refresh nearby servers",
            "settings.searchingServers": "Searching for nearby servers…",
            "settings.noServersFound": "No nearby servers found.",
            "settings.adFiltering": "Ad filtering",
            "settings.skipDisliked": "Skip disliked songs",
            "settings.preferVideo": "Prefer video playback",
            "settings.quality": "Quality",
            "settings.selectedLibrary": "Selected Library",
            "settings.invalidURL": "Enter a valid HTTP or HTTPS server URL.",
            "player.noMedia": "No media selected",
            "player.loading": "Loading",
            "player.shuffle": "Shuffle",
            "player.repeatOne": "Repeat One",
            "player.previous": "Previous",
            "player.next": "Next",
            "player.play": "Play",
            "player.pause": "Pause",
            "player.like": "Like",
            "player.dislike": "Dislike",
            "player.back": "Back",
            "player.queue": "Queue",
            "player.emptyQueue": "The queue is empty",
            "player.closePanel": "Close panel",
            "player.position": "Playback position",
            "player.remaining": "remaining",
            "player.showControls": "Show playback controls",
        ],
        "zh": [
            "app.name": "YTB Music TV",
            "nav.home": "首页",
            "nav.search": "搜索",
            "nav.settings": "设置",
            "nav.nowPlaying": "正在播放",
            "home.title": "首页",
            "home.subtitle": "媒体库、推荐和当下热门音乐",
            "home.relisten": "再听一遍",
            "home.library": "你的媒体库",
            "home.recommended": "为你推荐",
            "home.trending": "当下热门",
            "home.empty": "请先连接服务端并加载媒体库。",
            "home.loading": "正在加载你的音乐…",
            "search.placeholder": "搜索歌曲、专辑、音乐人",
            "search.button": "搜索",
            "settings.title": "设置",
            "settings.connection": "连接",
            "settings.association": "设备关联",
            "settings.features": "功能",
            "settings.language": "语言",
            "settings.system": "跟随系统",
            "settings.serverURL": "服务端地址",
            "settings.connect": "连接",
            "settings.connected": "已连接",
            "settings.disconnected": "未连接",
            "settings.notLoggedIn": "未登录",
            "settings.notAssociated": "未关联",
            "settings.associated": "已关联",
            "settings.deviceCode": "6 位设备码",
            "settings.associate": "关联",
            "settings.discoveredServers": "附近的服务端",
            "settings.refreshDiscovery": "刷新附近的服务端",
            "settings.searchingServers": "正在查找附近的服务端…",
            "settings.noServersFound": "未发现附近的服务端。",
            "settings.adFiltering": "过滤广告",
            "settings.skipDisliked": "跳过不喜欢的歌曲",
            "settings.preferVideo": "优先视频播放",
            "settings.quality": "画质",
            "settings.selectedLibrary": "选择的媒体库",
            "settings.invalidURL": "请输入有效的 HTTP 或 HTTPS 服务端地址。",
            "player.noMedia": "未选择音乐",
            "player.loading": "加载中",
            "player.shuffle": "随机播放",
            "player.repeatOne": "单曲循环",
            "player.previous": "上一首",
            "player.next": "下一首",
            "player.play": "播放",
            "player.pause": "暂停",
            "player.like": "喜欢",
            "player.dislike": "不喜欢",
            "player.back": "返回",
            "player.queue": "播放队列",
            "player.emptyQueue": "播放队列为空",
            "player.closePanel": "关闭面板",
            "player.position": "播放进度",
            "player.remaining": "剩余",
            "player.showControls": "显示播放控件",
        ],
    ]
}

struct LanguageOption: Identifiable {
    let id: String
    let en: String
    let zh: String
}
