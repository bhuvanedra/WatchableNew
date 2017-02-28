//
//  SignUpViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "SignUpViewController.h"

#import "AnalyticsEventsHandler.h"
#import "DBHandler.h"
#import "GAUtilities.h"
#import "PrivatePolicyViewController.h"
#import "ServerConnectionSingleton.h"
#import "SwrveUtility.h"
#import "TermsOfServiceViewController.h"
#import "Validator.h"

#define kTextVerifiedGreenColor [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0]

@interface SignUpViewController ()

@property (nonatomic, weak) UITextField *mCurrentTextFieldRef;
@property (nonatomic, strong) UIImageView *mCheckImageViewUserName;
@property (nonatomic, strong) UIImageView *mCheckImageViewEmail;
@property (nonatomic, strong) UIImageView *mCheckImageViewPassword;
@property (nonatomic, strong) IBOutlet UIButton *mSignUpButton;

@property (nonatomic, strong) UILabel *mTextOopsErrorMessageUserName;
@property (nonatomic, strong) UILabel *mTextOopsErrorMessageEmail;
@property (nonatomic, strong) UILabel *mTextOopsErrorMessagePassword;

@property (nonatomic, strong) NSString *mSignUpUserName;
@property (nonatomic, strong) NSString *mSignUpUserEmailId;
@property (nonatomic, strong) NSString *mSignUpPassword;

@end

@implementation SignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initalizeUISetup];
    // Do any additional setup after loading the view.
    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterEnter];
    /* Android design

    UIImage *athumbnail = [UIImage imageNamed:@"signUp0.png"];
    CGRect imageRect = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    UIGraphicsBeginImageContextWithOptions(athumbnail.size, NO, [UIScreen mainScreen].scale);
    [athumbnail drawInRect:imageRect];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    self.view.backgroundColor=[UIColor colorWithPatternImage:thumbnail];

     */
    isUserNameValid = false;
    isEmailValid = false;
    isPasswordValid = false;
    [self enableSignUpButton:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [GAUtilities setWatchbaleScreenName:@"SignUpScreen"];
}

- (void)initalizeUISetup
{
    self.mPasswordTextField.secureTextEntry = YES;
    self.mErrorViewTopConstraint.constant = 64 - 50;
    self.mErrorToastView.hidden = YES;

    if (self.view.frame.size.height <= 480)
    {
        self.mTermsandServiceBottomConstraint.constant = 120;
    }

    self.mPasswordGuidenceMsgLabel.text = @"";
    if (self.view.frame.size.width <= 320)
    {
        self.mUsernameTopConstraint.constant = 85.0;
        self.mUsernameandEmailGapConstraint.constant = 18.0;
        self.mEmailandPasswordGapConstraint.constant = 18.0;
        self.mTermsConditionLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:11.0];
    }
    [self createNavBarWithHidden:NO];
    if (self.isPresented)
    {
        [self createCancelButtonOnNavBar];
    }
    else
    {
        [self setBackButtonOnNavBar];
    }

    /* Android design
   // [self clearNavBarColor];
   */

    [self setNavigationBarTitle:@"SIGN UP" withFont:nil withTextColor:nil];
    // [self setSignUpDoneButtonOnNavBar];

    [Utilities addGradientToView:self.view withStartGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.0] withEndGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.2]];

    self.mUsernameTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Username (min 6 characters)"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];

    self.mEmailTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Email"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];

    self.mPasswordTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Password (min 6 characters)"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];

    [self.mUsernameTextField setTintColor:[UIColor darkGrayColor]];
    [self.mEmailTextField setTintColor:[UIColor darkGrayColor]];
    [self.mPasswordTextField setTintColor:[UIColor darkGrayColor]];

    //[self setUsernameErrorMessage:@"usern is invalid,  "];
    // [self setEmailIdErrorMessage:@"Email id is invalid, already existsw in server, please enter different username for register "];

    NSString *str = @"Privacy Policy ";

    UIFont *aFont = self.mTermsConditionLabel.font;
    NSLog(@"aFont=%f", aFont.pointSize);
    NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:aFont, NSFontAttributeName, [UIColor colorWithRed:62.0 / 255.0 green:175.0 / 255.0 blue:177.0 / 255.0 alpha:1.0], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];

    // Add attribute NSUnderlineStyleAttributeName
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:fontAttributes];
    [self.mPrivatePolicyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [self.mPrivatePolicyButton setAttributedTitle:attributedString forState:UIControlStateHighlighted];

    NSString *termofServiceStr = @"Terms of Service.";
    NSMutableAttributedString *attributedString1 = [[NSMutableAttributedString alloc] initWithString:termofServiceStr attributes:fontAttributes];
    [self.mTermsofServiceButton setAttributedTitle:attributedString1 forState:UIControlStateNormal];
    [self.mTermsofServiceButton setAttributedTitle:attributedString1 forState:UIControlStateHighlighted];
    self.mAgreeToLabel.font = aFont;
    //  [self showPasswordGuidanceLabel:YES];

    [self.mEmailTextField setRightViewMode:UITextFieldViewModeNever];
    [self.mUsernameTextField setRightViewMode:UITextFieldViewModeNever];
    [self.mPasswordTextField setRightViewMode:UITextFieldViewModeNever];

    /*
    UIImage *aCheckImage=[UIImage imageNamed:@"Check.png"];
    UIImageView *aEmailTickImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 9, 16, 16)];
    aEmailTickImageView.image=aCheckImage;
    [self.mEmailTextField setRightView:aEmailTickImageView];
    
    UIImageView *aUserNameTickImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 9, 16, 16)];
    aUserNameTickImageView.image=aCheckImage;
    [self.mUsernameTextField setRightView:aUserNameTickImageView];
    
    
    UIImageView *aPasswordTickImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 9, 16, 16)];
    aPasswordTickImageView.image=aCheckImage;
    [self.mPasswordTextField setRightView:aPasswordTickImageView];
     
     //[self.mEmailTextField setRightView:self.mCheckImageView];
     //[self.mUsernameTextField setRightView:self.mTextOopsErrorMessage];
     //[self.mPasswordTextField setRightView:self.mCheckImageView];
     */

    UIImage *aCheckImage = [UIImage imageNamed:@""];
    self.mCheckImageViewUserName = [[UIImageView alloc] initWithFrame:CGRectMake(0, 9, 16, 16)];
    self.mCheckImageViewUserName.image = aCheckImage;

    self.mCheckImageViewEmail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 9, 16, 16)];
    self.mCheckImageViewEmail.image = aCheckImage;

    self.mCheckImageViewPassword = [[UIImageView alloc] initWithFrame:CGRectMake(0, 9, 16, 16)];
    self.mCheckImageViewPassword.image = aCheckImage;

    self.mTextOopsErrorMessageUserName = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 45, 20)];
    self.mTextOopsErrorMessageUserName.backgroundColor = [UIColor clearColor];
    self.mTextOopsErrorMessageUserName.textColor = [UIColor redColor];
    self.mTextOopsErrorMessageUserName.text = @"";
    self.mTextOopsErrorMessageUserName.font = [UIFont fontWithName:@"AvenirNext-bold" size:12.0];

    self.mTextOopsErrorMessageEmail = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 45, 20)];
    self.mTextOopsErrorMessageEmail.backgroundColor = [UIColor clearColor];
    self.mTextOopsErrorMessageEmail.textColor = [UIColor redColor];
    self.mTextOopsErrorMessageEmail.text = @"";
    self.mTextOopsErrorMessageEmail.font = [UIFont fontWithName:@"AvenirNext-bold" size:12.0];

    self.mTextOopsErrorMessagePassword = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 45, 20)];
    self.mTextOopsErrorMessagePassword.backgroundColor = [UIColor clearColor];
    self.mTextOopsErrorMessagePassword.textColor = [UIColor redColor];
    self.mTextOopsErrorMessagePassword.text = @"";
    self.mTextOopsErrorMessagePassword.font = [UIFont fontWithName:@"AvenirNext-bold" size:12.0];

    UIImage *aCheckImageForTermsofService = [UIImage imageNamed:@"checkbox_selected.png"];
    UIImage *aUnCheckImageForTermsofService = [UIImage imageNamed:@"checkbox_unselected.png"];

    [self.mTermsofServiceCheckButton setImage:aCheckImageForTermsofService forState:UIControlStateSelected];
    [self.mTermsofServiceCheckButton setImage:aUnCheckImageForTermsofService forState:UIControlStateNormal];

    [self validateAndEnableDoneButton];
    //[self.mUsernameTextField becomeFirstResponder];
}

- (void)onClickingCancelButton
{
    [self.mCurrentTextFieldRef resignFirstResponder];
    AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
    if (aSharedDelegate.isTutorialOverLayPresentToUser)
    {
        if (self.presentedFromScreen == TutorialOverLayScreen)
        {
            [aSharedDelegate addTutorialOverLayView];
        }
        else if (self.presentedFromScreen == TabbarScreenByFollowAction)
        {
            //[aSharedDelegate showLoginSignInScreenForGuestUserOnClickingFollow];
        }
    }

    if (self.isPresentedFromMyShows)
    {
        [self cancelOverLay];
    }
    else
    {
        AppDelegate *aSharedDel = (AppDelegate *)kSharedApplicationDelegate;
        aSharedDel.isSignUpOverLayClicked = NO;
        CATransition *transition = [CATransition animation];
        transition.duration = 0.35;
        transition.timingFunction =
            [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromLeft;

        // NSLog(@"%s: self.view.window=%@", func, self.view.window);
        [self.view.window.layer addAnimation:transition forKey:nil];

        [self performSelector:@selector(cancelOverLay) withObject:nil afterDelay:0.35];
    }

    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)cancelOverLay
{
    [kSharedApplicationDelegate setPreviousSelectedIndexOfTabBarWhenCancelClicked];
}

- (void)setUsernameErrorMessage:(NSString *)aErrorMsg
{
    self.mUsernameErrorMsgLabel.text = aErrorMsg;

    if ([aErrorMsg length] > 0)
    {
        [self.mUsernameTextField setRightView:self.mTextOopsErrorMessageUserName];
        [self.mUsernameTextField setRightViewMode:UITextFieldViewModeAlways];
        isUserNameValid = false;
        self.mErrorLineUsername.backgroundColor = [UIColor redColor];
        [self.mUsernameTextField setTextColor:[UIColor redColor]];
        direction = 1;
        shakes = 0;
        [self shake:self.mUsernameTextField];
    }
    else
    {
        self.mErrorLineUsername.backgroundColor = [UIColor lightGrayColor];
        //[self.mUsernameTextField setRightViewMode:UITextFieldViewModeNever];
    }
}

- (void)setEmailIdErrorMessage:(NSString *)aErrorMsg
{
    self.mEmailErrorMsgLabel.text = aErrorMsg;
    if ([aErrorMsg length] > 0)
    {
        [self.mEmailTextField setRightView:self.mTextOopsErrorMessageEmail];
        [self.mEmailTextField setRightViewMode:UITextFieldViewModeAlways];
        [self.mEmailTextField setTextColor:[UIColor redColor]];
        isEmailValid = false;
        self.mErrorLineEmail.backgroundColor = [UIColor redColor];
        direction = 1;
        shakes = 0;
        [self shake:self.mEmailTextField];
    }
    else
    {
        self.mErrorLineEmail.backgroundColor = [UIColor lightGrayColor];
        //[self.mEmailTextField setRightViewMode:UITextFieldViewModeNever];
    }
}

- (void)showPasswordGuidanceLabel:(BOOL)show withText:(NSString *)aString withTextColor:(UIColor *)aColor
{
    self.mPasswordGuidenceMsgLabel.hidden = !show;

    if (show)
    {
        self.mPasswordGuidenceMsgLabel.text = aString;
        self.mPasswordGuidenceMsgLabel.textColor = aColor;
        self.mErrorLinePassword.backgroundColor = aColor;
    }
    else
    {
        self.mPasswordGuidenceMsgLabel.text = @"";
        self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
    }
}

- (BOOL)validateUserName
{
    BOOL isValidUserName = NO;
    if (self.mUsernameTextField.text.length)
    {
        isValidUserName = [Validator isUserNameValid:self.mUsernameTextField.text];
        if (!isValidUserName)
        {
            NSString *strUserName = self.mUsernameTextField.text;

            if (strUserName.length < 6)
            {
                [self setUsernameErrorMessage:@"Requires minimum of 6 characters"];
                [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUUsernameShort];
            }
            else
            {
                NSRange whiteSpaceRange = [strUserName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
                if (whiteSpaceRange.location != NSNotFound)
                {
                    NSLog(@"Found whitespace");
                    [self setUsernameErrorMessage:@"Username cannot contain spaces"];
                }
                else
                {
                    NSString *specialCharacterString = @"!~`@#$%^&*+();:={}[],.<>?\\/\"\'";
                    NSCharacterSet *specialCharacterSet = [NSCharacterSet
                        characterSetWithCharactersInString:specialCharacterString];

                    if ([strUserName.lowercaseString rangeOfCharacterFromSet:specialCharacterSet].length)
                    {
                        [self setUsernameErrorMessage:@"Special characters limited to _ and –"];
                        [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUUsernameSpec];
                    }
                    else
                    {
                        //            [self setUsernameErrorMessage:@"Minimum 6 characters. Special characters _ and - are allowed"];
                        [self setUsernameErrorMessage:@"Requires minimum of 6 characters"]; //updating error messages as per product requirement
                    }
                }
                if (self.view.frame.size.width <= 320)
                {
                    self.mUsernameandEmailGapConstraint.constant = 0.0;
                }
            }
        }
        else
        {
            [self setUsernameErrorMessage:@""];
            [self.mUsernameTextField setTextColor:[UIColor blackColor]];
            if (self.view.frame.size.width <= 320)
            {
                self.mUsernameandEmailGapConstraint.constant = 18.0;
            }
        }
    }
    else
    {
        [self setUsernameErrorMessage:@""];
        if (self.view.frame.size.width <= 320)
        {
            self.mUsernameandEmailGapConstraint.constant = 18.0;
        }
        /* [self setUsernameErrorMessage:@"Username should not be empty"];
        if(self.view.frame.size.width<=320)
        {
            self.mUsernameandEmailGapConstraint.constant=0.0;
        }*/
    }
    return isValidUserName;
}

- (BOOL)validateEmailId
{
    BOOL isValidEmail = NO;
    if (self.mEmailTextField.text.length)
    {
        isValidEmail = [Validator isEmailValid:self.mEmailTextField.text];
        if (!isValidEmail)
        {
            [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUEmailNotValid];

            [self setEmailIdErrorMessage:@"Enter a valid email address"];
            if (self.view.frame.size.width <= 320)
            {
                self.mEmailandPasswordGapConstraint.constant = 0.0;
            }
        }
        else
        {
            [self setEmailIdErrorMessage:@""];
            [self.mEmailTextField setTextColor:[UIColor blackColor]];
            if (self.view.frame.size.width <= 320)
            {
                self.mEmailandPasswordGapConstraint.constant = 18.0;
            }
        }
    }
    else
    {
        [self setEmailIdErrorMessage:@""];
        if (self.view.frame.size.width <= 320)
        {
            self.mEmailandPasswordGapConstraint.constant = 18.0;
        }

        /*[self setEmailIdErrorMessage:@"Email should not be empty"];
        if(self.view.frame.size.width<=320)
        {
            self.mEmailandPasswordGapConstraint.constant=0.0;
        }*/
    }
    return isValidEmail;
}

- (BOOL)validatePassword
{
    BOOL isValidEmail = NO;
    if (self.mPasswordTextField.text.length)
    {
        NSString *aErrorMsgStr = nil;
        isValidEmail = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsgStr];
        if (!isValidEmail)
        {
            [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUPasswordInvalid];

            //            [self showPasswordGuidanceLabel:YES withText:aErrorMsgStr withTextColor:[UIColor colorWithRed:245.0/255.0 green:63.0/255.0 blue:35.0/255.0 alpha:1.0]];
            [self showPasswordGuidanceLabel:YES withText:aErrorMsgStr withTextColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0]];
            self.mErrorLinePassword.backgroundColor = [UIColor redColor];
            [self.mPasswordTextField setRightView:self.mTextOopsErrorMessagePassword];
            [self.mPasswordTextField setRightViewMode:UITextFieldViewModeAlways];
            [self.mPasswordTextField setTextColor:[UIColor redColor]];
            direction = 1;
            shakes = 0;
            [self shake:self.mPasswordTextField];
            isPasswordValid = false;
        }
        else
        {
            [self showPasswordGuidanceLabel:NO withText:nil withTextColor:nil];
        }
    }
    return isValidEmail;
}

- (void)setPasswordHide:(BOOL)isHide
{
    if (isHide)
    {
        self.mPasswordTextField.secureTextEntry = YES;
    }
    else
    {
        //  self.mPasswordTextField.secureTextEntry=NO;
        self.mPasswordTextField.secureTextEntry = YES;
        self.mPasswordTextField.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
        self.mPasswordTextField.textColor = [UIColor blackColor];
    }
}

- (void)postSwrveSUErrorEvent:(NSString *)eventName andErrorCode:(NSString *)errorcode
{
    NSDictionary *payload = [SwrveUtility getErrorEventPayloadForCode:errorcode];
    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}

- (IBAction)onClickingSignUpBtn:(UIButton *)sender;
{
    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterStart_sign_up];
    [self onClickingDoneButton];
}

- (void)onClickingDoneButton
{
    __weak SignUpViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    if (!self.mErrorToastView.hidden)
    {
        self.mErrorToastView.hidden = YES;
        self.mErrorViewTopConstraint.constant = 64 - 50;
    }

    [self.mCurrentTextFieldRef resignFirstResponder];
    //    BOOL isEmailValid=[self validateEmailId];
    //    BOOL isUsernameValid=[self validateUserName];
    //    BOOL isPasswordValid=[self validatePassword];

    if (self.mUsernameTextField.rightViewMode == UITextFieldViewModeAlways && self.mEmailTextField.rightViewMode == UITextFieldViewModeAlways && self.mPasswordTextField.rightViewMode == UITextFieldViewModeAlways)
    {
        if (self.view.frame.size.width <= 320)
        {
            self.mUsernameTopConstraint.constant = 100.0;
            self.mUsernameandEmailGapConstraint.constant = 18.0;
            self.mEmailandPasswordGapConstraint.constant = 18.0;
        }

        [self createNewUserProfile];
    }
}

- (void)validateEmailIdFromServer
{
    __weak SignUpViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToValidateSignUpEmailId:self.mEmailTextField.text
        withResponseBlock:^(NSDictionary *responseDict) {
          NSNumber *aStatus = [responseDict objectForKey:@"Success"];

          if (aStatus.boolValue)
          {
              [weakSelf performSelectorOnMainThread:@selector(onEmailValidationSuccess) withObject:nil waitUntilDone:NO];
          }
          else
          {
              NSLog(@"Error in validating Email id");
          }

        }
        errorBlock:^(NSError *error) {

          if (error.code == 91)
          {
              [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUEmailTaken];
          }

          [weakSelf performSelectorOnMainThread:@selector(onEmailValidationFailur:) withObject:error waitUntilDone:NO];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)onEmailValidationFailur:(NSError *)aError
{
    self.mEmailErrorMsgLabel.text = aError.localizedDescription;
    self.mErrorLineEmail.backgroundColor = [UIColor redColor];
    [self.mEmailTextField setRightView:self.mTextOopsErrorMessageEmail];
    [self.mEmailTextField setRightViewMode:UITextFieldViewModeAlways];
    direction = 1;
    shakes = 0;
    [self shake:self.mEmailTextField];
    isEmailValid = false;
    if (self.view.frame.size.width <= 320)
    {
        self.mEmailandPasswordGapConstraint.constant = 0.0;
    }
}

- (void)onEmailValidationSuccess
{
    [self.mEmailTextField setRightView:self.mCheckImageViewEmail];
    [self.mEmailTextField setRightViewMode:UITextFieldViewModeAlways];
    //self.mErrorLineEmail.backgroundColor=[UIColor greenColor];
    isEmailValid = TRUE;
    self.mErrorLineEmail.backgroundColor = kTextVerifiedGreenColor;
    [self.mEmailTextField setTextColor:kTextVerifiedGreenColor];
    self.mEmailErrorMsgLabel.text = @"";
    if (self.view.frame.size.width <= 320)
    {
        self.mEmailandPasswordGapConstraint.constant = 18.0;
    }
    [self validateAndEnableDoneButton];
}

- (void)validateUserNameFromServer
{
    __weak SignUpViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToValidateSignUpUserName:self.mUsernameTextField.text
        withResponseBlock:^(NSDictionary *responseDict) {
          NSNumber *aStatus = [responseDict objectForKey:@"Success"];

          if (aStatus.boolValue)
          {
              [weakSelf performSelectorOnMainThread:@selector(onUsernameValidationSuccess) withObject:nil waitUntilDone:NO];
          }
          else
          {
              NSLog(@"Error in validating Email id");
          }

        }
        errorBlock:^(NSError *error) {

          if (error.code == 91)
          {
              [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUUsernameTaken];
          }
          [weakSelf performSelectorOnMainThread:@selector(onUsernameValidationFailur:) withObject:error waitUntilDone:NO];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)onUsernameValidationFailur:(NSError *)aError
{
    self.mUsernameErrorMsgLabel.text = aError.localizedDescription;
    self.mErrorLineUsername.backgroundColor = [UIColor redColor];

    [self.mUsernameTextField setRightView:self.mTextOopsErrorMessageUserName];
    [self.mUsernameTextField setRightViewMode:UITextFieldViewModeAlways];
    direction = 1;
    shakes = 0;
    [self shake:self.mUsernameTextField];
    isUserNameValid = false;
    //[self.mUsernameTextField setRightViewMode:UITextFieldViewModeNever];
    if (self.view.frame.size.width <= 320)
    {
        self.mUsernameandEmailGapConstraint.constant = 0.0;
    }
}

- (void)onUsernameValidationSuccess
{
    [self.mUsernameTextField setRightView:self.mCheckImageViewUserName];

    [self.mUsernameTextField setRightViewMode:UITextFieldViewModeAlways];
    //self.mErrorLineUsername.backgroundColor=[UIColor greenColor];
    self.mErrorLineUsername.backgroundColor = kTextVerifiedGreenColor;
    [self.mUsernameTextField setTextColor:kTextVerifiedGreenColor];

    isUserNameValid = TRUE;
    self.mUsernameErrorMsgLabel.text = @"";
    if (self.view.frame.size.width <= 320)
    {
        self.mUsernameandEmailGapConstraint.constant = 18.0;
    }

    [self validateAndEnableDoneButton];
}

- (void)validateAndEnableDoneButton
{
    //      if(self.mUsernameTextField.rightViewMode == UITextFieldViewModeAlways && self.mEmailTextField.rightViewMode == UITextFieldViewModeAlways && self.mPasswordTextField.rightViewMode == UITextFieldViewModeAlways && [self.mTermsofServiceCheckButton isSelected])
    if (self.mUsernameTextField.rightViewMode == UITextFieldViewModeAlways && self.mEmailTextField.rightViewMode == UITextFieldViewModeAlways && self.mPasswordTextField.rightViewMode == UITextFieldViewModeAlways && [self.mTermsofServiceCheckButton isSelected] && isUserNameValid && isEmailValid && isPasswordValid)
    {
        [self enableSignUpButton:YES];
    }
    else
    {
        [self enableSignUpButton:NO];
    }
}
- (void)enableSignUpButton:(BOOL)isEnable
{
    self.mSignUpButton.enabled = isEnable;
    if (isEnable)
    {
        self.mSignUpButton.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];
    }
    else
    {
        //        self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:151.0/255.0 green:151.0/255.0 blue:151.0/255.0 alpha:1.0];
        //        self.mSignUpButton.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:0.2];
        // Before Android design implementation Color code
        //   self.mSignUpButton.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:144.0/255.0 blue:226.0/255.0 alpha:0.2];

        self.mSignUpButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];
    }
}

- (void)createNewUserProfile
{
    //if error update error label with error msg

    NSDictionary *body = @{ @"userName" : self.mUsernameTextField.text,
                            @"password" : self.mPasswordTextField.text,
                            @"email" : self.mEmailTextField.text,
                            /*@"emailStatus":[NSNumber numberWithInt:1],*/ @"notifyUserOnCreation" : @"EMAIL",
                            @"confirmEmail" : [NSNumber numberWithInt:1] };

    self.mSignUpUserName = self.mUsernameTextField.text;
    self.mSignUpUserEmailId = self.mEmailTextField.text;
    self.mSignUpPassword = self.mPasswordTextField.text;
    // NSDictionary *body =@{@"userProfile":profileDict};
    __weak SignUpViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToSignUpNewUser:body
        withResponseBlock:^(NSDictionary *responseDict) {

          NSNumber *aStatus = [responseDict objectForKey:@"Success"];

          if (aStatus.boolValue)
          {
              [weakSelf performSelectorOnMainThread:@selector(onCreateNewUserProfileSuccess) withObject:nil waitUntilDone:NO];
          }
          else
          {
          }

        }
        errorBlock:^(NSError *error) {

          [self postSwrveSUErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kSUServerError];

          if (weakSelf)
          {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (error.code == kUserNameEmailUnavailableErrorCode)
                {
                    [weakSelf performSelectorOnMainThread:@selector(onCreateNewUserProfileFailure:) withObject:error waitUntilDone:NO];
                }
                else if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                /* else
                 {
                 [weakSelf performSelectorOnMainThread:@selector(onCreateNewUserProfileFailure:) withObject:error waitUntilDone:NO];
                 }*/
              }];
          }

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)onCreateNewUserProfileSuccess
{
    //   [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignUp];

    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterFinish_sign_up];
    [self enableSignUpButton:YES];
    [self enableBackButton:NO];
    [self validateUsernameAndPasswordFromServer];
}

- (void)validateUsernameAndPasswordFromServer
{
    //    [kSharedApplicationDelegate setTabBarControllerAsRootViewController];
    //    return;
    //if error update error label with error msg

    NSDictionary *body = @{ @"username" : self.mSignUpUserName,
                            @"password" : self.mSignUpPassword,
                            @"rememberMe" : @"true" };
    __weak SignUpViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToAuthenticateUserCrediential:body
        withResponseBlock:^(NSDictionary *responseDict) {
          NSNumber *aStatus = [responseDict objectForKey:@"isLoginSuccess"];

          if (aStatus.boolValue)
          {
              //[[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignIn];
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [Utilities setValueForKeyInUserDefaults:[responseDict objectForKey:@"LoginUserNameOrEmailKey"] key:@"LoginUserNameOrEmailKey"];

                [Utilities setValueForKeyInUserDefaults:[responseDict objectForKey:kAuthorizationKey] key:kAuthorizationKey];
                NSString *aVimondCookie = [responseDict objectForKey:@"Vimond-Cookie"];
                [Utilities setValueForKeyInUserDefaults:aVimondCookie key:@"Vimond-Cookie"];
                [weakSelf getUserProfile];

              }];
          }
          else
          {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf enableBackButton:YES];
                [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(validateUsernameAndPasswordFromServer) withInputParameters:nil];
              }];
          }

        }
        errorBlock:^(NSError *error) {

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            //            NSString *aErrorMsg=error.localizedDescription;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.hidden=NO;
            if (weakSelf)
            {
                [weakSelf enableBackButton:YES];
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(validateUsernameAndPasswordFromServer) withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(validateUsernameAndPasswordFromServer) withInputParameters:nil];
                }
                /*  else
                 {
                 NSString *aErrorMsg=error.localizedDescription;
                 weakSelf.mErrorMsgLabel.text=aErrorMsg;
                 weakSelf.mErrorMsgLabel.text=aErrorMsg;
                 weakSelf.mErrorMsgLabel.hidden=NO;
                 }*/
            }
          }];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)getUserProfile
{
    __weak SignUpViewController *weakSelf = self;

    NSString *aUsernameOrEmailStr = [Utilities getValueFromUserDefaultsForKey:@"LoginUserNameOrEmailKey"];
    NSString *aUsernameOrEmailKey = @"username";
    NSRange range = [aUsernameOrEmailStr rangeOfString:@"@"];
    if (range.location != NSNotFound)
    {
        aUsernameOrEmailKey = @"email";
    }
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aUsernameOrEmailStr, aUsernameOrEmailKey, nil];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetUserProfile:aDict
        withResponseBlock:^(NSDictionary *responseDict) {

          [weakSelf performSelectorOnMainThread:@selector(onGetProfileSuccessfull:) withObject:responseDict waitUntilDone:NO];

        }
        errorBlock:^(NSError *error) {

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            //            NSString *aErrorMsg=error.localizedDescription;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.hidden=NO;
            if (weakSelf)
            {
                [weakSelf enableBackButton:YES];
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getUserProfile) withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getUserProfile) withInputParameters:nil];
                }
            }
          }];

          //[weakSelf addNotificationForNetworkChanges];
          NSLog(@"error in getting user profile");

        }
        withVimondCookie:NO];
}

- (void)onGetProfileSuccessfull:(NSDictionary *)aResponseDict
{
    [[DBHandler sharedInstance] createUserProfileEntityInDB:aResponseDict];

    NSLog(@"onGetProfileSuccessfull");
    NSString *aStr = [aResponseDict objectForKey:@"emailStatus"];
    if (aStr)
    {
        if (![aStr isEqualToString:@"1"])
        {
            AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
            aSharedDelegate.isEmailConfirmedForUser = NO;
            aSharedDelegate.isEmailConfirmedStatusReceived = YES;
            [Utilities setValueForKeyInUserDefaults:[NSNumber numberWithBool:NO] key:@"emailStatus"];
        }
        else
        {
            AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
            aSharedDelegate.isEmailConfirmedForUser = YES;
            aSharedDelegate.isEmailConfirmedStatusReceived = YES;
            [Utilities setValueForKeyInUserDefaults:[NSNumber numberWithBool:YES] key:@"emailStatus"];
        }
    }
    AppDelegate *aSharedDel = (AppDelegate *)kSharedApplicationDelegate;
    aSharedDel.isSignUpOverLayClicked = NO;

    NSLog(@"sign 1");
    if (self.isPresented)
    {
        NSLog(@"sign 2");
        [kSharedApplicationDelegate signUpCompletedFromTutorialOverLayScreen];
        if (self.presentedFromScreen == TutorialOverLayScreen)
        {
            NSLog(@"sign 3");
            [kSharedApplicationDelegate addTutorialOverLayView];
        }
        else if (self.presentedFromScreen == TabbarScreenByFollowAction)
        {
            NSLog(@"sign 4");
            ((AppDelegate *)kSharedApplicationDelegate).isAppFromBGToFGFirstTimeToPlayListViewWillAppear = YES;
            // [kSharedApplicationDelegate showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshUserInterfaceWhenGuestLogIn" object:nil];
            [aSharedDel addTutorialOverLayView];
        }
        NSLog(@"sign 5");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(@"sign 6");
        [kSharedApplicationDelegate setTabBarControllerAsRootViewControllerFromSignUp:YES];
    }

    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignUp andUserId:(NSString *)[aResponseDict objectForKey:@"userId"]];
}

- (void)onCreateNewUserProfileFailure:(NSError *)aError
{
    [self performSelector:@selector(removeErrorToastView) withObject:nil afterDelay:10];
    self.mErrorToastViewLabel.text = aError.localizedDescription;

    self.mErrorViewTopConstraint.constant = 64;
    self.mErrorToastView.hidden = NO;

    //    [UIView animateWithDuration:.5
    //                     animations:^{
    //
    //                         self.mErrorViewTopConstraint.constant=64;
    //                         self.mErrorToastView.hidden=NO;
    //
    //                     }
    //                     completion:^(BOOL finished){
    //
    //
    //                     }];
}

- (void)removeErrorToastView
{
    self.mErrorToastView.hidden = YES;
    self.mErrorViewTopConstraint.constant = 64 - 50;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.mUsernameTextField == textField)
    {
        [self setUsernameErrorMessage:@""];
        // [self setUsernameErrorMessage:@""];
        [textField setRightViewMode:UITextFieldViewModeNever];
    }
    else if (self.mPasswordTextField == textField)
    {
        //        [self showPasswordGuidanceLabel:YES withText:@"Requires minimum of 6 characters" withTextColor:[UIColor colorWithRed:189.0/255.0 green:195.0/255.0 blue:199.0/255.0 alpha:1.0]];

        NSString *modifiedFieldText = [self.mPasswordTextField.text stringByReplacingCharactersInRange:range withString:string];
        self.mPasswordTextField.text = modifiedFieldText;

        NSString *aErrorMsg = nil;

        BOOL isVaild = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsg];
        if (isVaild)
        {
            [self.mPasswordTextField setRightView:self.mCheckImageViewPassword];
            [self.mPasswordTextField setRightViewMode:UITextFieldViewModeAlways];
            [self.mPasswordTextField setTextColor:kTextVerifiedGreenColor];
            self.mPasswordGuidenceMsgLabel.text = @"";
            self.mErrorLinePassword.backgroundColor = kTextVerifiedGreenColor;
            isPasswordValid = TRUE;
        }
        else
        {
            [self.mPasswordTextField setRightView:self.mTextOopsErrorMessagePassword];
            [self.mPasswordTextField setRightViewMode:UITextFieldViewModeNever];

            isPasswordValid = NO;
            self.mPasswordGuidenceMsgLabel.text = aErrorMsg;
            if ([aErrorMsg isEqualToString:@"Requires minimum of 6 characters"])
            {
                textField.textColor = [UIColor blackColor];
                self.mErrorLinePassword.backgroundColor = [UIColor blackColor];
            }
            else
            {
                [self.mPasswordTextField setTextColor:[UIColor redColor]];
                self.mErrorLinePassword.backgroundColor = [UIColor redColor];
            }
        }

        return NO;
    }
    else if (self.mEmailTextField == textField)
    {
        [self setEmailIdErrorMessage:@""];
        [textField setRightViewMode:UITextFieldViewModeNever];
    }

    textField.textColor = [UIColor blackColor];

    [self validateAndEnableDoneButton];

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (!self.mErrorToastView.hidden)
    {
        self.mErrorToastView.hidden = YES;
        self.mErrorViewTopConstraint.constant = 64 - 50;
    }
    self.mCurrentTextFieldRef = textField;
    if (textField == self.mPasswordTextField)
    {
        //        [self showPasswordGuidanceLabel:YES withText:@"Requires minimum of 6 characters" withTextColor:[UIColor colorWithRed:189.0/255.0 green:195.0/255.0 blue:199.0/255.0 alpha:1.0]];
        //        [self setPasswordHide:NO];
    }
    //    else
    //    {
    //        [self showPasswordGuidanceLabel:NO withText:nil withTextColor:nil];
    //
    ////        if(self.mPasswordTextField.text.length>=6)
    ////        {
    ////            [self showPasswordGuidanceLabel:NO withText:nil withTextColor:nil];
    ////        }
    ////        else
    ////        {
    ////          [self showPasswordGuidanceLabel:YES withText:@"Must contain at least 6 characters" withTextColor:[UIColor colorWithRed:245.0/255.0 green:63.0/255.0 blue:35.0/255.0 alpha:1.0]];
    ////        }
    //
    //    }

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == self.mUsernameTextField)
    {
        if (textField.rightView == self.mCheckImageViewUserName && textField.rightViewMode == UITextFieldViewModeAlways)
        {
            return YES;
        }

        BOOL isValidUserName = [self validateUserName];
        if (isValidUserName)
        {
            //validate against server
            [self validateUserNameFromServer];
        }
    }
    else if (textField == self.mEmailTextField)
    {
        if (textField.rightView == self.mCheckImageViewEmail && textField.rightViewMode == UITextFieldViewModeAlways)
        {
            return YES;
        }

        BOOL isValidEmailId = [self validateEmailId];
        if (isValidEmailId)
        {
            //validate against server
            [self validateEmailIdFromServer];
        }
    }
    else if (textField == self.mPasswordTextField)
    {
        if (textField.rightView == self.mCheckImageViewPassword && textField.rightViewMode == UITextFieldViewModeAlways)
        {
            return YES;
        }

        [self setPasswordHide:YES];
        BOOL isValidPassword = [self validatePassword];
        if (isValidPassword)
        {
            //validate against server
            [self.mPasswordTextField setRightView:self.mCheckImageViewPassword];
            [self.mPasswordTextField setTextColor:kTextVerifiedGreenColor];
            [self.mPasswordTextField setRightViewMode:UITextFieldViewModeAlways];
            // self.mErrorLinePassword.backgroundColor=[UIColor colorWithRed:83.0/255.0 green:209.0/255.0 blue:153.0/255.0 alpha:1.0];
            self.mErrorLinePassword.backgroundColor = kTextVerifiedGreenColor;
            isPasswordValid = TRUE;
            [self validateAndEnableDoneButton];
        }
    }
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //[textField resignFirstResponder];

    /* NSString* trimmedUsernameStr= [self.mUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString* trimmedEmailStr= [self.mEmailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(trimmedUsernameStr.length || trimmedEmailStr.length|| self.mPasswordTextField.text.length )
    {
        [self enableSignUpButton:YES];
    }
    else
    {
        [self enableSignUpButton:NO];
    }
    */

    if (textField == self.mUsernameTextField)
    {
        [self.mEmailTextField becomeFirstResponder];
    }

    if (textField == self.mEmailTextField)
    {
        [self.mPasswordTextField becomeFirstResponder];
    }

    if (textField == self.mPasswordTextField)
    {
        [textField resignFirstResponder];
        //[self onClickingDoneButton];
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onClickingPrivatePolicyBtn:(UIButton *)sender
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PrivatePolicyViewController *aPrivatePolicyViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PrivatePolicyViewController"];
    [self presentViewController:aPrivatePolicyViewController animated:YES completion:nil];
}

- (IBAction)onClickingTermsofServiceButton:(UIButton *)sender
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    TermsOfServiceViewController *aTermsOfServiceViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"TermsOfServiceViewController"];
    [self presentViewController:aTermsOfServiceViewController animated:YES completion:nil];
}

- (IBAction)onClickingTermsofServiceCheckButton:(UIButton *)sender
{
    self.mTermsofServiceCheckButton.selected = !self.mTermsofServiceCheckButton.selected;
    [self validateAndEnableDoneButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIViewController cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc
{
}
- (void)shake:(UIView *)theOneYouWannaShake
{
    [UIView animateWithDuration:0.08
        animations:^{
          theOneYouWannaShake.transform = CGAffineTransformMakeTranslation(5 * direction, 0);
        }
        completion:^(BOOL finished) {
          if (shakes >= 10)
          {
              theOneYouWannaShake.transform = CGAffineTransformIdentity;
              return;
          }
          shakes++;
          direction = direction * -1;
          [self shake:theOneYouWannaShake];
        }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES]; // this will do the trick
}

@end
