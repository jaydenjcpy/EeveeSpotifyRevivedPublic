import Foundation
import ObjectiveC.runtime

enum TrueShuffleHookInstaller {
    private static var didInstall = false
    
    private typealias WeightForTrackIMP = @convention(c) (
        AnyObject,
        Selector,
        AnyObject,
        Bool,
        Bool
    ) -> Double

    static func installIfEnabled() {
        guard UserDefaults.trueShuffleEnabled else {
            writeDebugLog("True Shuffle is disabled in settings; skipping runtime hook install")
            return
        }
        install()
    }

    private static func install() {
        guard !didInstall else { return }
        
        let weightSelector = NSSelectorFromString("weightForTrack:recommendedTrack:mergedList:")
        let weightedListSelector = NSSelectorFromString("weightedShuffleListWithTracks:recommendations:")
        
        var classCount: UInt32 = 0
        guard let classes = objc_copyClassList(&classCount) else {
            writeDebugLog("True Shuffle: failed to enumerate Objective-C classes")
            return
        }
        defer { free(classes) }
        
        for index in 0 ..< Int(classCount) {
            let cls = classes[index]
            let className = NSStringFromClass(cls)
            
            // Look for classes containing "Shuffle" in their name
            guard className.lowercased().contains("shuff") else {
                continue
            }
            
            // Check if it has the weightForTrack method
            guard let weightMethod = class_getInstanceMethod(cls, weightSelector) else {
                continue
            }
            
            let originalWeightIMP = method_getImplementation(weightMethod)
            
            // Create a block that always returns original weight but with recommendedTrack set to false
            let weightBlock: @convention(block) (AnyObject, AnyObject, Bool, Bool) -> Double = {
                object,
                track,
                _,
                _
            in
                let original = unsafeBitCast(originalWeightIMP, to: WeightForTrackIMP.self)
                // Call original with recommendedTrack: false, mergedList: false
                return original(object, weightSelector, track, false, false)
            }
            
            method_setImplementation(weightMethod, imp_implementationWithBlock(weightBlock as Any))
            
            // Also nullify the weightedShuffleListWithTracks:recommendations: method if it exists
            if let weightedListMethod = class_getInstanceMethod(cls, weightedListSelector) {
                let weightedListBlock: @convention(block) (AnyObject, AnyObject, AnyObject) -> AnyObject? = {
                    _,
                    _,
                    _
                in
                    return nil
                }
                method_setImplementation(weightedListMethod, imp_implementationWithBlock(weightedListBlock as Any))
            }
            
            didInstall = true
            writeDebugLog("True Shuffle hooks installed on class: \(className)")
            // We found the main shuffle class, we can stop
            return
        }
        
        writeDebugLog("True Shuffle: no compatible shuffle class found; feature not applied")
    }
}
