import Foundation

enum LyricsSource: Int, CaseIterable, CustomStringConvertible {
    case genius = 0
    case lrclib = 1
    case musixmatch = 2
    case petit = 3
    case notReplaced = 4
    case netease = 5
    
    // All sources enabled now that we have reliable metadata fetching
    public static var allCases: [LyricsSource] {
        return [.genius, .lrclib, .musixmatch, .petit, .netease]
    }

    // swift 5.8 compatible
    var description: String {
    switch self {
    case .genius:
        return "Genius"
    case .lrclib:
        return "LRCLIB"
    case .musixmatch:
        return "Musixmatch"
    case .petit:
        return "PetitLyrics"
    case .notReplaced:
        return "Spotify"
    case .netease:
        return "NetEase Cloud Music"
    }
    }

    
    var isReplacingLyrics: Bool { self != .notReplaced }
    
    static var defaultSource: LyricsSource {
        Locale.isInRegion("JP", orHasLanguage: "ja")
            ? .petit
            : .netease
    }
}
