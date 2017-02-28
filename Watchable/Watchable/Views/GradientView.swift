//
//  GradientView.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

class GradientView: UIView {

    init(startColor: UIColor, endColor: UIColor) {

        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = false

        if let gradientLayer = self.layer as? CAGradientLayer {
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
