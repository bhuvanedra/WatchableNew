//
//  WatchableTweaks.swift
//  Watchable
//
//  Created by Dan Murrell on 2/3/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation
import SwiftTweaks

internal class TweaksEnabler: NSObject {
    internal func tweakableWindow(frame: CGRect) -> TweakWindow {
        return TweakWindow(frame: frame, tweakStore: WatchableTweaks.defaultStore)
    }

    internal var shouldUseNewUI: Bool {
        return WatchableTweaks.assign(WatchableTweaks.shouldUseNewUI)
    }

    internal var testPlaylistError: Bool {
        return WatchableTweaks.assign(WatchableTweaks.testPlaylistError)
    }

    internal var playlistErrorCode: Int {
        return WatchableTweaks.assign(WatchableTweaks.playlistErrorCode)
    }
}

internal struct WatchableTweaks: TweakLibraryType {
    internal static let shouldUseNewUI = Tweak("v2 UI", "New UI -- Restart required!", "Should use new UI", false)

    internal static let tabBarHighlightColorTint = Tweak("v2 UI", "Tab Bar Selection Highlighting", "Color", UIColor(hex: 0xe82465))
    internal static let tabBarHighlightAnimation = SpringAnimationTweakTemplate("v2 UI", "Tab Bar Selection Highlighting", duration: 0.25, delay: 0.0, damping: 0.75, initialSpringVelocity: 0.5)

    internal static let testPlaylistError = Tweak("Playlist", "Errors", "Always Show Playlist Error", false)
    internal static let playlistErrorCode = Tweak("Playlist", "Errors", "Error code", defaultValue: 4_000, min: 4_000, max: 4_005)

    internal static let defaultStore: TweakStore = {
        let allTweaks: [TweakClusterType] = [shouldUseNewUI, tabBarHighlightColorTint, tabBarHighlightAnimation, testPlaylistError, playlistErrorCode]
        let tweaksEnabled = TweakDebug.isActive

        return TweakStore(tweaks: allTweaks, enabled: tweaksEnabled)
    }()
}
