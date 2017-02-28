//
//  ProviderCollectionViewCell.h
//  Watchable
//
//  Created by Valtech on 3/11/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProviderCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *showTitle;
@property (weak, nonatomic) IBOutlet UILabel *showDescription;
@property (weak, nonatomic) IBOutlet UIImageView *mChannelImage;

@end
