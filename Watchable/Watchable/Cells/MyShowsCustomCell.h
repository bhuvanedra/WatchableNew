//
//  MyShowsCustomCell.h
//  Watchable
//
//  Created by Raja Indirajith on 01/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Watchable-Swift.h"

@interface MyShowsCustomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mShowImageView;
@property (weak, nonatomic) IBOutlet CustomIndexImageView *mPlayImageView;
@property (weak, nonatomic) IBOutlet UILabel *mShowTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *mShowDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *mPlayButtonBGView;

@end
