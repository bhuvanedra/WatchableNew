//
//  ErrorView.swift
//  Watchable
//
//  Created by Dan Murrell on 1/31/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

class ErrorView: UIView {

    var containerView: UIView!
    var errorImageView: UIImageView!
    var errorLabel: UILabel!
    var tryAgainButton: UIButton!
    var tryAgainParameters: [AnyObject]?
    var tryAgainSelector: Selector?
    var tryAgainController: UIViewController?
    var style: Style = LegacyStyle()    // ToDo: Inject the style

    init(frame: CGRect, withErrorType errorType: eErrorType) {
        super.init(frame: frame)

        configure(forErrorType: errorType)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(forErrorType errorType: eErrorType) {

        switch errorType {
        case InternetFailureWithTryAgainMessage:
            configureForInternetFailureWithTryAgainMessage()
            break

        case InternetFailureInLandingScreenTryAgainButton:
            configureForInternetFailureInLandingScreenTryAgainButton()
            break

        case InternetFailureWithTryAgainButton:
            configureForInternetFailureWithTryAgainButton()
            break

        case ServiceErrorWithTryAgainButton:
            configureForServiceErrorWithTryAgainButton()
            break

        case ServiceErrorWithTryAgainMessage:
            configureForServiceErrorWithTryAgainMessage()
            break

        case ServiceErrorWithTryAgainMessageForBitlyShortURL:
            configureForServiceErrorWithTryAgainMessageForBitlyShortURL()
            break

        default:
            break
        }
    }

    private func configureForInternetFailureWithTryAgainMessage() {
        useStandardView()
        useStandardErrorLabelWith(NSLocalizedString("You're not connected to the Internet, check your network connection and try again", comment: "Error when not connected to the internet, should try again"))
        useSwipeGestures()
        constrainStandardView()
    }

    private func configureForInternetFailureInLandingScreenTryAgainButton() {
        useLandingView()
        useAttentionImage()
        useLandingErrorLabel()
        useLandingTryAgainButton()
        constrainLandingView()
    }

    private func configureForInternetFailureWithTryAgainButton() {
        useStandardView()
        useStandardErrorLabelWith(NSLocalizedString("You're not connected to the Internet", comment: "Error message when not connected to the internet"))
        useStandardTryAgainButton()
        constrainStandardViewWithTryAgain()
    }

    private func configureForServiceErrorWithTryAgainButton() {
        useStandardView()
        useStandardErrorLabelWith(NSLocalizedString("A server error occurred", comment: "Error message for a general server error"))
        useStandardTryAgainButton()
        constrainStandardViewWithTryAgain()
    }

    private func configureForServiceErrorWithTryAgainMessage() {
        useStandardView()
        useStandardErrorLabelWith(NSLocalizedString("A server error occurred, please try again", comment: "Error message for a general server error, should try again"))
        useSwipeGestures()
        constrainStandardView()
    }

    private func configureForServiceErrorWithTryAgainMessageForBitlyShortURL() {
        useStandardView()
        useStandardErrorLabelWith(NSLocalizedString("There was an error generating your request, please try again shortly.", comment: "Error message when generating a bitly url"))
        useSwipeGestures()
        constrainStandardView()
    }

    private func useStandardView() {
        setupStandardView()
        setupContainerView()
        useErrorImage()
    }

    private func useLandingView() {
        backgroundColor = style.colorFor(.DarkBackground)
    }

    private func useAttentionImage() {
        // swiftlint:disable object_literal
        let attentionImage = UIImage(named: "attentionLarge")
        // swiftlint:enable object_literal

        errorImageView = UIImageView(image: attentionImage)
        addSubview(errorImageView)
    }

    private func useErrorImage() {
        // swiftlint:disable object_literal
        let errorImage = UIImage(named: "error")
        // swiftlint:enable object_literal

        errorImageView = UIImageView(image: errorImage)
        containerView.addSubview(errorImageView)
    }

    private func useStandardErrorLabelWith(_ text: String) {
        setupErrorLabel(text, color: UIColor.white)
        containerView.addSubview(errorLabel)
    }

    private func useLandingErrorLabel() {
        setupErrorLabel(NSLocalizedString("You're not connected to the Internet", comment: "Error message when not connected to the internet"), color: style.colorFor(.LightText))
        addSubview(errorLabel)
    }

    private func useStandardTryAgainButton() {
        setupTryAgainButton()
        tryAgainButton.setTitleColor(UIColor.white, for: .normal)
        containerView.addSubview(tryAgainButton)
    }

    private func useLandingTryAgainButton() {
        setupTryAgainButton()
        tryAgainButton.setTitleColor(style.colorFor(.LightText), for: .normal)
        addSubview(tryAgainButton)
    }

    private func useSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
    }

    private func setupStandardView() {
        clipsToBounds = true
        backgroundColor = UIColor.clear
    }

    private func setupContainerView() {
        containerView = UIView()
        containerView.backgroundColor = style.colorFor(.ErrorBackgroundWithAlpha(0.8))
        addSubview(containerView)
    }

    private func setupErrorLabel(_ text: String, color: UIColor) {
        errorLabel = UILabel()
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.text = text
        errorLabel.textAlignment = .center
        errorLabel.textColor = color
        errorLabel.font = style.fontFor(.BoldText(16))
    }

    private func setupTryAgainButton() {
        tryAgainButton = UIButton(type: .custom)
        tryAgainButton.setTitle(NSLocalizedString("Try again", comment: "Button title for Try again"), for: .normal)
        tryAgainButton.addTarget(self, action: #selector(tryAgainTapped), for: .touchUpInside)
        tryAgainButton.layer.borderWidth = 1.0
        tryAgainButton.layer.borderColor = UIColor.white.cgColor
        tryAgainButton.layer.cornerRadius = 2.0
        tryAgainButton.titleLabel?.font = style.fontFor(.RegularText(14))
        tryAgainButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    }

    private func constrainLandingView() {
        errorImageView.autoCenterInSuperview()
        errorLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        errorLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        errorLabel.autoPinEdge(.top, to: .bottom, of: errorImageView, withOffset: 22)
        tryAgainButton.autoPinEdge(.top, to: .bottom, of: errorLabel, withOffset: 38)
        tryAgainButton.autoAlignAxis(toSuperviewAxis: .vertical)
    }

    private func constrainStandardView() {
        constrainContainerView()
        constrainErrorImageAndLabel()
        errorLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
    }

    private func constrainStandardViewWithTryAgain() {
        constrainContainerView()
        constrainErrorImageAndLabel()
        constrainTryAgainButtonToErrorLabel()
    }

    private func constrainContainerView() {
        containerView.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
        containerView.autoPinEdge(toSuperviewEdge: .leading)
        containerView.autoPinEdge(toSuperviewEdge: .trailing)
        containerView.autoSetDimension(.height, toSize: 64, relation: .greaterThanOrEqual)
    }

    private func constrainErrorImageAndLabel() {
        errorImageView.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        errorImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        fixWidthFor(errorImageView)
        errorLabel.autoPinEdge(.leading, to: .trailing, of: errorImageView, withOffset: 15)
        errorLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 4)
        errorLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)
        errorLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        flexWidthFor(errorLabel)
    }

    private func constrainTryAgainButtonToErrorLabel() {
        tryAgainButton.autoPinEdge(.leading, to: .trailing, of: errorLabel, withOffset: 15)
        tryAgainButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        tryAgainButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        fixWidthFor(tryAgainButton)
    }

    private func fixWidthFor(_ view: UIView) {
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
    }

    private func flexWidthFor(_ view: UIView) {
        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }

    func tryAgainTapped() {

        if let tryAgainSelector = self.tryAgainSelector,
            let tryAgainController = self.tryAgainController,
            tryAgainController.responds(to: tryAgainSelector) {

            tryAgainController.perform(tryAgainSelector)
        }
    }

    func handleSwipe(_ gesture: UISwipeGestureRecognizer) {

        var newFrame = self.frame

        if gesture.direction == .left {
            newFrame.origin.x = -bounds.size.width
        } else if gesture.direction == .right {
            newFrame.origin.x = bounds.size.width
        }

        UIView.animate(withDuration: 0.5,
                       animations: {
                        self.frame = newFrame
        },
                       completion: { finished in
                        if finished {
                            self.isHidden = true
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.removeErrorView(from: self.tryAgainController)
                            }
                        }
        })
    }
}
