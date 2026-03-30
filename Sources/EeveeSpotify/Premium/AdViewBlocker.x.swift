import Orion
import UIKit

// MARK: - AdViewBlocker
//
// Hooks the actual ad-rendering classes confirmed in Spotify v9.1.32 binary.
//
// CRITICAL LESSON FROM CRASH:
// The previous version crashed because it tried to swizzle INHERITED ObjC methods
// (didMoveToWindow, layoutSubviews, viewDidLoad) on Swift subclasses. Orion's
// ClassHook can only safely swizzle methods that are ACTUALLY DEFINED on the
// target class itself (i.e., present in the class's own ObjC method list).
//
// The safe approach: hook only selectors that are OWNED by each class
// (confirmed by binary analysis), and use ClassHook<NSObject> for all Swift classes.
//
// STRATEGY:
// Instead of hooking view lifecycle methods, we hook the FACTORY and PRESENTER
// classes that CREATE and SHOW the ads. If the factory returns nothing and the
// presenter never shows anything, the ads never appear — regardless of the
// underlying view class hierarchy.

// MARK: - DisplayAdCardElementFactoryImpl
// Mangled: _TtC23AdsPlatform_ElementImplP33_603627E8B0AC208963B3BB333CBD757C31DisplayAdCardElementFactoryImpl
// This factory creates DisplayAdCardElement instances for the Search/Home display ad cards.
// Confirmed selectors: adCardLogger, adEventsClient, dismissAction, viewedAction,
//                      videoPlayerManager, sectionDismisser, providers, etc.
// By making the factory's key properties return nil, no ad card element is created.
class DisplayAdCardElementFactoryHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC23AdsPlatform_ElementImplP33_603627E8B0AC208963B3BB333CBD757C31DisplayAdCardElementFactoryImpl"

    // Hook the dismissAction getter — returning nil prevents the ad from being set up
    func dismissAction() -> AnyObject? {
        return nil
    }

    // Hook viewedAction — prevents impression tracking and ad display
    func viewedAction() -> AnyObject? {
        return nil
    }

    // Hook providers — the factory uses this to build the ad element
    func providers() -> AnyObject? {
        return nil
    }

    // Hook shouldShowDismissButton — a no-op that prevents the ad card from initializing
    func shouldShowDismissButton() -> Bool {
        return false
    }
}

// MARK: - VideoAdCardElementFactoryImpl
// Mangled: _TtC23AdsPlatform_ElementImplP33_603627E8B0AC208963B3BB333CBD757C29VideoAdCardElementFactoryImpl
// Creates video ad card elements.
class VideoAdCardElementFactoryHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC23AdsPlatform_ElementImplP33_603627E8B0AC208963B3BB333CBD757C29VideoAdCardElementFactoryImpl"

    func dismissAction() -> AnyObject? {
        return nil
    }

    func viewedAction() -> AnyObject? {
        return nil
    }

    func providers() -> AnyObject? {
        return nil
    }

    func videoPlayerManager() -> AnyObject? {
        return nil
    }
}

// MARK: - MobileOverlayPresenterImpl
// Mangled: _TtC31AdsStandalone_MobileOverlayImpl26MobileOverlayPresenterImpl
// This is the presenter that decides when to show the Credit Karma / billboard overlay ad.
// Confirmed selectors: adOnAppOpenUIEventPublisher, currentOverlayInteractionType,
//                      currentNPVContextURI, isNPVVisible, sAdBillboardTitle, sAdBillboardDismiss
class MobileOverlayPresenterHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC31AdsStandalone_MobileOverlayImpl26MobileOverlayPresenterImpl"

    // Hook adOnAppOpenUIEventPublisher — this is the trigger for showing overlay ads on app open
    func adOnAppOpenUIEventPublisher() -> AnyObject? {
        return nil
    }

    // Hook currentOverlayInteractionType — returning nil prevents the overlay from being shown
    func currentOverlayInteractionType() -> AnyObject? {
        return nil
    }

    // Hook isNPVVisible — returning false prevents NPV-triggered overlay ads
    func isNPVVisible() -> Bool {
        return false
    }
}

// MARK: - MarqueeController
// Mangled: _TtC19Marquee_MarqueeImpl17MarqueeController
// Controls the Marquee (takeover/banner) ad display.
// Confirmed selectors: triggerSlotHandler, sendEventHandler, saveContentView,
//                      marqueeCollectionPlatform, textColorType
class MarqueeControllerHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC19Marquee_MarqueeImpl17MarqueeController"

    // Hook triggerSlotHandler — this is what triggers the marquee ad to appear
    func triggerSlotHandler() -> AnyObject? {
        return nil
    }

    // Hook sendEventHandler — prevents marquee event processing
    func sendEventHandler() -> AnyObject? {
        return nil
    }

    // Hook marqueeCollectionPlatform — prevents the marquee platform from being set up
    func marqueeCollectionPlatform() -> AnyObject? {
        return nil
    }
}

// MARK: - BrandAdSection (Browse/Search page)
// Mangled: _TtC21Browse_BrowsePageImpl14BrandAdSection
// The section that renders brand/display ads on the Browse and Search pages.
// Confirmed selectors: adMetadata, callToAction, promotionURI, tagline, density
class BrandAdSectionHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC21Browse_BrowsePageImpl14BrandAdSection"

    // Hook adMetadata — returning nil prevents the ad section from loading its content
    func adMetadata() -> AnyObject? {
        return nil
    }

    // Hook callToAction — prevents the CTA button from being set up
    func callToAction() -> AnyObject? {
        return nil
    }

    // Hook promotionURI — prevents the ad from having a destination
    func promotionURI() -> AnyObject? {
        return nil
    }
}

// MARK: - NativeAdsElementFactoryImpl
// Mangled: _TtC21NativeAds_ElementImpl27NativeAdsElementFactoryImpl
// Creates native ad elements (showcase/sponsored content).
// Confirmed selectors: showcaseContainerView, mediaView, defaultContentComponent,
//                      videoContentComponent, additionalInfoPresenter
class NativeAdsElementFactoryHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC21NativeAds_ElementImpl27NativeAdsElementFactoryImpl"

    func showcaseContainerView() -> AnyObject? {
        return nil
    }

    func mediaView() -> AnyObject? {
        return nil
    }

    func defaultContentComponent() -> AnyObject? {
        return nil
    }

    func videoContentComponent() -> AnyObject? {
        return nil
    }
}

// MARK: - DisplayAdCardElementUI (safe hook — only own selectors)
// Mangled: _TtC22AdsPlatform_ElementKit22DisplayAdCardElementUI
// Confirmed own selectors: surfaceName, display_ad_element, didNotifyStarted
// We hook display_ad_element to return nil, preventing the ad card from rendering.
class DisplayAdCardElementUIHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC22AdsPlatform_ElementKit22DisplayAdCardElementUI"

    // display_ad_element is the getter that returns the actual ad card view
    func display_ad_element() -> AnyObject? {
        return nil
    }

    // didNotifyStarted is called when the ad starts — we suppress it
    func didNotifyStarted() {
        // Do nothing — suppress the ad start notification
    }

    // surfaceName is used for ad tracking/logging — return empty string
    func surfaceName() -> AnyObject? {
        return "" as AnyObject
    }
}

// MARK: - VideoAdCardElementUI (safe hook — only own selectors)
// Mangled: _TtC22AdsPlatform_ElementKit20VideoAdCardElementUI
// Confirmed own selectors: lastVisibility, didDispatchStartedEvent, modalObserver
class VideoAdCardElementUIHook: ClassHook<NSObject> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC22AdsPlatform_ElementKit20VideoAdCardElementUI"

    func didDispatchStartedEvent() {
        // Suppress — do not dispatch the ad started event
    }

    func lastVisibility() -> AnyObject? {
        return nil
    }
}
