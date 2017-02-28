//
//  SavedController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal final class SavedController: BaseViewController, TopLevelWatchableViewController {
    override func commonInit() {
        super.commonInit()

        title = NSLocalizedString("Saved", comment: "The title of the Saved")
        tabBarItem.image = UIImage.Icon.TabBar.Inactive.saved.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = UIImage.Icon.TabBar.Active.saved.withRenderingMode(.alwaysOriginal)
    }
}
