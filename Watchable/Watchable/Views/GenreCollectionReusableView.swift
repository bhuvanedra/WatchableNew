//
//  GenreCollectionReusableView.swift
//  Watchable
//
//  Created by Dan Murrell on 1/26/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import UIKit

@IBDesignable
class GenreCollectionReusableView: UICollectionReusableView {

    @IBOutlet private var pageControl: UIPageControl?

    // swiftlint:disable private_outlet
    @IBOutlet var collectionVwOriginals: UICollectionView?
    @IBOutlet var lblHeaderTitle: UILabel?
    @IBOutlet var lblGenreTopTitle: UILabel?
    // swiftlint:enable private_outlet

    var pageControlIndex: Int = 0 {
        didSet {
            self.pageControl?.currentPage = pageControlIndex
        }
    }

    var totalPage: Int = 0 {
        didSet {
            self.pageControl?.numberOfPages = totalPage
        }
    }

    override func awakeFromNib() {

        super.awakeFromNib()
        self.pageControl?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }
}
