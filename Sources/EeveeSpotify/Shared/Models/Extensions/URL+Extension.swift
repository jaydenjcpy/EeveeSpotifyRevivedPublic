import Foundation

extension URL {
    var isLyrics: Bool {
        self.path.contains("color-lyrics/v2")
    }
    
    var isPlanOverview: Bool {
        self.path.contains("GetPlanOverview")
    }
    
    var isShuffle: Bool {
        self.path.contains("shuffle")
    }
    
    var isPremiumPlanRow: Bool {
        self.path.contains("v1/GetPremiumPlanRow")
    }
    
    var isPremiumBadge: Bool {
        self.path.contains("GetYourPremiumBadge")
    }

    var isOpenSpotifySafariExtension: Bool {
        self.host == "eevee"
    }
    
    var isCustomize: Bool {
        self.path.contains("v1/customize")
    }
    
    var isBootstrap: Bool {
        self.path.contains("v1/bootstrap")
    }

    // Blocked endpoint matchers (session protection)

    var isDeleteToken: Bool {
        self.path.contains("DeleteToken")
    }

    var isAccountValidate: Bool {
        self.path.contains("signup/public")
    }

    var isOndemandSelector: Bool {
        self.path.contains("select-ondemand-set")
    }

    var isTrialsFacade: Bool {
        self.path.contains("trials-facade/start-trial")
    }

    var isPremiumMarketing: Bool {
        self.path.contains("premium-marketing/upsellOffer")
    }

    var isPendragonFetchMessageList: Bool {
        self.path.contains("pendragon") && self.path.contains("FetchMessageList")
    }

    var isPushkaTokens: Bool {
        self.path.contains("pushka-tokens")
    }
    
    var isAdRelated: Bool {
        let path = self.path.lowercased()
        let host = (self.host ?? "").lowercased()

        // Block known third-party ad networks by host
        let adHosts = [
            "doubleclick.net", "googlesyndication.com", "googleadservices.com",
            "adservice.google.com", "moatads.com", "scorecardresearch.com",
            "omtrdc.net", "demdex.net", "ads.spotify.com", "adserver.spotify.com",
            "spclient.wg.spotify.com"  // spclient serves ad payloads too
        ]
        for adHost in adHosts {
            if host.contains(adHost) && (
                path.contains("/ads/") || path.contains("/ad/") ||
                path.contains("advert") || path.contains("sponsor") ||
                path.contains("campaign") || path.contains("promoted") ||
                path.contains("billboard") || path.contains("banner") ||
                path.contains("interstitial") || path.contains("overlay") ||
                path.contains("takeover") || path.contains("native")
            ) {
                return true
            }
        }

        // Block ad-related path segments (Spotify's own ad delivery endpoints)
        return path.contains("/ads/")
            || path.contains("/ad/")
            || path.contains("/ad-logic/")
            || path.contains("/ad-slot/")
            || path.contains("/ad-slots/")
            || path.contains("/ad-inventory/")
            || path.contains("/ad-targeting/")
            || path.contains("/ad-decision/")
            || path.contains("/ad-request/")
            || path.contains("/ad-event/")
            || path.contains("/ad-impression/")
            || path.contains("/ad-click/")
            || path.contains("/ad-tracking/")
            || path.contains("/ad-measurement/")
            || path.contains("/advert/")
            || path.contains("/adverts/")
            || path.contains("/advertising/")
            || path.contains("/sponsored/")
            || path.contains("/promoted/")
            || path.contains("/upsell/")
            || path.contains("/upsells/")
            || path.contains("/campaign/")
            || path.contains("/campaigns/")
            || path.contains("/billboard/")
            || path.contains("/billboards/")
            || path.contains("/banner/")
            || path.contains("/banners/")
            || path.contains("/interstitial/")
            || path.contains("/interstitials/")
            || path.contains("/overlay/")
            || path.contains("/overlays/")
            || path.contains("/popup/")
            || path.contains("/pop-up/")
            || path.contains("/search-ad/")
            || path.contains("/search-ads/")
            || path.contains("/home-ad/")
            || path.contains("/home-ads/")
            || path.contains("/takeover/")
            || path.contains("/takeovers/")
            || path.contains("/native-ad/")
            || path.contains("/display-ad/")
            || path.contains("/video-ad/")
            || path.contains("/audio-ad/")
            || path.contains("/rewarded/")
            || path.contains("/offerwall/")
            || path.contains("doubleclick")
            || path.contains("googlesyndication")
            || path.contains("adservice.google")
            || path.contains("moatads")
            || path.contains("scorecardresearch")
            // Spotify spclient ad-specific paths
            || (path.contains("spclient") && (
                path.contains("ad-logic") || path.contains("adlogic") ||
                path.contains("adserver") || path.contains("ad-server")
            ))
    }

    // Additional session protection endpoints
    var isSessionInvalidation: Bool {
        self.path.contains("logout") || self.path.contains("sign-out") ||
        self.path.contains("session/purge") || self.path.contains("token/revoke") ||
        self.path.contains("auth/expire") ||
        (self.path.contains("melody") && self.path.contains("check")) ||
        self.path.contains("product-state") ||
        (self.path.contains("license") && self.path.contains("check"))
    }
}
