//
//  Style.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

protocol Style {

    var viewInsets: UIEdgeInsets { get }

    func colorFor(_ item: ColorItem) -> UIColor
    func fontFor(_ item: FontItem) -> UIFont
}

struct LegacyStyle: Style {

    var viewInsets = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)

    func colorFor(_ item: ColorItem) -> UIColor {

        switch item {
        case .DarkBackground:
            return UIColor(hex: 0x1b1d1e)

        case .DarkBackgroundWithAlpha(let alpha):
            return UIColor(hex: 0x1b1d1e, alpha: alpha)

        case .ErrorBackgroundWithAlpha(let alpha):
            return UIColor(hex: 0xf39c12, alpha: alpha)

        case .HeaderText:
            return UIColor(hex: 0x6A6E71)

        case .LightText:
            return UIColor(hex: 0xbdc3c7)

        case .SelectedText:
            return UIColor(hex: 0x2adc91)
        }
    }

    func fontFor(_ item: FontItem) -> UIFont {

        switch item {
        case .BoldText(let size):
            return AvenirNext.demiBold(size)

        case .CondensedText(let size):
            return AvenirNextCondensed.demiBold(size)

        case .MediumText(let size):
            return AvenirNext.medium(size)

        case .RegularText(let size):
            return AvenirNext.regular(size)
        }
    }
}
