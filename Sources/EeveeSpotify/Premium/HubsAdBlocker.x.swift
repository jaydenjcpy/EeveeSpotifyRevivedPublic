import Foundation
import Orion

// MARK: - HubsAdBlocker
//
// Hooks HUBViewModelBuilderImplementation.addJSONDictionary(_:) to strip ad
// components from the Hubs JSON before Spotify builds view models from it.
//
// Confirmed present in Spotify 9.1.32 binary:
//   - Class: HUBViewModelBuilderImplementation
//   - Selector: addJSONDictionary:
//
// This is the PRIMARY ad-stripping layer for JSON-based hub pages.
// DataLoaderServiceHooks.x.swift provides a belt-and-suspenders network layer.
//
// CONFIRMED AD COMPONENT IDs IN SPOTIFY 9.1.32 BINARY:
//   "mobile-display-ad-card"
//   "mobile-ads-embedded-npv-display-card"
//   "mobile-ads-mobile-overlay"
//   "embedded_npv_display_element"
//   "display_ad_element"
//   "display_ad_card"
//   "video_ad_card"
//   "video_ad_element"
//
// CONFIRMED AD PROTO TYPES (casita/browsita):
//   spotify.casita.v1.resolved.ImageBrandAd
//   spotify.casita.v1.resolved.VideoBrandAd
//   spotify.casita.v1.resolved.PromotionV1 / PromotionV3
//   spotify.ads.browseads.v2.BrowseAd / BrowseAdMetadata
//   spotify.ads.brandads.v1.EmbeddedAd / EmbeddedAdMetadata

class HUBViewModelBuilderImplementationHook: ClassHook<NSObject> {
    static let targetName = "HUBViewModelBuilderImplementation"

    func addJSONDictionary(_ dictionary: [String: Any]) {
        guard BasePremiumPatchingGroup.isActive else {
            orig.addJSONDictionary(dictionary)
            return
        }
        let cleaned = stripAdsFromHubJSON(dictionary)
        orig.addJSONDictionary(cleaned)
    }
}

// MARK: - Ad component detection
// All detection logic is shared with DataLoaderServiceHooks.x.swift via
// the stripAdsFromHubJSON(_:) overload that accepts [String: Any].

private let confirmedAdComponentIds: Set<String> = [
    // Confirmed directly in Spotify 9.1.32 binary strings
    "mobile-display-ad-card",
    "mobile-ads-embedded-npv-display-card",
    "mobile-ads-mobile-overlay",
    "embedded_npv_display_element",
    "display_ad_element",
    "display_ad_card",
    "video_ad_card",
    "video_ad_element",
    // Spotify URI-style component IDs
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
    "display_ad", "video_ad", "embedded_ad", "browse_ad", "brand_ad",
    "mobile-display-ad", "mobile-ads-",
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
    "imagebrandad", "videobrandad", "browseadmetadata",
    "embeddedadmetadata", "brandads",
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
    "mobile-display-ad", "mobile-ads-",
    "embedded-ad", "embedded_ad",
    "browse-ad", "browse_ad",
]

private func componentTypeIsAd(_ typeId: String) -> Bool {
    let lower = typeId.lowercased()
    if confirmedAdComponentIds.contains(lower) { return true }
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
    // CHECK 1: component["component"]["id"] — authoritative HubFramework component type
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

    // CHECK 3: top-level logging ID
    if let id = component["id"] as? String {
        let lower = id.lowercased()
        for kw in adLoggingIdKeywords {
            if lower.contains(kw) { return true }
        }
    }

    // CHECK 4: text title == "Advertisement" (visible in user screenshots)
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

    // CHECK 5: deep-scan metadata/logging/tracking blobs
    for key in ["metadata", "logging", "custom", "customData", "tracking",
                "analytics", "impression_data", "impressionData",
                "event_data", "eventData", "payload", "data",
                "custom_data", "customdata", "ad_data", "adData"] {
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

/// Strip ad components from a hub JSON dictionary (used by HUBViewModelBuilderImplementation hook).
private func stripAdsFromHubJSON(_ dict: [String: Any]) -> [String: Any] {
    var dict = dict
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
    for key in dict.keys {
        if topKeys.contains(key) || key == "header" { continue }
        dict[key] = deepFilterHubValue(dict[key]!)
    }
    return dict
}
