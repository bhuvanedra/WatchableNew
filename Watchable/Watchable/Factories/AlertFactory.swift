//
//  AlertFactory.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/7/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

internal final class AlertFactory: NSObject {
    internal static func logout(withLogoutButtonTappedHandler affirmativeHandler: @escaping ((UIAlertAction) -> Swift.Void)) -> UIAlertController {
        let message = NSLocalizedString("Are you sure?", comment: "The 'logout' alert's message")
        let affirmative = NSLocalizedString("Log Out", comment: "One of the 'logout' alert's buttons")
        let negative = NSLocalizedString("Cancel", comment: "One of the 'logout' alert's buttons")

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let affirmativeAction = UIAlertAction(title: affirmative, style: .default, handler: affirmativeHandler)
        let negativeAction = UIAlertAction(title: negative, style: .cancel)

        alert.addActions([negativeAction, affirmativeAction])

        return alert
    }

    internal static func emailNotSetUp() -> UIAlertController {
        let title = NSLocalizedString("Alert", comment: "The 'email not set up' alert's title")
        let message = NSLocalizedString("No registered email accounts. Add an account in Mail Settings.", comment: "The 'email not set up' alert's message")
        let affirmative = NSLocalizedString("Ok", comment: "The 'email not set up' alert's only button")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let affirmativeAction = UIAlertAction(title: affirmative, style: .default)

        alert.addAction(affirmativeAction)

        return alert
    }

    internal static func networkOffline() -> UIAlertController {
        let title = NSLocalizedString("Alert", comment: "The 'network offline' alert's title")
        let message = NSLocalizedString("Network connection appears to be offline.", comment: "The 'network offline' alert's message")
        let affirmative = NSLocalizedString("Ok", comment: "The 'network offline' alert's only button")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let affirmativeAction = UIAlertAction(title: affirmative, style: .default)

        alert.addAction(affirmativeAction)

        return alert
    }

    @objc(genericWatchableWithDefaultTitleAndMessage:)
    internal static func genericWatchableWithDefaultTitle(andMessage message: String) -> UIAlertController {
        let title = NSLocalizedString("Watchable", comment: "The 'generic Watchable' alert's title")

        return genericWatchable(withTitle: title, andMessage: message)
    }

    internal static func genericWatchable(withTitle title: String?, andMessage message: String) -> UIAlertController {
        let affirmative = NSLocalizedString("Ok", comment: "The 'generic Watchable' alert's only button")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let affirmativeAction = UIAlertAction(title: affirmative, style: .default)

        alert.addAction(affirmativeAction)

        return alert
    }
}

fileprivate extension UIAlertController {
    fileprivate func addActions(_ actions: [UIAlertAction]) {
        actions.forEach { self.addAction($0) }
    }
}
