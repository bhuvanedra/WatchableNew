//
//  SettingsViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"
#import "Watchable-Swift.h"

@interface SettingsViewController : ParentViewController <TrackingPathGenerating>
@property (nonatomic, assign) BOOL isPushedForConfirmEmail;
@end
