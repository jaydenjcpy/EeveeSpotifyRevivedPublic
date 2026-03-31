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
        return path.contains("/ads/") || 
               path.contains("/ad-logic/") ||
               path.contains("/ad-slot/") ||
               path.contains("/ad-inventory/") ||
               path.contains("/sponsored/") ||
               path.contains("/promoted/") ||
               path.contains("/upsell/") ||
               path.contains("/campaign/") ||
               path.contains("/billboard/") ||
               path.contains("/banner/") ||
               path.contains("/interstitial/") ||
               path.contains("/overlay/") ||
               path.contains("/popup/") ||
               path.contains("/pop-up/") ||
               path.contains("/search-ad/") ||
               path.contains("/home-ad/") ||
               path.contains("/marquee/") ||
               path.contains("/leavebehind/") ||
               path.contains("/display-ad/") ||
               path.contains("/fullbleed/") ||
               path.contains("/leaderboard/") ||
               path.contains("doubleclick") ||
               path.contains("googlesyndication") ||
               path.contains("ad.spotify.com") ||
               path.contains("ads.spotify.com") ||
               path.contains("spclient.wg.spotify.com/ads/") ||
               path.contains("spclient.wg.spotify.com/ad-logic/")
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
