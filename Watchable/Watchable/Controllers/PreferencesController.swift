//
//  PreferencesController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal final class PreferencesController: BaseViewController, TopLevelWatchableViewController {
    override func commonInit() {
        super.commonInit()

        title = NSLocalizedString("Preferences", comment: "The title of the Preferences")
        tabBarItem.image = UIImage.Icon.TabBar.Inactive.preferences.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = UIImage.Icon.TabBar.Active.preferences.withRenderingMode(.alwaysOriginal)
    }
}
