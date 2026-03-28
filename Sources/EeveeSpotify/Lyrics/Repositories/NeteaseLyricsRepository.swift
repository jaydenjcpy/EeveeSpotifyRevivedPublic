import Foundation

class NeteaseLyricsRepository: LyricsRepository {
    private let jsonDecoder: JSONDecoder
    private let session: URLSession
    private let searchApiUrl = "http://music.163.com/api/search/get"
    private let lyricApiUrl = "http://music.163.com/api/song/lyric"

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EeveeSpotify v\(EeveeSpotify.version) https://github.com/whoeevee/EeveeSpotify"
        ]
        session = URLSession(configuration: configuration)
        jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    private func perform(
        _ urlString: String,
        query: [String: Any] = [:],
        method: String = "GET"
    ) throws -> Data {
        var components = URLComponents(string: urlString)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = components.url else {
            throw LyricsError.decodingError
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        let semaphore = DispatchSemaphore(value: 0)
        var data: Data?
        var error: Error?

        let task = session.dataTask(with: request) { responseData, _, err in
            error = err
            data = responseData
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        if let error = error {
            throw error
        }

        guard let responseData = data else {
            throw LyricsError.decodingError
        }
        return responseData
    }

    private func searchSong(title: String, artist: String) throws -> NeteaseSong? {
        let query: [String: Any] = [
            "s": "\(title) \(artist)",
            "type": 1, // 1 for single song
            "limit": 1
        ]
        let data = try perform(searchApiUrl, query: query)
        
        struct SearchResponse: Decodable {
            struct Result: Decodable {
                let songs: [NeteaseSong]?
            }
            let result: Result?
        }

        let searchResponse = try jsonDecoder.decode(SearchResponse.self, from: data)
        return searchResponse.result?.songs?.first
    }

    private func getLyrics(songId: Int) throws -> NeteaseLyrics {
        let query: [String: Any] = [
            "id": songId
        ]
        let data = try perform(lyricApiUrl, query: query)
        
        struct LyricResponse: Decodable {
            let lrc: NeteaseLyrics?
            let tlyric: NeteaseLyrics?
            let nolyric: Bool?
            let uncollected: Bool?
        }

        let lyricResponse = try jsonDecoder.decode(LyricResponse.self, from: data)
        
        if lyricResponse.nolyric == true || lyricResponse.uncollected == true {
            throw LyricsError.noSuchSong
        }
        
        guard let lrc = lyricResponse.lrc else {
            throw LyricsError.decodingError
        }
        return lrc
    }

    private func mapSyncedLyricsLines(_ lrcContent: String) -> [LyricsLineDto] {
        var lines: [LyricsLineDto] = []
        let regex = try! NSRegularExpression(pattern: "\\[(?<minute>\\d{2}):(?<second>\\d{2})\\.(?<millisecond>\\d{2,3})\\](?<content>.*)", options: [])
        
        lrcContent.enumerateLines { line, stop in
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                var captures: [String: String] = [:]
                for name in ["minute", "second", "millisecond", "content"] {
                    let matchRange = match.range(withName: name)
                    if let substringRange = Range(matchRange, in: line) {
                        captures[name] = String(line[substringRange])
                    }
                }
                
                if let minuteStr = captures["minute"], let secondStr = captures["second"], let millisecondStr = captures["millisecond"], let content = captures["content"] {
                    if let minute = Int(minuteStr), let second = Int(secondStr), var millisecond = Int(millisecondStr) {
                        // Netease sometimes uses 2-digit milliseconds, convert to 3-digit
                        if millisecondStr.count == 2 { millisecond *= 10 }
                        let offsetMs = minute * 60 * 1000 + second * 1000 + millisecond
                        lines.append(LyricsLineDto(content: content.trimmingCharacters(in: .whitespaces), offsetMs: offsetMs))
                    }
                }
            }
        }
        return lines
    }

    func getLyrics(_ query: LyricsSearchQuery, options: LyricsOptions) throws -> LyricsDto {
        guard let song = try searchSong(title: query.title, artist: query.primaryArtist) else {
            throw LyricsError.noSuchSong
        }

        let neteaseLyrics = try getLyrics(songId: song.id)
        
        guard let lrcContent = neteaseLyrics.lyric else {
            throw LyricsError.noSuchSong
        }

        let lines = mapSyncedLyricsLines(lrcContent)
        
        return LyricsDto(
            lines: lines,
            timeSynced: !lines.isEmpty,
            romanization: .original // Netease provides romanization in separate tlyric, not handled yet
        )
    }
}
