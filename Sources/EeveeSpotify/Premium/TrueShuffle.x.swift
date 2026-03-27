import Foundation
import ObjectiveC.runtime

enum TrueShuffleHookInstaller {
    private static var didInstall = false
    
    // Using a static variable to store the original implementation to avoid capture issues in blocks
    private static var originalWeightIMP: IMP?
    
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
        
        let classesPtr = UnsafeMutableRawPointer(classes)
        defer { free(classesPtr) }
        
        for index in 0 ..< Int(classCount) {
            let cls: AnyClass = classes[index]
            let className = NSStringFromClass(cls)
            
            // Be more specific with class names to avoid hooking unrelated classes
            let lowerClassName = className.lowercased()
            guard lowerClassName.contains("shuff") && 
                  (lowerClassName.contains("service") || lowerClassName.contains("impl")) else {
                continue
            }
            
            guard let weightMethod = class_getInstanceMethod(cls, weightSelector) else {
                continue
            }
            
            // Store the original implementation
            self.originalWeightIMP = method_getImplementation(weightMethod)
            
            let weightBlock: @convention(block) (AnyObject, AnyObject, Bool, Bool) -> Double = {
                object,
                track,
                _,
                _
            in
                guard let originalIMP = TrueShuffleHookInstaller.originalWeightIMP else {
                    return 0.0
                }
                let original = unsafeBitCast(originalIMP, to: WeightForTrackIMP.self)
                // Call original with false for recommended and mergedList to bypass weighting
                return original(object, weightSelector, track, false, false)
            }
            
            method_setImplementation(weightMethod, imp_implementationWithBlock(weightBlock as Any))
            
            if let weightedListMethod = class_getInstanceMethod(cls, weightedListSelector) {
                let weightedListBlock: @convention(block) (AnyObject, AnyObject, AnyObject) -> AnyObject? = {
                    _,
                    _,
                    _
                in
                    // Returning nil here might cause a crash if the app expects an array.
                    // It's safer to not hook this or return an empty array if we knew the type.
                    // For now, let's skip hooking this method as the weight hook is usually sufficient.
                    return nil 
                }
                // method_setImplementation(weightedListMethod, imp_implementationWithBlock(weightedListBlock as Any))
            }
            
            didInstall = true
            writeDebugLog("True Shuffle hooks installed on class: \(className)")
            return
        }
        
        writeDebugLog("True Shuffle: no compatible shuffle class found; feature not applied")
    }
}
