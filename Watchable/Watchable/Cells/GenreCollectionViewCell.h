//
//  GenreCollectionViewCell.h
//  Watchable
//
//  Created by Valtech on 3/9/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Watchable-Swift.h"

@interface GenreCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *showImage;
@property (weak, nonatomic) IBOutlet UILabel *showTitle;
@property (weak, nonatomic) IBOutlet UILabel *showDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mFollowButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet CustomIndexButton *mFollowButton;

@end
