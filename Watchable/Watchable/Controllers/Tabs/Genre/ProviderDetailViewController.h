//
//  ProviderDetailViewController.h
//  Watchable
//
//  Created by Valtech on 3/11/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"
#import "Watchable-Swift.h"

@class ProviderModel;
@interface ProviderDetailViewController : ParentViewController <TrackingPathGenerating>

@property (nonatomic, strong) NSString *publisherApiFormat;
@property (weak, nonatomic) IBOutlet UIView *mProviderBGView;
@property (weak, nonatomic) IBOutlet UIImageView *mProviderImageView;
@property (strong, nonatomic) NSString *mProviderImageUrl;
@property (nonatomic, strong) ProviderModel *mProviderModel;
@end
