//
//  EmailTableViewCell.h
//  SettingsApp
//
//  Created by Abhilash on 4/27/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailNotificationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;
@property (weak, nonatomic) IBOutlet UILabel *txtlable;

@end
