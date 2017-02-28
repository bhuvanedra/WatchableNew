//
//  PlayDetailFirstCollectionViewCell.h
//  Watchable
//
//  Created by Raja Indirajith on 03/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayDetailFirstCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mVideoImageView;
@property (weak, nonatomic) IBOutlet UIView *mVideoDetailBGView;
@property (weak, nonatomic) IBOutlet UIButton *mPlayButton;
@property (weak, nonatomic) IBOutlet UILabel *mNoOfVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *mVideoDescLabel;
@property (weak, nonatomic) IBOutlet UILabel *mVideoCategoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *mVideoTitleLabel;

@end
