//
//  VideoDetailView.swift
//  Watchable
//
//  Created by Dan Murrell on 1/27/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import PureLayout
import SDWebImage
import UIKit

protocol UpdatingVideoDetalView: class {
    func update(videoModel: VideoModel)
    func setProviderImage(url: String)
}

class VideoDetailView: UIView {
    var indexPath: IndexPath?
    var followButton: CustomIndexButton!
    var publisherImageView: UIImageView!
    var publisherDescription: UILabel!
    var videoDescription: UITextView!
    var bgScrollView: UIScrollView!
    var bgView: UIView!
    var blurEffect: UIBlurEffect!
    var visualEffectView: UIVisualEffectView!
    var separatorView: UIView!
    var descriptionLabel: UILabel!
    var style: Style = LegacyStyle()    // ToDo: Inject the style

    var viewInsets = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        constrainUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setupBlurEffect()
        setupBGScrollView()
        setupBGView()
        setupPublisherImageView()
        setupFollowButton()
        setupPublisherDescription()
        setupSeparatorLine()
        setupDescriptionLabel()
        setupVideoDescription()
    }

    private func setupBlurEffect() {
        self.backgroundColor = style.colorFor(.DarkBackgroundWithAlpha(0.1))

        blurEffect = UIBlurEffect(style: .dark)
        visualEffectView = UIVisualEffectView(effect: blurEffect)
        addSubview(visualEffectView)
    }

    private func setupBGScrollView() {
        bgScrollView = UIScrollView()
        bgScrollView.backgroundColor = UIColor.clear
        addSubview(bgScrollView)
    }

    private func setupBGView() {
        bgView = UIView()
        bgView.backgroundColor = UIColor.clear
        bgScrollView.addSubview(bgView)
    }

    private func setupPublisherImageView() {
        publisherImageView = UIImageView()
        publisherImageView.backgroundColor = UIColor.black
        addSubview(publisherImageView)
    }

    private func setupFollowButton() {
        let labelTextForNormal = NSLocalizedString("follow",
                                                   comment: "The title for a button when the user is following")
        let labelTextForSelected = NSLocalizedString("following",
                                                     comment: "The title for a button when the user is not following")

        followButton = CustomIndexButton(type: .custom)
        followButton.adjustsImageWhenHighlighted = true
        followButton.titleLabel?.font = style.fontFor(.MediumText(15))
        followButton.setTitleColor(UIColor.white, for: .normal)
        followButton.setTitleColor(style.colorFor(.SelectedText), for: .selected)
        followButton.setTitle(labelTextForNormal, for: .normal)
        followButton.setTitle(labelTextForSelected, for: .selected)
        followButton.setTitle(nil, for: .highlighted)
        addSubview(followButton)
    }

    private func setupPublisherDescription() {
        publisherDescription = UILabel()
        publisherDescription.numberOfLines = 0
        publisherDescription.backgroundColor = UIColor.clear
        publisherDescription.textColor = style.colorFor(.LightText)
        publisherDescription.font = style.fontFor(.RegularText(14))
        bgView.addSubview(publisherDescription)
    }

    private func setupSeparatorLine() {
        separatorView = UIView()
        separatorView.backgroundColor = UIColor.black
        bgView.addSubview(separatorView)
    }

    private func setupDescriptionLabel() {
        let labelText = NSLocalizedString("description", comment: "The description for a video")

        descriptionLabel = UILabel()
        descriptionLabel.textColor = style.colorFor(.HeaderText)
        descriptionLabel.font = style.fontFor(.CondensedText(16))
        descriptionLabel.text = labelText.localizedUppercase
        bgView.addSubview(descriptionLabel)
    }

    private func setupVideoDescription() {
        videoDescription = UITextView()
        videoDescription.backgroundColor = UIColor.clear
        videoDescription.textColor = style.colorFor(.LightText)
        videoDescription.font = style.fontFor(.RegularText(14))
        videoDescription.isEditable = false
        videoDescription.isScrollEnabled = false
        bgView.addSubview(videoDescription)
    }

    private func constrainUI() {
        constrainVisualEffectView()
        constrainPublisherImageView()
        constrainFollowButton()
        constrainBGScrollView()
        constrainBGView()
        constrainPublisherDescription()
        constrainSeparatorView()
        constrainDescriptionLabel()
        constrainVideoDescription()
    }

    private func constrainVisualEffectView() {
        visualEffectView.autoPinEdgesToSuperviewEdges()
    }

    private func constrainPublisherImageView() {
        let imageSize = CGSize(width: 190, height: 22)
        publisherImageView.autoPinEdge(toSuperviewEdge: .left, withInset: style.viewInsets.left)
        publisherImageView.autoPinEdge(toSuperviewEdge: .top, withInset: style.viewInsets.top)
        publisherImageView.autoSetDimensions(to: imageSize)
    }

    private func constrainFollowButton() {
        followButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
    }

    private func constrainBGScrollView() {
        bgScrollView.autoPinEdge(toSuperviewEdge: .leading)
        bgScrollView.autoPinEdge(toSuperviewEdge: .trailing)
        bgScrollView.autoPinEdge(.top, to: .bottom, of: publisherImageView, withOffset: 20)
        bgScrollView.autoPinEdge(toSuperviewEdge: .bottom)
    }

    private func constrainBGView() {
        bgView.autoPinEdge(toSuperviewEdge: .top)
        bgView.autoPinEdge(toSuperviewEdge: .bottom)
        bgView.autoPinEdge(.leading, to: .leading, of: self, withOffset: 0)
        bgView.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: 0)
    }

    private func constrainPublisherDescription() {
        publisherDescription.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        publisherDescription.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        publisherDescription.autoPinEdge(toSuperviewEdge: .top, withInset: style.viewInsets.top)
    }

    private func constrainSeparatorView() {
        separatorView.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        separatorView.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        separatorView.autoPinEdge(.top, to: .bottom, of: publisherDescription, withOffset: 15)
        separatorView.autoSetDimension(.height, toSize: 1)
    }

    private func constrainDescriptionLabel() {
        descriptionLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        descriptionLabel.autoPinEdge(.top, to: .bottom, of: separatorView, withOffset: 15)
    }

    private func constrainVideoDescription() {
        videoDescription.autoPinEdge(toSuperviewEdge: .leading, withInset: style.viewInsets.left)
        videoDescription.autoPinEdge(toSuperviewEdge: .trailing, withInset: style.viewInsets.right)
        videoDescription.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 2)
        videoDescription.autoPinEdge(toSuperviewEdge: .bottom, withInset: -10, relation: .lessThanOrEqual)
    }
}

extension VideoDetailView: UpdatingVideoDetalView {

    func update(videoModel: VideoModel) {
        followButton.isSelected = videoModel.isVideoFollowing
        publisherDescription.text = videoModel.title

        if let description = videoModel.shortDescription.characters.isEmpty == false ?
            videoModel.shortDescription : videoModel.longDescription, description.characters.isEmpty == false {

            if let postDate = Utilities.postDate(from: videoModel.liveBroadcastTime) {
                let format = NSLocalizedString("Posted on %@", comment: "Formatted Posted on (date)")
                let postDateString = String(format: format, postDate)
                videoDescription.text = String(format: "%@\n\n%@", description, postDateString)
            } else {
                videoDescription.text = description
            }
        }

        if let imageURL = videoModel.channelInfo.imageUri {
            setProviderImage(url: imageURL)
        }

        setFollowButtonHighlightProperty(selected: followButton.isSelected)

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    func setProviderImage(url: String) {
        publisherImageView.backgroundColor = UIColor.clear

        let imageSize = CGSize(width: 190, height: 22)

        if let providerImageURLString = ImageURIBuilder.buildImageUrl(with: url,
                                                                      for: Horizontal_lc_logo,
                                                                      with: imageSize),
            let providerImageURL = URL(string: providerImageURLString) {
            publisherImageView.contentMode = .scaleAspectFit
            publisherImageView.sd_setImage(with: providerImageURL, completed: nil)
        } else {
            publisherImageView.image = nil
        }

    }

    func setFollowButtonHighlightProperty(selected: Bool) {

        if selected {
            followButton.setImage(followButton.image(for: .selected), for: .normal)
            followButton.setTitle(followButton.title(for: .selected), for: .normal)
            followButton.setTitleColor(followButton.titleColor(for: .selected), for: .normal)
        } else {
            // swiftlint:disable object_literal
            let followImage = UIImage(named: "addSmall")
            // swiftlint:enable object_literal
            followButton.setImage(followImage, for: .normal)
            followButton.setTitle(NSLocalizedString("follow", comment: ""), for: .normal)
            followButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
}
