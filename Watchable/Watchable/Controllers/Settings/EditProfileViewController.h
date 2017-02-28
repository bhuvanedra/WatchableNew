//
//  EditProfileViewController.h
//  Watchable
//
//  Created by Abhilash on 5/18/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"

@protocol EditProfileViewControllerDelegate <NSObject>

- (void)profileUpdated;

@end

@interface EditProfileViewController : ParentViewController
@property (nonatomic, assign) BOOL isEditUserName;
@property (nonatomic, assign) BOOL isFromConfirmEmail;
@property (nonatomic, weak) id<EditProfileViewControllerDelegate> mDelegate;
@property (nonatomic, weak) IBOutlet UIButton *resendConfirmationEmailButton;
@property (nonatomic, weak) IBOutlet UIView *resendConfirmationBGView;
@end
