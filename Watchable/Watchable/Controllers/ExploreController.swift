//
//  ExploreController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal final class ExploreController: BaseViewController, TopLevelWatchableViewController {
    override func commonInit() {
        super.commonInit()

        title = NSLocalizedString("Explore", comment: "The title of the Explore")
        tabBarItem.image = UIImage.Icon.TabBar.Inactive.explore.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = UIImage.Icon.TabBar.Active.explore.withRenderingMode(.alwaysOriginal)
    }
}
