//
//  PlayGenreGenreFirstCollectionViewCell.m
//  Watchable
//
//  Created by Valtech on 3/11/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PlayGenreGenreFirstCollectionViewCell.h"

@implementation PlayGenreGenreFirstCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self layoutIfNeeded];
    self.mVideoCategoryLabel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    self.mVideoCategoryLabel.layer.borderWidth = .5f;
}

@end
