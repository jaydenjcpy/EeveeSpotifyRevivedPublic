import Foundation
import Orion

// Global variable for access token
public var spotifyAccessToken: String?

// Helper function to start capturing from other files
func DataLoaderServiceHooks_startCapturing() {
}

// MARK: - Hub JSON Ad Stripping
//
// This is a network-level defense layer for visual ads on Search and Home screens.
// The PRIMARY fix is in AdViewBlocker.x.swift (view-layer hooks).
// This file provides belt-and-suspenders protection at the network level.
//
// SPOTIFY v9.1.32 AD DELIVERY ARCHITECTURE (confirmed by binary analysis):
//
//   Home screen ads:   Delivered via Casita API (spotify.casita.v1.resolved.*)
//                      as protobuf over spclient.wg.spotify.com
//   Search/Browse ads: Delivered via Browsita API (spotify.browsita.v1.resolved.*)
//                      as protobuf over spclient.wg.spotify.com
//   Overlay ads:       Delivered via AdsStandalone_MobileOverlayImpl
//   Marquee ads:       Delivered via Marquee_MarqueeImpl
//
//   The responses are PROTOBUF, not plain JSON. The /hm/ path assumption
//   in previous versions was wrong — Spotify 9.1.x uses /casita/ and /browsita/.
//
//   However, the HUBViewModelBuilderImplementation hook (HubsAdBlocker.x.swift)
//   still receives JSON dictionaries for older hub-based pages. Both layers
//   are kept active.
//
// AD NETWORK BLOCKING:
//   Ad delivery endpoints are blocked at the HTTP response level in
//   URLSession:dataTask:didReceiveResponse:completionHandler: by calling
//   handler(.cancel) before any data arrives.

// MARK: - Ad component detection (shared with HubsAdBlocker)

private let adComponentTypeIds: Set<String> = [
    "spotify:ad", "spotify:ad-banner", "spotify:ad-card", "spotify:ad-row",
    "spotify:ad-carousel", "spotify:ad-header", "spotify:ad-overlay",
    "spotify:ad-interstitial", "spotify:ad-takeover", "spotify:ad-billboard",
    "spotify:ad-leaderboard", "spotify:ad-mrec", "spotify:ad-halfpage",
    "spotify:ad-skin", "spotify:ad-roadblock", "spotify:ad-wallpaper",
    "spotify:ad-expandable", "spotify:ad-video", "spotify:ad-audio",
    "spotify:ad-native", "spotify:ad-display", "spotify:ad-search",
    "spotify:ad-home", "spotify:ad-nowplaying",
    "spotify:sponsored", "spotify:sponsored-card", "spotify:sponsored-row",
    "spotify:sponsored-banner", "spotify:sponsored-content",
    "spotify:promoted", "spotify:promoted-card", "spotify:promoted-row",
    "spotify:upsell", "spotify:upsell-banner", "spotify:upsell-card",
    "spotify:upsell-row", "spotify:premium-upsell",
    "spotify:premium-upsell-banner", "spotify:premium-upsell-card",
    "spotify:marquee", "spotify:billboard", "spotify:hpto",
    "spotify:dfp", "spotify:gam", "spotify:takeover",
    "spotify:interstitial", "spotify:overlay", "spotify:banner",
    "spotify:rewarded", "spotify:offerwall", "spotify:brand-ad",
    "spotify:brand_ad", "spotify:merch", "spotify:ticket-upsell",
    "spotify:incentivized", "spotify:survey",
]

private let adTypeSubstrings: [String] = [
    ":ad", ":ad-", ":ad_", "ad:", "ads:",
    ":advertisement", ":advertis",
    ":sponsored", ":sponsor",
    ":promoted", ":promotion",
    ":upsell", ":premium-upsell",
    ":billboard", ":takeover",
    ":interstitial", ":overlay",
    ":marquee", ":hpto", ":dfp", ":gam",
    ":rewarded", ":offerwall",
    ":native-ad", ":display-ad",
    ":video-ad", ":audio-ad",
    ":search-ad", ":home-ad",
    ":brand-ad", ":brand_ad",
]

private let adMetaKeywords: [String] = [
    "advertisement", "advertis",
    "sponsored", "sponsor",
    "promoted",
    "upsell",
    "billboard", "takeover",
    "marquee", "hpto", "dfp", "gam",
    "credit-karma", "creditkarma", "credit_karma",
    "cartier",
    "ad_type", "ad_id", "ad_unit", "adtype", "adunit",
    "is_ad", "isad", "is_sponsored",
    "campaign_id", "campaign_type",
    "impression_url", "click_url",
    "ad_slot", "ad_slots",
    "native_ad", "nativead", "display_ad",
    "rewarded", "offerwall",
    "brand_ad", "brand-ad",
]

private let adLoggingIdKeywords: [String] = [
    "advertisement", "advertis",
    "sponsored", "sponsor",
    "promoted",
    "upsell",
    "billboard", "takeover",
    "interstitial",
    "marquee", "hpto", "dfp", "gam",
    "merch-",
    "rewarded", "offerwall",
    "native-ad", "display-ad",
    "video-ad", "audio-ad",
    "search-ad", "home-ad",
    "brand-ad", "brand_ad",
    "credit-karma", "creditkarma",
    "cartier",
]

private func componentTypeIsAd(_ typeId: String) -> Bool {
    let lower = typeId.lowercased()
    if adComponentTypeIds.contains(lower) { return true }
    for kw in adTypeSubstrings {
        if lower.contains(kw) { return true }
    }
    return false
}

private func metaValueContainsAdSignal(_ value: Any) -> Bool {
    if let s = value as? String {
        let lower = s.lowercased()
        for kw in adMetaKeywords {
            if lower.contains(kw) { return true }
        }
        return false
    }
    if let dict = value as? [String: Any] {
        for (k, v) in dict {
            let lk = k.lowercased()
            for kw in adMetaKeywords {
                if lk.contains(kw) { return true }
            }
            if metaValueContainsAdSignal(v) { return true }
        }
    }
    if let arr = value as? [Any] {
        for v in arr {
            if metaValueContainsAdSignal(v) { return true }
        }
    }
    return false
}

private func shouldStripHubComponent(_ component: [String: Any]) -> Bool {
    // CHECK 1: component["component"]["id"] — the authoritative HubFramework type
    if let compDict = component["component"] as? [String: Any],
       let compTypeId = compDict["id"] as? String,
       componentTypeIsAd(compTypeId) {
        return true
    }

    // CHECK 2: component["component"]["category"]
    if let compDict = component["component"] as? [String: Any],
       let category = compDict["category"] as? String {
        let lowerCat = category.lowercased()
        let adCategories: Set<String> = [
            "ad", "ads", "advertisement", "sponsored", "promoted",
            "upsell", "premium-upsell", "billboard", "takeover",
            "interstitial", "overlay", "marquee", "hpto", "dfp", "gam",
            "rewarded", "offerwall",
        ]
        if adCategories.contains(lowerCat) { return true }
    }

    // CHECK 3: component["id"] (logging/tracking ID)
    if let id = component["id"] as? String {
        let lower = id.lowercased()
        for kw in adLoggingIdKeywords {
            if lower.contains(kw) { return true }
        }
    }

    // CHECK 4: text title == "Advertisement"
    if let text = component["text"] as? [String: Any] {
        for (_, v) in text {
            if let s = v as? String {
                let lower = s.lowercased()
                if lower == "advertisement" || lower == "ad" || lower == "sponsored" {
                    return true
                }
            }
        }
    }

    // CHECK 5: deep-scan metadata/logging/custom blobs
    for key in ["metadata", "logging", "custom", "customData", "tracking",
                "analytics", "impression_data", "impressionData",
                "event_data", "eventData", "payload", "data",
                "custom_data", "customdata"] {
        if let v = component[key], metaValueContainsAdSignal(v) {
            return true
        }
    }

    // CHECK 6: URI field
    if let uri = component["uri"] as? String {
        let lower = uri.lowercased()
        if lower.contains("spotify:ad:") || lower.contains(":ad:") {
            return true
        }
    }

    return false
}

private let hubContainerKeys = [
    "children", "items", "content", "sections", "rows",
    "components", "slots", "tiles", "cards", "entries",
    "shelf", "shelves", "modules", "blocks", "cells",
]

private func filterHubComponents(_ components: [[String: Any]]) -> [[String: Any]] {
    var result = [[String: Any]]()
    for var component in components {
        if shouldStripHubComponent(component) { continue }
        for key in hubContainerKeys {
            if let nested = component[key] as? [[String: Any]] {
                component[key] = filterHubComponents(nested)
            } else if let nested = component[key] as? [Any] {
                component[key] = nested.compactMap { item -> Any? in
                    if let d = item as? [String: Any], shouldStripHubComponent(d) { return nil }
                    return deepFilterHubValue(item)
                }
            }
        }
        result.append(component)
    }
    return result
}

private func deepFilterHubValue(_ value: Any) -> Any {
    if var dict = value as? [String: Any] {
        if shouldStripHubComponent(dict) { return [String: Any]() }
        for key in dict.keys {
            if let nested = dict[key] as? [[String: Any]] {
                dict[key] = filterHubComponents(nested)
            } else if let nested = dict[key] as? [Any] {
                dict[key] = nested.compactMap { item -> Any? in
                    if let d = item as? [String: Any], shouldStripHubComponent(d) { return nil }
                    return deepFilterHubValue(item)
                }
            }
        }
        return dict
    }
    if let arr = value as? [[String: Any]] {
        return filterHubComponents(arr)
    }
    if let arr = value as? [Any] {
        return arr.compactMap { item -> Any? in
            if let d = item as? [String: Any], shouldStripHubComponent(d) { return nil }
            return deepFilterHubValue(item)
        }
    }
    return value
}

/// Strip all ad components from a raw Hubs JSON response Data.
/// Returns the cleaned Data, or nil if the data is not valid JSON or not a hub response.
func stripAdsFromHubJSON(_ data: Data) -> Data? {
    guard
        var dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    else { return nil }

    let topKeys = [
        "body", "sections", "items", "slots", "overlays",
        "rows", "cards", "modules", "blocks", "shelves",
        "components", "tiles", "entries", "cells",
    ]

    for key in topKeys {
        if let arr = dict[key] as? [[String: Any]] {
            dict[key] = filterHubComponents(arr)
        }
    }

    // Filter header
    if var header = dict["header"] as? [String: Any] {
        if shouldStripHubComponent(header) {
            dict.removeValue(forKey: "header")
        } else {
            for key in hubContainerKeys {
                if let nested = header[key] as? [[String: Any]] {
                    header[key] = filterHubComponents(nested)
                }
            }
            dict["header"] = header
        }
    }

    // Deep-filter all remaining keys
    for key in dict.keys {
        if topKeys.contains(key) || key == "header" { continue }
        dict[key] = deepFilterHubValue(dict[key]!)
    }

    guard let cleaned = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
        return nil
    }
    return cleaned
}

// MARK: - Hub URL detection
// Spotify 9.1.32 delivers hub pages via spclient.wg.spotify.com.
// The response format is protobuf (Casita/Browsita APIs), but the
// HUBViewModelBuilderImplementation hook receives JSON dicts for legacy hub pages.
// We keep the network-level filter for any JSON hub responses that slip through.
private func isHubResponseURL(_ url: URL) -> Bool {
    let path = url.path.lowercased()
    let host = (url.host ?? "").lowercased()

    // Must be a Spotify API host
    guard host.contains("spotify.com") || host.contains("spclient") else { return false }

    // Spotify 9.1.32 hub page paths (confirmed by binary analysis)
    // Legacy /hm/ paths (older Spotify versions)
    // Casita/Browsita paths are protobuf and handled by AdViewBlocker.x.swift
    let hubPathPrefixes: [String] = [
        "/hm/",           // Legacy hub pages (JSON)
        "/casita/",       // Home screen (protobuf - filtered at view layer)
        "/browsita/",     // Browse/Search (protobuf - filtered at view layer)
        "/user-customization-service/",
    ]

    for prefix in hubPathPrefixes {
        if path.hasPrefix(prefix) || path.contains(prefix) { return true }
    }

    return false
}

// MARK: - Ad URL detection
// These are the network-level ad delivery endpoints to block entirely.
private func isAdDeliveryURL(_ url: URL) -> Bool {
    let path = url.path.lowercased()
    let host = (url.host ?? "").lowercased()

    // Block known third-party ad network hosts entirely
    let adHosts: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "adservice.google.com", "moatads.com", "scorecardresearch.com",
        "omtrdc.net", "demdex.net", "ads.spotify.com", "adserver.spotify.com",
        "pubads.g.doubleclick.net", "securepubads.g.doubleclick.net",
        "pagead2.googlesyndication.com", "tpc.googlesyndication.com",
        "cm.g.doubleclick.net", "stats.g.doubleclick.net",
        "ad.doubleclick.net", "googleads.g.doubleclick.net",
    ]
    for adHost in adHosts {
        if host == adHost || host.hasSuffix("." + adHost) { return true }
    }

    // Block Spotify's ad delivery path fragments
    let adPathFragments: [String] = [
        "/ads/", "/ad/", "/ad-logic/", "/adlogic/", "/ad_logic/",
        "/dfp/", "/hpto/", "/marquee/", "/gam/", "/gam-ad/",
        "/ad-slot/", "/ad-slots/", "/ad-inventory/", "/ad-targeting/",
        "/ad-decision/", "/ad-request/", "/ad-event/", "/ad-impression/",
        "/ad-click/", "/ad-tracking/", "/ad-measurement/",
        "/sponsored/", "/promoted/", "/billboard/", "/takeover/",
        "/interstitial/", "/native-ad/", "/display-ad/",
        "/video-ad/", "/audio-ad/", "/rewarded/", "/offerwall/",
    ]
    for fragment in adPathFragments {
        if path.contains(fragment) { return true }
    }

    return false
}

class SPTDataLoaderServiceHook: ClassHook<NSObject>, SpotifySessionDelegate {
    static let targetName = "SPTDataLoaderService"

    // orion:new
    static var cachedCustomizeData: Data?

    // orion:new
    static var handledCustomizeTasks = Set<Int>()

    // orion:new
    func shouldBlock(_ url: URL) -> Bool {
        let elapsed = Date().timeIntervalSince(tweakInitTime)
        
        // Always block: session destroy, token delete, and ALL ad-related requests
        if url.isDeleteToken
            || url.isSessionInvalidation
            || url.path.contains("session/purge")
            || url.path.contains("token/revoke")
            || url.isAdRelated
            || isAdDeliveryURL(url) {
            return true
        }

        // Only block these after startup (30s) to allow initial login/initialization
        if elapsed > 30 {
            return url.isAccountValidate || url.isOndemandSelector
                || url.isTrialsFacade || url.isPremiumMarketing || url.isPendragonFetchMessageList
                || url.isPushkaTokens || url.path.contains("signup/public") || url.path.contains("apresolve")
                || url.path.contains("pses/screenconfig") || url.path.contains("bootstrap/v1/bootstrap")
        }
        
        return false
    }

    // orion:new
    func shouldModify(_ url: URL) -> Bool {
        let shouldPatchPremium = BasePremiumPatchingGroup.isActive
        let shouldReplaceLyrics = BaseLyricsGroup.isActive
        
        let isLyricsURL = url.isLyrics
        
        return (shouldReplaceLyrics && isLyricsURL)
            || (shouldPatchPremium && (url.isCustomize || url.isPremiumPlanRow || url.isPremiumBadge || url.isPlanOverview))
    }
    
    // orion:new
    func respondWithCustomData(_ data: Data, task: URLSessionDataTask, session: URLSession) {
        orig.URLSession(session, dataTask: task, didReceiveData: data)
    }

    // orion:new
    func handleBlockedEndpoint(_ url: URL, task: URLSessionDataTask, session: URLSession) {
        if url.isDeleteToken {
            respondWithCustomData(Data(), task: task, session: session)
        } else if url.isAccountValidate {
            let response = "{\"status\":1,\"country\":\"US\",\"is_country_launched\":true}".data(using: .utf8)!
            respondWithCustomData(response, task: task, session: session)
        } else if url.isOndemandSelector {
            respondWithCustomData(Data(), task: task, session: session)
        } else if url.isTrialsFacade {
            let response = "{\"result\":\"NOT_ELIGIBLE\"}".data(using: .utf8)!
            respondWithCustomData(response, task: task, session: session)
        } else if url.isPremiumMarketing {
            respondWithCustomData("{}".data(using: .utf8)!, task: task, session: session)
        } else if url.isPendragonFetchMessageList {
            respondWithCustomData(Data(), task: task, session: session)
        } else if url.isPushkaTokens {
            respondWithCustomData(Data(), task: task, session: session)
        } else if url.isSessionInvalidation || url.path.contains("session/purge") || url.path.contains("token/revoke") {
            respondWithCustomData("{\"status\":\"OK\"}".data(using: .utf8)!, task: task, session: session)
        } else if url.path.contains("signup/public") {
            respondWithCustomData("{\"status\":\"OK\"}".data(using: .utf8)!, task: task, session: session)
        } else if url.path.contains("apresolve") {
            respondWithCustomData("{\"status\":\"OK\"}".data(using: .utf8)!, task: task, session: session)
        } else if url.path.contains("pses/screenconfig") {
            respondWithCustomData("{}".data(using: .utf8)!, task: task, session: session)
        } else if url.path.contains("bootstrap/v1/bootstrap") {
            respondWithCustomData("{}".data(using: .utf8)!, task: task, session: session)
        } else {
            // All ad-related and unknown blocked URLs → empty response
            respondWithCustomData(Data(), task: task, session: session)
        }
        orig.URLSession(session, task: task, didCompleteWithError: nil)
    }
    
    func URLSession(
        _ session: URLSession,
        task: URLSessionDataTask,
        didCompleteWithError error: Error?
    ) {
        // Capture authorization token from any request
        if let request = task.currentRequest,
           let headers = request.allHTTPHeaderFields,
           let auth = headers["Authorization"] ?? headers["authorization"],
           auth.hasPrefix("Bearer ") {
            spotifyAccessToken = String(auth.dropFirst(7))
        }
	
        guard let url = task.currentRequest?.url else {
            orig.URLSession(session, task: task, didCompleteWithError: error)
            return
        }

        // Handle blocked endpoints (session protection + ad blocking)
        if shouldBlock(url) {
            handleBlockedEndpoint(url, task: task, session: session)
            return
        }

        // Handle customize 304 that was already served in didReceiveResponse
        if SPTDataLoaderServiceHook.handledCustomizeTasks.remove(task.taskIdentifier) != nil {
            orig.URLSession(session, task: task, didCompleteWithError: nil)
            return
        }

        // ── HUB JSON AD STRIPPING (legacy JSON hub pages) ────────────────────────
        // For Spotify 9.1.32, Casita/Browsita responses are protobuf and handled
        // by AdViewBlocker.x.swift at the view layer. This handles any remaining
        // JSON-based hub responses.
        if error == nil,
           BasePremiumPatchingGroup.isActive,
           isHubResponseURL(url),
           let buffer = URLSessionHelper.shared.obtainData(for: url),
           let cleaned = stripAdsFromHubJSON(buffer) {
            respondWithCustomData(cleaned, task: task, session: session)
            orig.URLSession(session, task: task, didCompleteWithError: nil)
            return
        }
        // ─────────────────────────────────────────────────────────────────────────

        guard error == nil, shouldModify(url) else {
            orig.URLSession(session, task: task, didCompleteWithError: error)
            return
        }
        
        guard let buffer = URLSessionHelper.shared.obtainData(for: url) else {
            // Customize 304 fallback: serve cached modified data when no buffer available
            if url.isCustomize, let cached = SPTDataLoaderServiceHook.cachedCustomizeData {
                respondWithCustomData(cached, task: task, session: session)
                orig.URLSession(session, task: task, didCompleteWithError: nil)
            } else {
                orig.URLSession(session, task: task, didCompleteWithError: error)
            }
            return
        }
        
        do {
            if url.isLyrics {
                let originalLyrics = try? Lyrics(serializedBytes: buffer)
                
                let semaphore = DispatchSemaphore(value: 0)
                var customLyricsData: Data?
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        customLyricsData = try getLyricsDataForCurrentTrack(
                            url.path,
                            originalLyrics: originalLyrics
                        )
                    } catch {
                    }
                    semaphore.signal()
                }
                
                let timeout = DispatchTime.now() + .milliseconds(5000)
                let result = semaphore.wait(timeout: timeout)
                
                if result == .success, let data = customLyricsData {
                    respondWithCustomData(data, task: task, session: session)
                    orig.URLSession(session, task: task, didCompleteWithError: nil)
                } else {
                    respondWithCustomData(buffer, task: task, session: session)
                    orig.URLSession(session, task: task, didCompleteWithError: nil)
                }
                return
            }
            
            if url.isPremiumPlanRow {
                respondWithCustomData(
                    try getPremiumPlanRowData(
                        originalPremiumPlanRow: try PremiumPlanRow(serializedBytes: buffer)
                    ),
                    task: task,
                    session: session
                )
                orig.URLSession(session, task: task, didCompleteWithError: nil)
                return
            }
            
            if url.isPremiumBadge {
                respondWithCustomData(try getPremiumPlanBadge(), task: task, session: session)
                orig.URLSession(session, task: task, didCompleteWithError: nil)
                return
            }
            
            if url.isCustomize {
                var customizeMessage = try CustomizeMessage(serializedBytes: buffer)
                modifyRemoteConfiguration(&customizeMessage.response)
                let modifiedData = try customizeMessage.serializedData()
                SPTDataLoaderServiceHook.cachedCustomizeData = modifiedData
                respondWithCustomData(modifiedData, task: task, session: session)
                orig.URLSession(session, task: task, didCompleteWithError: nil)
                return
            }
            
            if url.isPlanOverview {
                respondWithCustomData(try getPlanOverviewData(), task: task, session: session)
                orig.URLSession(session, task: task, didCompleteWithError: nil)
                return
            }
        }
        catch {
            orig.URLSession(session, task: task, didCompleteWithError: error)
        }
    }

    func URLSession(
        _ session: URLSession,
        dataTask task: URLSessionDataTask,
        didReceiveResponse response: HTTPURLResponse,
        completionHandler handler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        // Block ad responses at the HTTP response level — cancel before data arrives
        if let url = task.currentRequest?.url, shouldBlock(url) {
            handler(.cancel)
            return
        }

        // Handle customize 304 — prevent free-account data leaking from URLSession cache
        if let url = task.currentRequest?.url, url.isCustomize, response.statusCode == 304 {
            if let cached = SPTDataLoaderServiceHook.cachedCustomizeData {
                let fakeResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: [:])!
                orig.URLSession(session, dataTask: task, didReceiveResponse: fakeResponse, completionHandler: handler)
                respondWithCustomData(cached, task: task, session: session)
                SPTDataLoaderServiceHook.handledCustomizeTasks.insert(task.taskIdentifier)
                return
            }
        }

        guard
            let url = task.currentRequest?.url,
            url.isLyrics,
            response.statusCode != 200
        else {
            orig.URLSession(session, dataTask: task, didReceiveResponse: response, completionHandler: handler)
            return
        }

        do {
            let data = try getLyricsDataForCurrentTrack(url.path)
            let okResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: [:])!
            
            orig.URLSession(session, dataTask: task, didReceiveResponse: okResponse, completionHandler: handler)
            respondWithCustomData(data, task: task, session: session)
        } catch {
            orig.URLSession(session, task: task, didCompleteWithError: error)
        }
    }

    func URLSession(
        _ session: URLSession,
        dataTask task: URLSessionDataTask,
        didReceiveData data: Data
    ) {
        guard let url = task.currentRequest?.url else {
            return
        }

        // Suppress data for blocked endpoints (prevent original data from reaching handler)
        if shouldBlock(url) {
            return
        }

        // Buffer hub responses so we can strip ads in didCompleteWithError
        if BasePremiumPatchingGroup.isActive && isHubResponseURL(url) {
            URLSessionHelper.shared.setOrAppend(data, for: url)
            return
        }

        if shouldModify(url) {
            URLSessionHelper.shared.setOrAppend(data, for: url)
            return
        }

        orig.URLSession(session, dataTask: task, didReceiveData: data)
    }
}
