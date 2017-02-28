//
//  EmptyDataErrorView.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

class EmptyDataErrorView: UIView {

    let mErrorLabel = UILabel()
    var style: Style = LegacyStyle() // ToDo: Inject the style

    var errorText: String? {
        didSet {
            self.mErrorLabel.text = errorText
        }
    }

    init(frame: CGRect, errorMsg: String?) {

        super.init(frame: frame)

        self.isUserInteractionEnabled = true
        self.frame = CGRect(x: 0, y: 64, width: frame.size.width, height: frame.size.height - 64)
        self.backgroundColor = self.style.colorFor(.DarkBackground)

        configure(errorLabel: self.mErrorLabel, withMessage: errorMsg)
        addSubview(self.mErrorLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(errorLabel label: UILabel, withMessage message: String?) {
        label.frame = CGRect(x: 40, y: 0, width: frame.size.width - 80, height: frame.size.height)
        label.textAlignment = .center
        label.textColor = style.colorFor(.LightText)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        label.font = style.fontFor(.BoldText(16))
        label.text = message
    }
}
