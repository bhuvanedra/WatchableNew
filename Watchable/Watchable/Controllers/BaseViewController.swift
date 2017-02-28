//
//  BaseViewController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal class BaseViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    func commonInit() {
        if let topLevelWatchableViewController = self as? TopLevelWatchableViewController {
            topLevelWatchableViewController.configureNavigationBar()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex: 0xe0e0e0)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
