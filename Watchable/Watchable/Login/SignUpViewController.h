//
//  SignUpViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginParentViewController.h"
#import "WatchableConstants.h"
@interface SignUpViewController : LoginParentViewController
{
    int direction;
    int shakes;
    bool isUserNameValid;
    bool isEmailValid;
    bool isPasswordValid;
}
@property (weak, nonatomic) IBOutlet UILabel *mUsernameErrorMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *mEmailErrorMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *mPasswordGuidenceMsgLabel;
@property (weak, nonatomic) IBOutlet UITextField *mUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *mEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *mPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *mTermsConditionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mUsernameTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mUsernameandEmailGapConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mEmailandPasswordGapConstraint;
@property (weak, nonatomic) IBOutlet UIButton *mPrivatePolicyButton;
- (IBAction)onClickingPrivatePolicyBtn:(UIButton *)sender;
- (IBAction)onClickingTermsofServiceButton:(UIButton *)sender;
- (IBAction)onClickingTermsofServiceCheckButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *mTermsofServiceButton;
@property (weak, nonatomic) IBOutlet UILabel *mAgreeToLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mErrorViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTermsandServiceBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *mErrorToastView;
@property (weak, nonatomic) IBOutlet UILabel *mErrorToastViewLabel;
@property (nonatomic, assign) BOOL isPresented;
@property (nonatomic, assign) eSignUpLoginScreenPresentedFromScreen presentedFromScreen;
@property (weak, nonatomic) IBOutlet UIView *mErrorLineUsername;
@property (weak, nonatomic) IBOutlet UIView *mErrorLineEmail;
@property (weak, nonatomic) IBOutlet UIView *mErrorLinePassword;
@property (weak, nonatomic) IBOutlet UIButton *mTermsofServiceCheckButton;
@property (assign) BOOL isPresentedFromMyShows;
;
@end
