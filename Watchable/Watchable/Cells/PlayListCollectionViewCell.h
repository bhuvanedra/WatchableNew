//
//  PlayListCollectionViewCell.h
//  Watchable
//
//  Created by Raja Indirajith on 21/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayListCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *mPlayTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mPlayListImageView;
@property (weak, nonatomic) IBOutlet UILabel *mPlayListCategoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *mPlayListNoofVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *mGenreTitleLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *mPlayListDescriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTitleLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mDescriptionLabelWidthConstraint;

@end
