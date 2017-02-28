//
//  PlayDetailCollectionViewCell.h
//  Watchable
//
//  Created by Raja Indirajith on 03/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Watchable-Swift.h"

@interface PlayDetailCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mVideoImageView;
@property (weak, nonatomic) IBOutlet UILabel *mVideoDescLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mBrandLogoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mImageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mImageViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet UILabel *mVideoTitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mFollowButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet CustomIndexButton *mFollowButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mBrandLogoImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mSpaceBetweenBrandLogoImageViewAndDescLabelConstraint;
@property (weak, nonatomic) IBOutlet UIView *mBrandLogoAndDescBGView;
@property (weak, nonatomic) IBOutlet UILabel *mVideoDurationLabel;

@end
