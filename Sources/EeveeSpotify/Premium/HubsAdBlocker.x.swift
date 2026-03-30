import Orion
import Foundation

// MARK: - HubsAdBlocker
//
// This hook targets HUBViewModelBuilderImplementation, which handles the parsed
// hub view model before it is rendered. It acts as a second line of defense
// after the network-level stripping in DataLoaderServiceHooks.x.swift.
//
// NOTE: If HUBViewModelBuilderImplementation does not exist in the running
// Spotify version, Orion silently skips this hook — which is fine, because
// the network-level stripping in DataLoaderServiceHooks.x.swift handles it.
//
// The definitive fix for visual ads (Cartier, Credit Karma, etc.) is in
// DataLoaderServiceHooks.x.swift via stripAdsFromHubJSON() + isHubResponseURL().
// This file is kept as a belt-and-suspenders second layer.

class HubsAdBlocker: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName: String = "HUBViewModelBuilderImplementation"

    func addJSONDictionary(_ dictionary: NSDictionary?) {
        guard var dict = dictionary as? [String: Any] else {
            orig.addJSONDictionary(dictionary)
            return
        }

        // Apply LikedSongs mutation first
        dict = mutateHubsJSON(dict)

        // Strip ads using the shared stripAdsFromHubJSON logic.
        // We re-serialize and re-parse to reuse the exact same filtering
        // code path used at the network level.
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let cleaned = stripAdsFromHubJSON(data),
           let cleanedDict = (try? JSONSerialization.jsonObject(with: cleaned, options: [])) as? [String: Any] {
            orig.addJSONDictionary(cleanedDict as NSDictionary)
        } else {
            orig.addJSONDictionary(dict as NSDictionary)
        }
    }
}
