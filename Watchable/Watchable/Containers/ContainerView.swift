//
//  ContainerView.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/14/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import PureLayout
import UIKit

// MARK: - Container

internal protocol ContainerView {
    func configure()
}

// MARK: - Container Item

internal protocol ContainerViewItem: CellReuse {
    func configure()
}

// MARK: - Labeling

internal protocol ContainerLabeling {
    var labels: TwoVerticalStackedLabelsView? { get set }
}

// MARK: - Social

internal protocol ContainerSocial {
    var liking: UIView? { get set }
    var sharing: UIView? { get set }
    var saving: UIView? { get set }
}

// MARK: - Badging

internal protocol ContainerBadging {
    var topLeft: UIView? { get set }
    var topRight: UIView? { get set }
    var bottomLeft: UIView? { get set }
    var bottomRight: UIView? { get set }
}

// MARK: - Carousel

internal protocol ContainerCarousel: UICollectionViewDataSource {
    var dataSource: ContainerCarouselDataSource? { get set }
    var collectionView: UICollectionView? { get set }

    func collectionViewLayout() -> UICollectionViewFlowLayout
    func configureCollectionView()
    func registerCollectionViewCells()
}

internal protocol ContainerCarouselDataSource: NSObjectProtocol {
    func numberOfItems(forContainerView containerView: ContainerView) -> Int
}

extension ContainerCarousel where Self: UIView {
    func collectionViewLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        return layout
    }

    func configureCollectionView() {
        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: collectionViewLayout())

        if let collectionView = collectionView {
            collectionView.dataSource = self
            registerCollectionViewCells()

            self.addSubview(collectionView)
            collectionView.autoPinEdgesToSuperviewEdges()
        }
    }
}
