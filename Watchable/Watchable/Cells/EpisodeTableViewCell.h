//
//  EpisodeTableViewCell.h
//  Watchable
//
//  Created by Raja Indirajith on 15/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EpisodeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *mTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *mProviderNameLabel;

@end
