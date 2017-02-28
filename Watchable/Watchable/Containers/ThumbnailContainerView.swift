//
//  ThumbnailContainerView.swift
//  Watchable
//
//  Created by Luke LaBonte on 2/14/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

internal final class ThumbnailContainerView: UIView, ContainerView, ContainerCarousel {
    internal var dataSource: ContainerCarouselDataSource?
    internal var collectionView: UICollectionView?

    init() {
        super.init(frame: CGRect())
        self.configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        self.configureCollectionView()
    }

    internal func registerCollectionViewCells() {
        collectionView?.register(ThumbnailContainerViewCell.self, forCellWithReuseIdentifier: ThumbnailContainerViewCell.identifier())
    }
}

extension ThumbnailContainerView {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailContainerViewCell.identifier(), for: indexPath)

        if let cell = cell as? ThumbnailContainerViewCell {
            cell.configure()
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else {
            return 0
        }

        return dataSource.numberOfItems(forContainerView: self)
    }
}
