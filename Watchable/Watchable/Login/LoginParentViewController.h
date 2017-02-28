//
//  LoginParentViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginParentViewController : UIViewController

@property (nonatomic, weak) UIView *mErrorView;
@property BOOL isFromSettings;
- (void)createNavBarWithHidden:(BOOL)isHidden;
- (void)setBackButtonOnNavBar;
- (void)setNavigationBarTitle:(NSString *)aString withFont:(UIFont *)aFont withTextColor:(UIColor *)aColor;
//-(void)setLogInButtonOnNavBar;
- (void)setSignUpDoneButtonOnNavBar;
- (void)hideBackButton:(BOOL)isHide;
- (void)enableSignUpDoneButton:(BOOL)isEnable;
- (void)enableSignInLoginButton:(BOOL)isEnable;
- (void)enableBackButton:(BOOL)isEnable;
- (void)setLoginButtonBGColorForSelectedState;
- (void)clearNavBarColor;
- (void)createCancelButtonOnNavBar;

@end
