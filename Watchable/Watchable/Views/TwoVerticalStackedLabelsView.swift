//
//  TwoVerticalStackedLabelsView.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/17/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import PureLayout
import UIKit

// swiftlint:disable attributes
@IBDesignable internal class TwoVerticalStackedLabelsView: UIView {
// swiftlint:enable attributes

    fileprivate let topLabel = UILabel()
    fileprivate let bottomLabel = UILabel()

    fileprivate let paddingBetweenLabels: CGFloat = 15.0

    fileprivate var labelConstraints = [NSLayoutConstraint]()

    @IBInspectable internal var topLabelText: String = "" {
        didSet {
            topLabel.text = topLabelText

            setNeedsLayout()
        }
    }

    @IBInspectable internal var topLabelTextColor: UIColor = UIColor(hex: 0x595f6f) {
        didSet {
            topLabel.textColor = topLabelTextColor

            setNeedsLayout()
        }
    }

    @IBInspectable internal var topLabelNumberOfLines: Int = 2 {
        didSet {
            topLabel.numberOfLines = topLabelNumberOfLines

            setNeedsLayout()
        }
    }

    internal var topLabelFont: UIFont = UIFont.boldSystemFont(ofSize: 16) {
        didSet {
            topLabel.font = topLabelFont

            setNeedsLayout()
        }
    }

    @IBInspectable internal var bottomLabelText: String = "" {
        didSet {
            bottomLabel.text = bottomLabelText

            setNeedsLayout()
        }
    }

    @IBInspectable internal var bottomLabelTextColor: UIColor = UIColor(hex: 0x333333) {
        didSet {
            bottomLabel.textColor = bottomLabelTextColor

            setNeedsLayout()
        }
    }

    @IBInspectable internal var bottomLabelNumberOfLines: Int = 10 {
        didSet {
            bottomLabel.numberOfLines = bottomLabelNumberOfLines

            setNeedsLayout()
        }
    }

    internal var bottomLabelFont: UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            bottomLabel.font = bottomLabelFont

            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        createAndConfigureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        createAndConfigureSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        configureLayout()
    }

    func createAndConfigureSubviews() {
        configureView()
        attachSubviews()
        configureLayout()
    }

    func configureView() {
        configureTopLabel()
        configureBottomLabel()
    }

    func configureTopLabel() {
        topLabel.text = topLabelText
        topLabel.font = topLabelFont
        topLabel.textColor = topLabelTextColor
        topLabel.numberOfLines = topLabelNumberOfLines
    }

    func configureBottomLabel() {
        bottomLabel.text = bottomLabelText
        bottomLabel.font = bottomLabelFont
        bottomLabel.textColor = bottomLabelTextColor
        bottomLabel.numberOfLines = bottomLabelNumberOfLines
    }

    func attachSubviews() {
        addSubview(topLabel)
        addSubview(bottomLabel)
    }

    func configureLayout() {
        removeConstraints(labelConstraints)

        if bottomLabelText.characters.isEmpty {
            topLabel.autoPinEdgesToSuperviewEdges().forEach { labelConstraints.append($0) }
        } else {
            topLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

            labelConstraints.append(topLabel.autoPinEdge(toSuperviewEdge: .top))
            labelConstraints.append(topLabel.autoPinEdge(toSuperviewEdge: .leading))
            labelConstraints.append(topLabel.autoPinEdge(toSuperviewEdge: .trailing))

            labelConstraints.append(bottomLabel.autoPinEdge(.top, to: .bottom, of: topLabel, withOffset: paddingBetweenLabels))

            labelConstraints.append(bottomLabel.autoPinEdge(toSuperviewEdge: .bottom))
            labelConstraints.append(bottomLabel.autoPinEdge(toSuperviewEdge: .leading))
            labelConstraints.append(bottomLabel.autoPinEdge(toSuperviewEdge: .trailing))
        }
    }
}
