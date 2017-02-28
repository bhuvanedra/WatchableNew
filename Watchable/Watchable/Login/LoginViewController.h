//
//  LoginViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginParentViewController.h"

@interface LoginViewController : LoginParentViewController
{
    int direction;
    int shakes;
}
@property (weak, nonatomic) IBOutlet UIButton *mForgotPasswordButton;
@property (weak, nonatomic) IBOutlet UITextField *mUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *mPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *mErrorMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *mUsernameErrorMsg;
@property (weak, nonatomic) IBOutlet UILabel *mPasswordErrorMsg;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mForgetPasswordButtonBottomHeightConstraint;
@property (nonatomic, assign) BOOL isPresented;
@property (assign) BOOL isPresentedFromMyShows;
@property (weak, nonatomic) IBOutlet UIView *mErrorLineUserNameEmail;
@property (weak, nonatomic) IBOutlet UIView *mErrorLinePassword;

@property (nonatomic, assign) eSignUpLoginScreenPresentedFromScreen presentedFromScreen;
@end
