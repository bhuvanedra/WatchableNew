//
//  BaseNavigationController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal final class BaseNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex: 0xffffff)
    }
}
