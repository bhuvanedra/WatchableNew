//
//  PlayDetailFirstCollectionViewCell.m
//  Watchable
//
//  Created by Raja Indirajith on 03/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PlayDetailFirstCollectionViewCell.h"

@implementation PlayDetailFirstCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.mVideoCategoryLabel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    self.mVideoCategoryLabel.layer.borderWidth = .5f;
}

@end
