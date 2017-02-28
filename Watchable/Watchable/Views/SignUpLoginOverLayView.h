//
//  SignUpLoginOverLayView.h
//  Watchable
//
//  Created by Valtech on 10/15/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignUpLoginOverLayView : UIView
@property (weak, nonatomic) IBOutlet UILabel *mDescLbl;
@property (weak, nonatomic) IBOutlet UIButton *mSignUpBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mSignUpButtonPortraitTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mDescTopConstraint;
@property (assign) BOOL isPresentedFromMyShows;
@property (assign) BOOL isPresentedInLandScape;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mLandscapeDescViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mLoginBtnPortaritBottomSpace;
- (void)addUIElements;

- (IBAction)onClickingSignUpBtn;
- (IBAction)onClickingCancelBtn;
- (IBAction)onClickingLogInBtn;
- (void)cancelSignInOverLay;
@end
