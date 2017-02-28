//
//  File.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/15/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal protocol TopLevelWatchableViewController {
    func configureNavigationBar()
}

internal protocol CellReuse {
    static func identifier() -> String
}

internal extension CellReuse where Self: UIView {
    static func identifier() -> String {
        return String(describing: Self.self)
    }
}

internal extension UIImage {
    // swiftlint:disable nesting
    // swiftlint:disable force_unwrapping
    enum Icon {
        enum NavigationBar {
            static let header = UIImage(assetIdentifier: .IogoHeader)!
            static let alertActive = UIImage(assetIdentifier: .IconAlertActive)!
            static let alertDefault = UIImage(assetIdentifier: .IconAlertDefault)!
            static let alertMuted = UIImage(assetIdentifier: .IconAlertMuted)!
        }
        enum TabBar {
            enum Active {
                static let explore = UIImage(assetIdentifier: .IconExploreActive)!
                static let feed = UIImage(assetIdentifier: .IconFeedActive)!
                static let preferences = UIImage(assetIdentifier: .IconPreferencesActive)!
                static let saved = UIImage(assetIdentifier: .IconSavedActive)!
            }
            enum Inactive {
                static let explore = UIImage(assetIdentifier: .IconExploreInactive)!
                static let feed = UIImage(assetIdentifier: .IconFeedInactive)!
                static let preferences = UIImage(assetIdentifier: .IconPreferencesInactive)!
                static let saved = UIImage(assetIdentifier: .IconSavedInactive)!
            }
        }

    }
    // swiftlint:enable force_unwrapping
    // swiftlint:enable nesting

    internal enum AssetIdentifier: String {
        case IconExploreActive, IconFeedActive, IconPreferencesActive, IconSavedActive
        case IconExploreInactive, IconFeedInactive, IconPreferencesInactive, IconSavedInactive
        case IogoHeader, IconAlertActive, IconAlertDefault, IconAlertMuted
    }

    internal convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }
}

extension TopLevelWatchableViewController where Self: UIViewController {
    func configureNavigationBar() {
        let leftNavigationImage = UIImage.Icon.NavigationBar.header.withRenderingMode(.alwaysOriginal)
        let rightNavigationImage = UIImage.Icon.NavigationBar.alertActive.withRenderingMode(.alwaysOriginal)

        navigationItem.titleView = UIView() // Setting an empty view so that the navigation title is suppressed

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIImageView(image: leftNavigationImage))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightNavigationImage, style: .plain, target: nil, action: nil)
    }
}
