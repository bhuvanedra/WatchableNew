//
//  Color.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

enum ColorItem {
    case DarkBackground
    case DarkBackgroundWithAlpha(CGFloat)
    case ErrorBackgroundWithAlpha(CGFloat)
    case HeaderText
    case LightText
    case SelectedText
}

public extension UIColor {
    public convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat(hex >> 16 & 0xff) / 255.0
        let green = CGFloat(hex >> 8 & 0xff) / 255.0
        let blue = CGFloat(hex & 0xff) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
