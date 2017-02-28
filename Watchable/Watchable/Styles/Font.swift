//
//  Font.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

enum FontItem {
    case BoldText(Int)
    case CondensedText(Int)
    case MediumText(Int)
    case RegularText(Int)
}

struct AvenirNext {

    static func regular(_ size: Int) -> UIFont! {
        return UIFont(name: "AvenirNext-Regular", size: CGFloat(size))
    }

    static func demiBold(_ size: Int) -> UIFont! {
        return UIFont(name: "AvenirNext-DemiBold", size: CGFloat(size))
    }

    static func medium(_ size: Int) -> UIFont! {
        return UIFont(name: "AvenirNext-Medium", size: CGFloat(size))
    }
}

struct AvenirNextCondensed {

    static func demiBold(_ size: Int) -> UIFont! {
        return UIFont(name: "AvenirNextCondensed-DemiBold", size: CGFloat(size))
    }
}

struct Lato {

    static func regular(_ size: Int) -> UIFont! {
        return UIFont(name: "Lato-Regular", size: CGFloat(size))
    }

    static func bold(_ size: Int) -> UIFont! {
        return UIFont(name: "Lato-Bold", size: CGFloat(size))
    }
}

struct Roboto {

    static func bold(_ size: Int) -> UIFont! {
        return UIFont(name: "Roboto-Bold", size: CGFloat(size))
    }

    static func medium(_ size: Int) -> UIFont! {
        return UIFont(name: "Roboto-Medium", size: CGFloat(size))
    }
}
