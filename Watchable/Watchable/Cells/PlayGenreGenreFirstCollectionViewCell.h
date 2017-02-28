//
//  PlayGenreGenreFirstCollectionViewCell.h
//  Watchable
//
//  Created by Valtech on 3/11/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayGenreGenreFirstCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mVideoImageView;
@property (weak, nonatomic) IBOutlet UIView *mVideoDetailBGView;
@property (weak, nonatomic) IBOutlet UIButton *mPlayButton;
@property (weak, nonatomic) IBOutlet UILabel *mVideoDescLabel;
@property (weak, nonatomic) IBOutlet UILabel *mVideoCategoryLabel;
@property (weak, nonatomic) IBOutlet UIButton *providerButton;

@property (weak, nonatomic) IBOutlet UIImageView *mProviderImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mChannelLogoImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mChannelLogoImageViewHeightConstraint;

@end
