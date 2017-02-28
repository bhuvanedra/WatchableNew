//
//  FeedController.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/13/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation
import PureLayout

internal final class FeedController: BaseViewController, TopLevelWatchableViewController {
    let scrollView = UIScrollView()

    let container1 = GridContainerView()
    let container2 = InLineContainerView()
    let container3 = ThumbnailContainerView()

    let edgeInsetForContainers: CGFloat = 15.0
    let offsetBetweenContainers: CGFloat = 15.0

    override func commonInit() {
        super.commonInit()

        title = NSLocalizedString("Feed", comment: "The title of the Feed")
        tabBarItem.image = UIImage.Icon.TabBar.Inactive.feed.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = UIImage.Icon.TabBar.Active.feed.withRenderingMode(.alwaysOriginal)

        container1.dataSource = self
        container2.dataSource = self
        container3.dataSource = self

        view.addSubview(scrollView)
        scrollView.addSubview(container1)
        scrollView.addSubview(container2)
        scrollView.addSubview(container3)

        scrollView.autoPinEdgesToSuperviewEdges()

        let containers: [UIView] = [container1, container2, container3]

        containers.forEach { container in
            container.autoPinEdge(toSuperviewEdge: .leading, withInset: edgeInsetForContainers)
            container.autoPinEdge(toSuperviewEdge: .trailing, withInset: edgeInsetForContainers)

            container.autoSetDimension(.height, toSize: 200)
            container.autoMatch(.width, to: .width, of: scrollView, withOffset: -(edgeInsetForContainers * 2))
        }

        container1.autoPinEdge(toSuperviewEdge: .top)
        container2.autoPinEdge(.top, to: .bottom, of: container1, withOffset: offsetBetweenContainers)
        container3.autoPinEdge(.top, to: .bottom, of: container2, withOffset: offsetBetweenContainers)
        container3.autoPinEdge(toSuperviewEdge: .bottom)
    }
}

extension FeedController: ContainerCarouselDataSource {
    func numberOfItems(forContainerView containerView: ContainerView) -> Int {
        return 25
    }
}
