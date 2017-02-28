//
//  LoginViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "LoginViewController.h"
#import "Validator.h"
#import "ServerConnectionSingleton.h"
#import "DBHandler.h"
#import "AnalyticsTokens.h"
#import "AnalyticsEventsHandler.h"
#import "ForgotPasswordViewController.h"
#import "SwrveUtility.h"
#import "GAUtilities.h"

@interface LoginViewController () <UITextFieldDelegate, CAAnimationDelegate>
@property (nonatomic, weak) UITextField *mCurrentTextFieldRef;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initalizeUISetup];
    //[self enableSignInLoginButton:NO];
    /* Android design
    UIImage *athumbnail = [UIImage imageNamed:@"signUp1.png"];
    CGRect imageRect = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    UIGraphicsBeginImageContextWithOptions(athumbnail.size, NO, [UIScreen mainScreen].scale);
    [athumbnail drawInRect:imageRect];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    self.view.backgroundColor=[UIColor colorWithPatternImage:thumbnail];
    */
    // Do any additional setup after loading the view.

    //    [self.mPasswordTextField addTarget:self
    //                       action:@selector(onClickingLoginButton)
    //             forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"LogInScreen"];
}

- (void)onClickingCancelButton
{
    [self.mCurrentTextFieldRef resignFirstResponder];
    // AppDelegate *aSharedDelegate= kSharedApplicationDelegate;
    if (self.presentedFromScreen == TabbarScreenByFollowAction)
    {
        // [aSharedDelegate showLoginSignInScreenForGuestUserOnClickingFollow];
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

- (void)initalizeUISetup
{
    [self createNavBarWithHidden:NO];
    /* Android design
    [self clearNavBarColor];
    */
    if (self.isPresented)
    {
        [self createCancelButtonOnNavBar];
    }
    else
    {
        [self setBackButtonOnNavBar];
    }
    [self setNavigationBarTitle:@"WELCOME BACK!" withFont:nil withTextColor:nil];
    //[self setLogInButtonOnNavBar];
    [Utilities addGradientToView:self.view withStartGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.0] withEndGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.2]];

    NSString *str = @"Forgot password?";
    UIFont *aFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:aFont, NSFontAttributeName, [UIColor colorWithRed:0.00 / 255.0 green:127.0 / 255.0 blue:255.0 / 255.0 alpha:1.0], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];

    // Add attribute NSUnderlineStyleAttributeName
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:fontAttributes];
    [self.mForgotPasswordButton setAttributedTitle:attributedString forState:UIControlStateNormal];

    //    [self.mUsernameTextField setValue:[UIColor colorWithRed:189.0/255.0 green:195.0/255.0 blue:199.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    //    [self.mPasswordTextField setValue:[UIColor colorWithRed:189.0/255.0 green:195.0/255.0 blue:199.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];

    self.mUsernameTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Username or Email"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];

    self.mPasswordTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Password"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];
    [self.mUsernameTextField setTintColor:[UIColor darkGrayColor]];
    [self.mPasswordTextField setTintColor:[UIColor darkGrayColor]];
    self.mErrorMsgLabel.text = @"";
    self.mErrorMsgLabel.hidden = YES;
    /* Android design
      [Utilities setAppBackgroundcolorForView:self.view];
    */
    if (self.view.frame.size.height <= 480)
    {
        self.mForgetPasswordButtonBottomHeightConstraint.constant = 147;
    }
}
- (IBAction)onClickingForgetPasswordBtn:(id)sender
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ForgotPasswordViewController *aForgotPasswordViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"ForgotPasswordViewController"];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //    transition.type = kCATransitionFromRight;
    //    [transition setType:kCATransitionPush];
    //    transition.subtype = kCATransitionFromRight;
    //    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];

    [self.navigationController pushViewController:aForgotPasswordViewController animated:NO];
}

- (void)popController
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionFromLeft;
    [transition setType:kCATransitionPush];
    transition.subtype = kCATransitionFromLeft;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}
//-(void)onClickingLoginButton
- (IBAction)onClickingLoginButton:(UIButton *)sender
{
    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterStart_log_in];
    __weak LoginViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
    [self.mCurrentTextFieldRef resignFirstResponder];
    self.mErrorMsgLabel.text = @"";
    NSString *trimmedUsernameStr = [self.mUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isValidUsername = NO;
    if (trimmedUsernameStr.length <= 0)
    {
        self.mUsernameErrorMsg.text = @"Username or Email should not be empty";
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        [self.mUsernameTextField setTextColor:[UIColor redColor]];

        direction = 1;
        shakes = 0;
        [self shake:self.mUsernameTextField];
    }
    else if ([trimmedUsernameStr rangeOfString:@"@"].location == NSNotFound && trimmedUsernameStr.length < 6)
    {
        self.mUsernameErrorMsg.text = @"Requires minimum of 6 characters";
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        [self.mUsernameTextField setTextColor:[UIColor redColor]];
        direction = 1;
        shakes = 0;
        [self shake:self.mUsernameTextField];
    }
    else
    {
        isValidUsername = YES;
        self.mUsernameErrorMsg.text = @"";
        //[self.mUsernameTextField setTextColor:[UIColor blackColor]];
        // self.mErrorLineUserNameEmail.backgroundColor=[UIColor lightGrayColor];
    }
    NSString *aErrorMsg = nil;
    BOOL isValidPassword = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsg];

    if (isValidPassword)
    {
        self.mPasswordErrorMsg.text = @"";
        // self.mErrorLinePassword.backgroundColor=[UIColor lightGrayColor];
        // [self.mPasswordTextField setTextColor:[UIColor blackColor]];
    }
    else
    {
        self.mPasswordErrorMsg.text = aErrorMsg;
        self.mErrorLinePassword.backgroundColor = [UIColor redColor];
        [self.mPasswordTextField setTextColor:[UIColor redColor]];

        direction = 1;
        shakes = 0;
        [self shake:self.mPasswordTextField];
    }

    [self setForgetPasswordButtonBottomHeigthConstraintAsPerDeviceWhileErrorOccurs];
    if (isValidUsername && isValidPassword)
    {
        [self validateUsernameAndPasswordFromServer];

        //validate against server
    }
    //[kSharedApplicationDelegate setTabBarControllerAsRootViewController];
}

- (void)validateUsernameAndPasswordFromServer
{
    //    [kSharedApplicationDelegate setTabBarControllerAsRootViewController];
    //    return;
    //if error update error label with error msg

    [self enableSignInLoginButton:NO];
    [self setLoginButtonBGColorForSelectedState];
    NSDictionary *body = @{ @"username" : self.mUsernameTextField.text,
                            @"password" : self.mPasswordTextField.text,
                            @"rememberMe" : @"true" };
    __weak LoginViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToAuthenticateUserCrediential:body
        withResponseBlock:^(NSDictionary *responseDict) {
          NSNumber *aStatus = [responseDict objectForKey:@"isLoginSuccess"];

          if (aStatus.boolValue)
          {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                [[AnalyticsTokens new] getAnalyticsTokens];
                [Utilities setValueForKeyInUserDefaults:[responseDict objectForKey:@"LoginUserNameOrEmailKey"] key:@"LoginUserNameOrEmailKey"];
                [Utilities setValueForKeyInUserDefaults:[responseDict objectForKey:kAuthorizationKey] key:kAuthorizationKey];
                NSString *aVimondCookie = [responseDict objectForKey:@"Vimond-Cookie"];
                [Utilities setValueForKeyInUserDefaults:aVimondCookie key:@"Vimond-Cookie"];
                [weakSelf getUserProfile];
                [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterFinish_log_in];
                [SwrveUtility updateSwrveUserProperty:YES];

              }];
          }
          else
          {
              [self postSwrveLIErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kLIUserDoesNotExist];

              [self enableSignInLoginButton:YES];
              [self setLoginButtonBGColorForSelectedState];
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                NSString *aErrorMsg = [responseDict objectForKey:@"Errormessage"];
                weakSelf.mErrorMsgLabel.text = aErrorMsg;
                weakSelf.mErrorMsgLabel.hidden = NO;
                direction = 1;
                shakes = 0;
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
                [weakSelf shake:self.mUsernameTextField];
                [self.mUsernameTextField setTextColor:[UIColor redColor]];
                [self.mPasswordTextField setTextColor:[UIColor redColor]];

                direction = 1;
                shakes = 0;
                self.mErrorLinePassword.backgroundColor = [UIColor redColor];
                [weakSelf shake:self.mPasswordTextField];

              }];
          }

        }
        errorBlock:^(NSError *error) {

          [self postSwrveLIErrorEvent:kSwrveDiagnosticsErrors andErrorCode:kLIServerError];
          [self enableSignInLoginButton:YES];
          [self setLoginButtonBGColorForSelectedState];

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            //            NSString *aErrorMsg=error.localizedDescription;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.hidden=NO;
            if (weakSelf)
            {
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
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

- (void)postSwrveLIErrorEvent:(NSString *)eventName andErrorCode:(NSString *)errorcode
{
    NSDictionary *payload = [SwrveUtility getErrorEventPayloadForCode:errorcode];
    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveDiagnosticsCannotLogIn];
}

- (void)getUserProfile
{
    __weak LoginViewController *weakSelf = self;

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
          [self enableSignInLoginButton:YES];
          [self setLoginButtonBGColorForSelectedState];
          [weakSelf performSelectorOnMainThread:@selector(onGetProfileSuccessfull:) withObject:responseDict waitUntilDone:NO];

        }
        errorBlock:^(NSError *error) {
          [self enableSignInLoginButton:YES];
          [self setLoginButtonBGColorForSelectedState];
          //[weakSelf addNotificationForNetworkChanges];

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (weakSelf)
            {
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
            }
          }];

          NSLog(@"error in getting user profile");

        }
        withVimondCookie:NO];
}

- (void)onGetProfileSuccessfull:(NSDictionary *)aResponseDict
{
    [[DBHandler sharedInstance] createUserProfileEntityInDB:aResponseDict];

    NSLog(@"onGetProfileSuccessfull-login");
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

    if (self.isPresented)
    {
        if (self.presentedFromScreen == TabbarScreenByFollowAction)
        {
            //dismiss the controller
            [kSharedApplicationDelegate signUpCompletedFromTutorialOverLayScreen];
            [self dismissViewControllerAnimated:YES completion:nil];
            ((AppDelegate *)kSharedApplicationDelegate).isAppFromBGToFGFirstTimeToPlayListViewWillAppear = YES;
            // [kSharedApplicationDelegate showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchChannelSubscriptionWhenGuestLogin" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshUserInterfaceWhenGuestLogIn" object:nil];
        }
    }
    else
    {
        [kSharedApplicationDelegate setTabBarControllerAsRootViewControllerFromSignUp:NO];
    }

    //[self performSelector:@selector(postSignInAnalyticsEvent) withObject:nil afterDelay:0.7];
    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignIn andUserId:(NSString *)[aResponseDict objectForKey:@"userId"]];
}

//-(void)postSignInAnalyticsEvent{
//
//    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignIn andUserId:<#(NSString *)#>];
//
//}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.mCurrentTextFieldRef = textField;
    if (self.mUsernameTextField == textField)
    {
        if (self.mPasswordTextField.text.length >= 6)
        {
            NSString *aErrorMsg = nil;
            BOOL isValidPassword = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsg];
            if (isValidPassword)
            {
                self.mPasswordTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mPasswordErrorMsg.text = @"";
                self.mErrorLinePassword.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mPasswordErrorMsg.textColor = [UIColor clearColor];
            }
            else
            {
                self.mPasswordTextField.textColor = [UIColor blackColor];
                self.mPasswordErrorMsg.text = @"";
                self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
                self.mPasswordErrorMsg.textColor = [UIColor clearColor];
            }
        }
        else
        {
            self.mPasswordTextField.textColor = [UIColor blackColor];
            self.mPasswordErrorMsg.text = @"";
            self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
            self.mPasswordErrorMsg.textColor = [UIColor clearColor];
        }
    }
    else
    {
        if (self.mUsernameTextField.text.length >= 6)
        {
            if ([self.mUsernameTextField.text rangeOfString:@"@"].location != NSNotFound)
            {
                BOOL isValidEmail = [Validator isEmailValid:self.mUsernameTextField.text];

                if (isValidEmail)
                {
                    self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
                else
                {
                    self.mUsernameTextField.textColor = [UIColor blackColor];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
            }
            else
            {
                BOOL isVaildUserName = [Validator isUserNameValid:self.mUsernameTextField.text];

                if (isVaildUserName)
                {
                    self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
                else
                {
                    self.mUsernameTextField.textColor = [UIColor blackColor];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
            }
        }
        else
        {
            self.mUsernameTextField.textColor = [UIColor blackColor];
            self.mUsernameErrorMsg.text = @"";
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
            self.mUsernameErrorMsg.textColor = [UIColor clearColor];
        }
    }

    [self setForgetPasswordButtonBottomHeigthConstraintAsPerDeviceWhileErrorOccurs];
    self.mErrorMsgLabel.text = @"";
    // [self enableSignInLoginButton:YES];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.mUsernameTextField.text.length > 0 && self.mUsernameTextField.text.length < 6)
    {
        self.mUsernameTextField.textColor = [UIColor redColor];
        self.mUsernameErrorMsg.text = @"Requires minimum of 6 characters";
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        self.mUsernameErrorMsg.textColor = [UIColor lightGrayColor];
    }
    else if (self.mUsernameTextField.text.length >= 6)
    {
        if ([self.mUsernameTextField.text rangeOfString:@"@"].location != NSNotFound)
        {
            BOOL isValidEmail = [Validator isEmailValid:self.mUsernameTextField.text];

            if (isValidEmail)
            {
                self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mUsernameErrorMsg.text = @"";
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mUsernameErrorMsg.textColor = [UIColor clearColor];
            }
            else
            {
                self.mUsernameTextField.textColor = [UIColor redColor];
                self.mUsernameErrorMsg.text = @"Special characters limited to _ and -";
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
                self.mUsernameErrorMsg.textColor = [UIColor lightGrayColor];
            }
        }
        else
        {
            BOOL isVaildUserName = [Validator isUserNameValid:self.mUsernameTextField.text];

            if (isVaildUserName)
            {
                self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mUsernameErrorMsg.text = @"";
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mUsernameErrorMsg.textColor = [UIColor clearColor];
            }
            else
            {
                self.mUsernameTextField.textColor = [UIColor redColor];
                self.mUsernameErrorMsg.text = @"Special characters limited to _ and -";
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
                self.mUsernameErrorMsg.textColor = [UIColor lightGrayColor];
            }
        }
    }
    else
    {
        self.mUsernameTextField.textColor = [UIColor blackColor];
        self.mUsernameErrorMsg.text = @"";
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
        self.mUsernameErrorMsg.textColor = [UIColor clearColor];
    }

    if (self.mPasswordTextField.text.length > 0 && self.mPasswordTextField.text.length < 6)
    {
        self.mPasswordTextField.textColor = [UIColor redColor];
        self.mPasswordErrorMsg.text = @"Requires minimum of 6 characters";
        self.mPasswordErrorMsg.textColor = [UIColor lightGrayColor];
        self.mErrorLinePassword.backgroundColor = [UIColor redColor];
    }
    else if (self.mPasswordTextField.text.length >= 6)
    {
        NSString *aErrorMsg = nil;
        BOOL isValidPassword = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsg];
        if (isValidPassword)
        {
            self.mPasswordTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
            self.mPasswordErrorMsg.text = @"";
            self.mErrorLinePassword.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
            self.mPasswordErrorMsg.textColor = [UIColor clearColor];
        }
        else
        {
            self.mPasswordTextField.textColor = [UIColor redColor];
            self.mPasswordErrorMsg.text = aErrorMsg;
            self.mErrorLinePassword.backgroundColor = [UIColor redColor];
            self.mPasswordErrorMsg.textColor = [UIColor lightGrayColor];
        }
    }
    else
    {
        self.mPasswordTextField.textColor = [UIColor blackColor];
        self.mPasswordErrorMsg.text = @"";
        self.mPasswordErrorMsg.textColor = [UIColor clearColor];
        self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
    }

    [self setForgetPasswordButtonBottomHeigthConstraintAsPerDeviceWhileErrorOccurs];
    self.mErrorMsgLabel.text = @"";

    return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //    if(self.mUsernameTextField==textField)
    //    {
    //        self.mUsernameErrorMsg.text=@"";
    //        self.mErrorLineUserNameEmail.backgroundColor=[UIColor lightGrayColor];
    //    }
    //    else if (self.mPasswordTextField==textField)
    //    {
    //        self.mPasswordErrorMsg.text=@"";
    //        self.mErrorLinePassword.backgroundColor=[UIColor lightGrayColor];
    //    }

    if (self.mUsernameTextField == textField)
    {
        NSString *modifiedFieldText = [self.mUsernameTextField.text stringByReplacingCharactersInRange:range withString:string];
        self.mUsernameTextField.text = modifiedFieldText;
    }

    if (self.mPasswordTextField == textField)
    {
        NSString *modifiedFieldText = [self.mPasswordTextField.text stringByReplacingCharactersInRange:range withString:string];
        self.mPasswordTextField.text = modifiedFieldText;
    }

    NSString *trimmedUsernameStr = [self.mUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (trimmedUsernameStr.length >= 6 && self.mPasswordTextField.text.length >= 6)
    {
        [self enableSignInLoginButton:YES];
    }
    else
    {
        [self enableSignInLoginButton:NO];
    }
    //    if(([textField.text length] + [string length] - range.length) == 0)
    //    {
    //        [self.mUsernameTextField setTextColor:[UIColor blackColor]];
    //        [self.mPasswordTextField setTextColor:[UIColor blackColor]];
    //    }
    if (self.mUsernameTextField == textField)
    {
        if (self.mUsernameTextField.text.length >= 6)
        {
            if ([self.mUsernameTextField.text rangeOfString:@"@"].location != NSNotFound)
            {
                BOOL isValidEmail = [Validator isEmailValid:self.mUsernameTextField.text];

                if (isValidEmail)
                {
                    self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
                else
                {
                    self.mUsernameTextField.textColor = [UIColor blackColor];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
            }
            else
            {
                BOOL isVaildUserName = [Validator isUserNameValid:self.mUsernameTextField.text];

                if (isVaildUserName)
                {
                    self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
                else
                {
                    self.mUsernameTextField.textColor = [UIColor blackColor];
                    self.mUsernameErrorMsg.text = @"";
                    self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
                    self.mUsernameErrorMsg.textColor = [UIColor clearColor];
                }
            }
        }
        else
        {
            self.mUsernameTextField.textColor = [UIColor blackColor];
            self.mUsernameErrorMsg.text = @"";
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
            self.mUsernameErrorMsg.textColor = [UIColor clearColor];
        }
    }

    if (self.mPasswordTextField == textField)
    {
        if (self.mPasswordTextField.text.length >= 6)
        {
            NSString *aErrorMsg = nil;
            BOOL isValidPassword = [Validator isSignUpPasswordValid:self.mPasswordTextField.text withErrorMessage:&aErrorMsg];
            if (isValidPassword)
            {
                self.mPasswordTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mPasswordErrorMsg.text = @"";
                self.mErrorLinePassword.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mPasswordErrorMsg.textColor = [UIColor clearColor];
            }
            else
            {
                self.mPasswordTextField.textColor = [UIColor blackColor];
                self.mPasswordErrorMsg.text = @"";
                self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
                self.mPasswordErrorMsg.textColor = [UIColor clearColor];
            }
        }
        else
        {
            self.mPasswordTextField.textColor = [UIColor blackColor];
            self.mPasswordErrorMsg.text = @"";
            self.mErrorLinePassword.backgroundColor = [UIColor lightGrayColor];
            self.mPasswordErrorMsg.textColor = [UIColor clearColor];
        }
    }

    [self setForgetPasswordButtonBottomHeigthConstraintAsPerDeviceWhileErrorOccurs];
    self.mErrorMsgLabel.text = @"";

    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.mPasswordTextField)
    {
        [textField resignFirstResponder];
        [self onClickingLoginButton:nil];
    }

    if (textField == self.mUsernameTextField)
    {
        [self.mPasswordTextField becomeFirstResponder];
    }

    return YES;
}

- (void)setForgetPasswordButtonBottomHeigthConstraintAsPerDeviceWhileErrorOccurs
{
    if (self.view.frame.size.height <= 568.0)
    {
        // iphone 5 and lesser version

        float aForgotPasswordBottomHeightConstraint = 235.0;
        aForgotPasswordBottomHeightConstraint = self.view.frame.size.height <= 480 ? 147 : 235;

        if (self.mUsernameErrorMsg.text.length)
        {
            aForgotPasswordBottomHeightConstraint = aForgotPasswordBottomHeightConstraint - 40;
        }
        if (self.mPasswordErrorMsg.text.length)
        {
            aForgotPasswordBottomHeightConstraint = aForgotPasswordBottomHeightConstraint - 40;
        }

        if (self.mForgetPasswordButtonBottomHeightConstraint)
        {
            self.mForgetPasswordButtonBottomHeightConstraint.constant = aForgotPasswordBottomHeightConstraint;
        }
    }
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
- (void)shake:(UIView *)theOneYouWannaShake
{
    [UIView animateWithDuration:0.03
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

@end
