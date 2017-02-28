//
//  HistoryCustomCell.h
//  Watchable
//
//  Created by Raja Indirajith on 01/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryCustomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mPublisherImageView;
@property (weak, nonatomic) IBOutlet UIImageView *mShowImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mPublisherLogoImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mPublisherLogoImageHeightConstraint;

@end
