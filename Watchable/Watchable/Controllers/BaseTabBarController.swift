//
//  BaseTabBarController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/9/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import PureLayout
import UIKit

internal final class BaseTabBarController: UITabBarController {
    let tabBarViewControllers = [
        BaseNavigationController(rootViewController: FeedController()),
        BaseNavigationController(rootViewController: ExploreController()),
        BaseNavigationController(rootViewController: SavedController()),
        BaseNavigationController(rootViewController: PreferencesController())
    ]

    var numberOfTabs: Int {
        return tabBarViewControllers.count
    }

    let highlightingView = UIView()
    var highlightingViewLeadingConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        constrainView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureHighlightingView()
    }

    func configureView() {
        viewControllers = tabBarViewControllers
        view.backgroundColor = UIColor(hex: 0xffffff)

        let tabTextAttributes = [NSForegroundColorAttributeName: UIColor(hex: 0xc7cacb)]

        UITabBarItem.appearance(whenContainedInInstancesOf: [BaseTabBarController.self]).setTitleTextAttributes(tabTextAttributes, for: .normal)
        UITabBarItem.appearance(whenContainedInInstancesOf: [BaseTabBarController.self]).setTitleTextAttributes(tabTextAttributes, for: .selected)

        configureHighlightingView()

        view.addSubview(highlightingView)
    }

    func constrainView() {
        constrainHighlightingView()
    }

    func configureHighlightingView() {
        highlightingView.backgroundColor = WatchableTweaks.assign(WatchableTweaks.tabBarHighlightColorTint)
    }

    func constrainHighlightingView() {
        highlightingView.translatesAutoresizingMaskIntoConstraints = false

        highlightingView.autoSetDimensions(to: highlightingViewSize())
        highlightingView.autoPinEdge(.bottom, to: .top, of: tabBar, withOffset: highlightingViewSize().height)
        highlightingViewLeadingConstraint = highlightingView.autoPinEdge(toSuperviewEdge: .leading, withInset: highlightingViewLeadingInset())
    }
}

// MARK: - Helper(s)

extension BaseTabBarController {
    func highlightingViewSize() -> CGSize {
        return CGSize(width: 50.0, height: 2.0)
    }

    func highlightingViewLeadingInset(withSelectedTabIndex selectedTabIndex: Int = 0) -> CGFloat {
        let widthOfTab = UIScreen.main.bounds.size.width / CGFloat(numberOfTabs)
        let additionalPadding = CGFloat(selectedTabIndex) * widthOfTab

        return ((widthOfTab - highlightingViewSize().width) / 2.0) + additionalPadding
    }
}

// MARK: - UITabBarDelegate

extension BaseTabBarController {
    override public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let leadingInset: CGFloat

        if let indexOfItem = tabBar.items?.index(of: item) {
            leadingInset = highlightingViewLeadingInset(withSelectedTabIndex: indexOfItem)
        } else {
            leadingInset = highlightingViewLeadingInset()
        }

        view.layoutIfNeeded()
        highlightingViewLeadingConstraint?.constant = leadingInset

        UIView.animate(
            withDuration: WatchableTweaks.assign(WatchableTweaks.tabBarHighlightAnimation.duration),
            delay: WatchableTweaks.assign(WatchableTweaks.tabBarHighlightAnimation.delay),
            usingSpringWithDamping: WatchableTweaks.assign(WatchableTweaks.tabBarHighlightAnimation.damping),
            initialSpringVelocity: WatchableTweaks.assign(WatchableTweaks.tabBarHighlightAnimation.initialSpringVelocity),
            options: .curveEaseInOut,
            animations: {
                self.view.layoutIfNeeded()
        }) { _ in

        }
    }
}
