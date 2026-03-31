import Orion
import Foundation
import UIKit

// MARK: - Safe Ad View Controllers and Views Hooks
// We use dynamic targetName and check if classes exist to prevent crashes on launch.
// We also avoid hooking initWithFrame on Swift classes as it causes ObjC swizzling crashes.

class MarqueeContentViewControllerHook: ClassHook<UIViewController> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        return NSClassFromString("MarqueeContentViewController") != nil ? "MarqueeContentViewController" : "UIViewController"
    }
    
    func viewDidLoad() {
        orig.viewDidLoad()
        if String(describing: type(of: target)) == "MarqueeContentViewController" {
            target.view.isHidden = true
            target.view.alpha = 0
            target.view.frame = .zero
        }
    }
    
    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        if String(describing: type(of: target)) == "MarqueeContentViewController" {
            target.dismiss(animated: false, completion: nil)
        }
    }
}

class MarqueeClassicContentViewControllerHook: ClassHook<UIViewController> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        // Use the exact mangled name found in the binary, or fallback to UIViewController
        let mangledName = "_TtC19Marquee_MarqueeImpl35MarqueeClassicContentViewController"
        if NSClassFromString(mangledName) != nil {
            return mangledName
        } else if NSClassFromString("MarqueeClassicContentViewController") != nil {
            return "MarqueeClassicContentViewController"
        }
        return "UIViewController"
    }
    
    func viewDidLoad() {
        orig.viewDidLoad()
        let className = String(describing: type(of: target))
        if className.contains("MarqueeClassicContentViewController") {
            target.view.isHidden = true
            target.view.alpha = 0
            target.view.frame = .zero
        }
    }
    
    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        let className = String(describing: type(of: target))
        if className.contains("MarqueeClassicContentViewController") {
            target.dismiss(animated: false, completion: nil)
        }
    }
}

class SPTBannerViewControllerHook: ClassHook<UIViewController> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        return NSClassFromString("SPTBannerViewController") != nil ? "SPTBannerViewController" : "UIViewController"
    }
    
    func viewDidLoad() {
        orig.viewDidLoad()
        if String(describing: type(of: target)) == "SPTBannerViewController" {
            target.view.isHidden = true
            target.view.alpha = 0
            target.view.frame = .zero
        }
    }
    
    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        if String(describing: type(of: target)) == "SPTBannerViewController" {
            target.dismiss(animated: false, completion: nil)
        }
    }
}

// Hooking layoutSubviews is safer than initWithFrame for Swift UIViews
class SPTBannerViewHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        return NSClassFromString("SPTBannerView") != nil ? "SPTBannerView" : "UIView"
    }
    
    func layoutSubviews() {
        orig.layoutSubviews()
        if String(describing: type(of: target)) == "SPTBannerView" {
            target.isHidden = true
            target.frame = .zero
        }
    }
}

// For Swift UI classes, we use the mangled names and only hook layoutSubviews
class DisplayAdCardElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        let mangledName = "_TtC22AdsPlatform_ElementKit22DisplayAdCardElementUI"
        return NSClassFromString(mangledName) != nil ? mangledName : "UIView"
    }
    
    func layoutSubviews() {
        orig.layoutSubviews()
        let className = String(describing: type(of: target))
        if className.contains("DisplayAdCardElementUI") {
            target.isHidden = true
            target.frame = .zero
        }
    }
}

class FullbleedDisplayAdElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    
    static var targetName: String {
        let mangledName = "_TtC22AdsPlatform_ElementKit27FullbleedDisplayAdElementUI"
        return NSClassFromString(mangledName) != nil ? mangledName : "UIView"
    }
    
    func layoutSubviews() {
        orig.layoutSubviews()
        let className = String(describing: type(of: target))
        if className.contains("FullbleedDisplayAdElementUI") {
            target.isHidden = true
            target.frame = .zero
        }
    }
}
