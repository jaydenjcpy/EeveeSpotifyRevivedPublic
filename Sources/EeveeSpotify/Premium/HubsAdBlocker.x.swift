import Orion
import Foundation

// HUB JSON component structure (from open-source HubFramework):
// Each component dict has:
//   "component": {"namespace": "mobile", "name": "display-ad-card"}
//     — OR in some versions just a string "mobile:display-ad-card"
//   "id": "some-identifier"
//   "metadata": {...}
//   "logging": {...}
//   "body": [...] (child components)
//   "header": {...}
//   "overlays": [...]
//   "sections": [...]
//
// Known ad component identifiers found in Spotify 9.1.x binary:
//   mobile-display-ad-card          (namespace: mobile, name: display-ad-card)
//   mobile-ads-display-ad-element   (namespace: mobile-ads, name: display-ad-element)
//   mobile-ads-fullbleed-display-card
//   mobile-ads-embedded-npv-display-card
//   native-ad-home-shelf
//   com.spotify.service.marquee

struct AdBlockerGroup: HookGroup { }

class HubsAdBlocker: ClassHook<NSObject> {
    typealias Group = AdBlockerGroup
    static let targetName: String = "HUBViewModelBuilderImplementation"

    // Ad-related keywords matched against component namespace, name, id, type, and metadata keys
    private static let adKeywords: [String] = [
        "ad", "ads", "sponsored", "upsell", "campaign", "promoted",
        "premium-upsell", "merch", "ticket", "billboard", "banner",
        "interstitial", "overlay", "marquee", "leavebehind",
        "leave-behind", "displayad", "display-ad", "fullbleed", "full-bleed",
        "leaderboard", "advertisement", "sponsor", "promo", "native-ad",
        "mobile-ads", "on-surface", "onsurface", "search-ad", "home-ad",
        "sponsored-content", "sponsored-ad", "display-ad", "ad-card",
        "native-ad-home-shelf", "sponsored-shelf", "sponsored-row",
        "ad-shelf", "ad-row", "sponsored-item", "ad-item",
        "merchandising", "upgrade-component", "offer", "marketing",
        "sponsored-shelf", "sponsored-row", "native-ad-home-shelf",
        "mobile-display-ad-card", "mobile-ads-display-ad-element"
    ]

    // Returns true if the given string contains any ad keyword
    private static func containsAdKeyword(_ str: String) -> Bool {
        let lower = str.lowercased()
        for kw in adKeywords {
            if lower.contains(kw) { return true }
        }
        return false
    }

    // Returns true if the component dictionary represents an ad
    private func isAdComponent(_ component: [String: Any]) -> Bool {
        // 1. Check "component" field
        //    In HUB JSON this is a dict: {"namespace": "mobile", "name": "display-ad-card"}
        if let componentDict = component["component"] as? [String: Any] {
            let ns = componentDict["namespace"] as? String ?? ""
            let name = componentDict["name"] as? String ?? ""
            if HubsAdBlocker.containsAdKeyword(ns) { return true }
            if HubsAdBlocker.containsAdKeyword(name) { return true }
            if HubsAdBlocker.containsAdKeyword("\(ns):\(name)") { return true }
        }
        // Also handle plain string format (e.g. "mobile:display-ad-card")
        if let componentStr = component["component"] as? String {
            if HubsAdBlocker.containsAdKeyword(componentStr) { return true }
        }

        // 2. Check "id" field
        if let id = component["id"] as? String {
            if HubsAdBlocker.containsAdKeyword(id) { return true }
        }

        // 3. Check "type" field
        if let type_ = component["type"] as? String {
            if HubsAdBlocker.containsAdKeyword(type_) { return true }
        }

        // 4. Check "metadata" dict — look for ad flags and ad-related keys
        if let metadata = component["metadata"] as? [String: Any] {
            if metadata["ad"] as? Bool == true { return true }
            if metadata["is_ad"] as? Bool == true { return true }
            if metadata["is_sponsored"] as? Bool == true { return true }
            for key in metadata.keys {
                if HubsAdBlocker.containsAdKeyword(key) { return true }
            }
        }

        // 5. Check "logging" dict keys and type
        if let logging = component["logging"] as? [String: Any] {
            if let logType = logging["type"] as? String {
                if HubsAdBlocker.containsAdKeyword(logType) { return true }
            }
            for key in logging.keys {
                if HubsAdBlocker.containsAdKeyword(key) { return true }
            }
        }

        // 6. Check "custom" dict keys
        if let custom = component["custom"] as? [String: Any] {
            for key in custom.keys {
                if HubsAdBlocker.containsAdKeyword(key) { return true }
            }
        }

        // 7. Check "text" and "title" fields for "Advertisement" label
        if let text = component["text"] as? [String: Any] {
            for value in text.values {
                if let str = value as? String, HubsAdBlocker.containsAdKeyword(str) { return true }
                if let dict = value as? [String: Any] {
                    for v in dict.values {
                        if let s = v as? String, HubsAdBlocker.containsAdKeyword(s) { return true }
                    }
                }
            }
        }
        
        if let title = component["title"] as? String {
            if HubsAdBlocker.containsAdKeyword(title) { return true }
        }

        // 8. Check "subtitle" and "header" fields
        if let subtitle = component["subtitle"] as? String {
            if HubsAdBlocker.containsAdKeyword(subtitle) { return true }
        }

        if let header = component["header"] as? String {
            if HubsAdBlocker.containsAdKeyword(header) { return true }
        }

        return false
    }

    // Recursively filter ad components from an array
    private func filterComponents(_ components: [[String: Any]]) -> [[String: Any]] {
        var result = [[String: Any]]()
        for var component in components {
            if isAdComponent(component) {
                continue
            }
            // Recursively filter nested arrays
            if let children = component["children"] as? [[String: Any]] {
                component["children"] = filterComponents(children)
            }
            if let rows = component["rows"] as? [[String: Any]] {
                component["rows"] = filterComponents(rows)
            }
            if let body = component["body"] as? [[String: Any]] {
                component["body"] = filterComponents(body)
            }
            result.append(component)
        }
        return result
    }

    func addJSONDictionary(_ dictionary: NSDictionary?) {
        guard var mutableDict = dictionary as? [String: Any] else {
            orig.addJSONDictionary(dictionary)
            return
        }

        // Filter top-level "body" array
        if let body = mutableDict["body"] as? [[String: Any]] {
            mutableDict["body"] = filterComponents(body)
        }

        // Filter "header" component
        if var header = mutableDict["header"] as? [String: Any] {
            if isAdComponent(header) {
                mutableDict.removeValue(forKey: "header")
            } else {
                if let children = header["children"] as? [[String: Any]] {
                    header["children"] = filterComponents(children)
                }
                mutableDict["header"] = header
            }
        }

        // Filter "overlays" array
        if let overlays = mutableDict["overlays"] as? [[String: Any]] {
            mutableDict["overlays"] = filterComponents(overlays)
        }

        // Filter "sections" array (used in some page types)
        if let sections = mutableDict["sections"] as? [[String: Any]] {
            mutableDict["sections"] = filterComponents(sections)
        }

        orig.addJSONDictionary(mutableDict as NSDictionary)
    }
}
