import Foundation
import Orion

// This is a much safer, passive hook that only triggers when the app 
// actually tries to calculate the next track in a shuffle.
// It avoids the "instant crash" by not interfering with the app's startup memory.

class SPTShuffleServiceHook: ClassHook<NSObject> {
    static let targetName = "SPTShuffleService"

    // orion:new
    func isTrueShuffleEnabled() -> Bool {
        return UserDefaults.trueShuffleEnabled
    }

    // This hook targets the core shuffle weighting logic
    // By returning 1.0 for all tracks, we force a truly random shuffle
    func weightForTrack(_ track: NSObject) -> Float {
        if isTrueShuffleEnabled() {
            return 1.0
        }
        return orig.weightForTrack(track)
    }
}

// We also hook the recommendation service to prevent it from 
// injecting "weighted" tracks into the shuffle queue.
class SPTShuffleRecommendationServiceHook: ClassHook<NSObject> {
    static let targetName = "SPTShuffleRecommendationService"

    func recommendationsForContext(_ context: NSObject) -> NSObject? {
        if UserDefaults.trueShuffleEnabled {
            // Returning nil forces the app to use its local, non-weighted shuffle
            return nil
        }
        return orig.recommendationsForContext(context)
    }
}
