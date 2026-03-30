import Orion
import UIKit

// MARK: - AdViewBlocker
//
// This file hooks the ACTUAL ad rendering classes confirmed to exist in
// Spotify v9.1.32 by binary analysis. These classes are responsible for
// rendering every type of visual ad on the Search and Home screens:
//
//   DisplayAdCardElementUI  — The Cartier-style banner ad card (Search/Home)
//   VideoAdCardElementUI    — Video ad cards (Home feed)
//   MobileOverlayViewController — The Credit Karma full-screen overlay ad
//   MarqueeContentViewController — Marquee/takeover banner ads
//   ShowcaseElementUI       — Sponsored showcase cards (Browse)
//
// The strategy: make every ad view zero-size and hidden immediately on
// viewDidLoad / didMoveToWindow / viewWillAppear, so it is never visible.
// Also override frame/bounds to CGRect.zero so layout gives it no space.
//
// These class names are confirmed present in the Spotify 9.1.32 binary.
// Swift classes are registered with Objective-C using their mangled names.

// MARK: - DisplayAdCardElementUI
// Mangled ObjC name: _TtC22AdsPlatform_ElementKit22DisplayAdCardElementUI
// This is the primary display ad card shown on Search and Home screens.
// Confirmed in binary: AdsPlatform_ElementKit/DisplayAdCardElement.swift
class DisplayAdCardElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC22AdsPlatform_ElementKit22DisplayAdCardElementUI"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}

// MARK: - VideoAdCardElementUI
// Mangled ObjC name: _TtC22AdsPlatform_ElementKit20VideoAdCardElementUI
// Video ad card shown in the Home feed.
class VideoAdCardElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC22AdsPlatform_ElementKit20VideoAdCardElementUI"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}

// MARK: - MobileOverlayViewController
// Mangled ObjC name: _TtC31AdsStandalone_MobileOverlayImpl27MobileOverlayViewController
// Full-screen overlay ad (Credit Karma, etc.)
class MobileOverlayViewControllerHook: ClassHook<UIViewController> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC31AdsStandalone_MobileOverlayImpl27MobileOverlayViewController"

    func viewDidLoad() {
        // Do NOT call orig — prevent the ad view from loading at all
        target.view.isHidden = true
        target.view.alpha = 0
        target.view.frame = .zero
    }

    func viewWillAppear(_ animated: Bool) {
        // Do NOT call orig — prevent the ad from appearing
        target.view.isHidden = true
        target.view.alpha = 0
    }

    func viewDidAppear(_ animated: Bool) {
        // Dismiss immediately if it somehow appeared
        target.dismiss(animated: false, completion: nil)
    }
}

// MARK: - MarqueeContentViewController
// Marquee/takeover banner ads
class MarqueeContentViewControllerHook: ClassHook<UIViewController> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "MarqueeContentViewController"

    func viewDidLoad() {
        target.view.isHidden = true
        target.view.alpha = 0
        target.view.frame = .zero
    }

    func viewWillAppear(_ animated: Bool) {
        target.view.isHidden = true
        target.view.alpha = 0
    }

    func viewDidAppear(_ animated: Bool) {
        target.dismiss(animated: false, completion: nil)
    }
}

// MARK: - ShowcaseElementUI (NativeAds)
// Mangled ObjC name: _TtC21NativeAds_ElementImpl17ShowcaseElementUI
// Sponsored showcase cards on Browse/Search
class ShowcaseElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC21NativeAds_ElementImpl17ShowcaseElementUI"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}

// MARK: - ShowcaseMDCElementUI (NativeAds MDC variant)
// Mangled ObjC name: _TtC21NativeAds_ElementImpl20ShowcaseMDCElementUI
class ShowcaseMDCElementUIHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "_TtC21NativeAds_ElementImpl20ShowcaseMDCElementUI"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}

// MARK: - AdMobileOverlay (Components.UI.AdMobileOverlay)
// Plain ObjC class name confirmed in binary
class AdMobileOverlayHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "AdMobileOverlay"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}

// MARK: - MarqueeContentView
// The view component of marquee ads
class MarqueeContentViewHook: ClassHook<UIView> {
    typealias Group = BasePremiumPatchingGroup
    static let targetName = "MarqueeContentView"

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func didMoveToSuperview() {
        orig.didMoveToSuperview()
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
        target.removeFromSuperview()
    }

    func layoutSubviews() {
        target.isHidden = true
        target.alpha = 0
        target.frame = .zero
    }
}
