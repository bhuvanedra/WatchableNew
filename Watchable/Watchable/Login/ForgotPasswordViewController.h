//
//  ForgotPasswordViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginParentViewController.h"

@interface ForgotPasswordViewController : LoginParentViewController
@property (weak, nonatomic) IBOutlet UITextField *mUsernameTextField;
@property (weak, nonatomic) IBOutlet UIButton *mSendPasswordResetLinkBtn;
@property (weak, nonatomic) IBOutlet UILabel *mErrorMsgLabel;
@property (weak, nonatomic) IBOutlet UIView *mForgotPasswordBGView;
@property (weak, nonatomic) IBOutlet UILabel *mEmailSentLabel;
@property (weak, nonatomic) IBOutlet UIButton *mLoginButton;
@property (weak, nonatomic) IBOutlet UIView *mSuccessOverLayView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mCancelButtonBottomHeight;
@property (weak, nonatomic) IBOutlet UIButton *mCancelButton;
@property (weak, nonatomic) IBOutlet UIView *mErrorLineUserNameEmail;

- (IBAction)onClickingCancelButton:(id)sender;
@end
