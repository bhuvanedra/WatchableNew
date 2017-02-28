//
//  ForgotPasswordViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ForgotPasswordViewController.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "Validator.h"
#import "ServerConnectionSingleton.h"
#import "AnalyticsEventsHandler.h"
#import "Utilities.h"
@interface ForgotPasswordViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView *mConfirmationSuccessView;
@end

@implementation ForgotPasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initalizeUISetup];
    /* Android design
    UIImage *athumbnail = [UIImage imageNamed:@"signUp1.png"];
    CGRect imageRect = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    UIGraphicsBeginImageContextWithOptions(athumbnail.size, NO, [UIScreen mainScreen].scale);
    [athumbnail drawInRect:imageRect];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    self.view.backgroundColor=[UIColor colorWithPatternImage:thumbnail];
    */
    // Do any additional setup after loading the view.
}
- (IBAction)onClickingLogInButton:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initalizeUISetup
{
    [self createNavBarWithHidden:NO];
    /* Android design
    [self clearNavBarColor];
     */
    [self setBackButtonOnNavBar];
    [self setNavigationBarTitle:@"FORGOT PASSWORD?" withFont:nil withTextColor:nil];
    //[self setLogInButtonOnNavBar];

    [Utilities addGradientToView:self.view withStartGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.0] withEndGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.2]];

    NSString *str = @"Cancel";
    UIFont *aFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:aFont, NSFontAttributeName, [UIColor colorWithRed:0.0 / 255.0 green:127.0 / 255.0 blue:255.0 / 255.0 alpha:1.0], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];

    // Add attribute NSUnderlineStyleAttributeName
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:fontAttributes];
    [self.mCancelButton setAttributedTitle:attributedString forState:UIControlStateNormal];

    self.mUsernameTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Username or Email"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.0]
                                        }];

    [self.mUsernameTextField setTintColor:[UIColor darkGrayColor]];

    //Android Design self.mSendPasswordResetLinkBtn.backgroundColor=[UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:1.0];

    if (self.mUsernameTextField.text.length <= 0)
    {
        //        self.mSendPasswordResetLinkBtn.backgroundColor=[UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:0.2];
        //Android Design   self.mSendPasswordResetLinkBtn.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:144.0/255.0 blue:226.0/255.0 alpha:0.2];

        self.mSendPasswordResetLinkBtn.enabled = NO;
    }

    self.mErrorMsgLabel.text = @"";
    self.mErrorMsgLabel.hidden = YES;

    self.mLoginButton.layer.borderWidth = 1.0;
    self.mLoginButton.layer.cornerRadius = 2.0;
    self.mLoginButton.layer.borderColor = [UIColor colorWithRed:241.0 / 255.0 green:241.0 / 255.0 blue:241.0 / 255.0 alpha:1.0].CGColor;

    self.mSendPasswordResetLinkBtn.layer.cornerRadius = 2.0;
    self.mSendPasswordResetLinkBtn.layer.masksToBounds = YES;

    self.mSuccessOverLayView.hidden = YES;
    self.mForgotPasswordBGView.hidden = NO;

    // [self.mUsernameTextField becomeFirstResponder];
    /* Android design
    [Utilities setAppBackgroundcolorForView:self.view];
    */
    //    if(self.view.frame.size.height <=480)
    //    {
    //        self.mCancelButtonBottomHeight.constant=147;
    //
    //    }
    //    else  if(self.view.frame.size.height <=568)
    //    {
    //        self.mCancelButtonBottomHeight.constant=250;
    //
    //    }
    //    else
    //    {
    //        self.mCancelButtonBottomHeight.constant=330;
    //    }
}

- (void)popController
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //    transition.type = kCATransitionFromRight;
    //    [transition setType:kCATransitionPush];
    //    transition.subtype = kCATransitionFromRight;
    //  transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)onClickingCancelButton:(id)sender
{
    [self popController];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *modifiedFieldText = [self.mUsernameTextField.text stringByReplacingCharactersInRange:range withString:string];
    self.mUsernameTextField.text = modifiedFieldText;
    /* if(([textField.text length] + [string length] - range.length) > 0)
    {

//        self.mSendPasswordResetLinkBtn.backgroundColor=[UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:1.0];
        self.mSendPasswordResetLinkBtn.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:144.0/255.0 blue:226.0/255.0 alpha:1.0];

        self.mSendPasswordResetLinkBtn.enabled=YES;
        self.mErrorMsgLabel.text=@"";
        self.mErrorMsgLabel.hidden=YES;
        self.mErrorLineUserNameEmail.backgroundColor=[UIColor lightGrayColor];
    }
    else
    {
//         self.mSendPasswordResetLinkBtn.backgroundColor=[UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:0.2];
        // Before Android Design implementation
         //  self.mSendPasswordResetLinkBtn.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:144.0/255.0 blue:226.0/255.0 alpha:0.2];
       // Android design color code
        self.mSendPasswordResetLinkBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];;
        [self.mUsernameTextField setTextColor:[UIColor blackColor]];

        self.mSendPasswordResetLinkBtn.enabled=NO;
    }
    
    */

    ///////////000////

    if (self.mUsernameTextField.text.length >= 6)
    {
        if ([self.mUsernameTextField.text rangeOfString:@"@"].location != NSNotFound)
        {
            BOOL isValidEmail = [Validator isEmailValid:self.mUsernameTextField.text];

            if (isValidEmail)
            {
                self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];

                self.mSendPasswordResetLinkBtn.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];

                self.mSendPasswordResetLinkBtn.enabled = YES;
            }
            else
            {
                self.mUsernameTextField.textColor = [UIColor blackColor];
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];

                self.mSendPasswordResetLinkBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];

                self.mSendPasswordResetLinkBtn.enabled = NO;
            }
        }
        else
        {
            BOOL isVaildUserName = [Validator isUserNameValid:self.mUsernameTextField.text];

            if (isVaildUserName)
            {
                self.mUsernameTextField.textColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];

                self.mSendPasswordResetLinkBtn.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];

                self.mSendPasswordResetLinkBtn.enabled = YES;
            }
            else
            {
                self.mUsernameTextField.textColor = [UIColor blackColor];
                self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];

                self.mSendPasswordResetLinkBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];

                self.mSendPasswordResetLinkBtn.enabled = NO;
            }
        }
    }
    else
    {
        self.mUsernameTextField.textColor = [UIColor blackColor];
        //self.mErrorMsgLabel.text=@"";
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor lightGrayColor];
        //self.mErrorMsgLabel.textColor = [UIColor clearColor];

        self.mSendPasswordResetLinkBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];

        self.mSendPasswordResetLinkBtn.enabled = NO;
    }
    self.mErrorMsgLabel.text = @"";
    //self.mErrorMsgLabel.textColor = [UIColor clearColor];
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    if (textField == self.mUsernameTextField)
    {
        [self onClickingSendPasswordButton:nil];
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onClickingSendPasswordButton:(UIButton *)sender
{
    __weak ForgotPasswordViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    self.mErrorMsgLabel.text = @"";
    [self.mUsernameTextField resignFirstResponder];

    int UsernameorEmailIdStatus = 0;
    // UsernameorEmailIdStatus ==1, for username
    // UsernameorEmailIdStatus ==2, for email

    BOOL isVaildUserNameOrEmail = [self isValidateUserNameOrEmail:&UsernameorEmailIdStatus];
    if (isVaildUserNameOrEmail)

    {
        if (UsernameorEmailIdStatus == 2)
        {
            NSDictionary *aRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:self.mUsernameTextField.text, @"email", nil];
            [[ServerConnectionSingleton sharedInstance] sendRequestToGetPasswordResetLinkForEmailId:aRequestDict
                withResponseBlock:^(NSDictionary *responseDict) {
                  [weakSelf performSelectorOnMainThread:@selector(onSuccessFullResetPasswordForEmailResponse:) withObject:responseDict waitUntilDone:NO];

                }
                errorBlock:^(NSError *error) {

                  [weakSelf performSelectorOnMainThread:@selector(onFailureResetPasswordResponse:) withObject:error waitUntilDone:NO];
                }];
        }
        else if (UsernameorEmailIdStatus == 1)
        {
            NSDictionary *aRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:self.mUsernameTextField.text, @"userName", nil];
            [[ServerConnectionSingleton sharedInstance] sendRequestToGetPasswordResetLinkForUsername:aRequestDict
                withResponseBlock:^(NSDictionary *responseDict) {
                  [weakSelf performSelectorOnMainThread:@selector(onSuccessFullResetPasswordForUsernameResponse:) withObject:responseDict waitUntilDone:NO];

                }
                errorBlock:^(NSError *error) {

                  [weakSelf performSelectorOnMainThread:@selector(onFailureResetPasswordResponse:) withObject:error waitUntilDone:NO];
                }];
        }
        else
        {
            self.mErrorMsgLabel.text = @"Please enter a valid Username or Email id";
            self.mErrorMsgLabel.hidden = NO;
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        }
    }
    else
    {
        self.mErrorMsgLabel.hidden = NO;
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        [self.mUsernameTextField setTextColor:[UIColor redColor]];
    }
}

- (BOOL)isValidateUserNameOrEmail:(int *)isUsernamePointer
{
    BOOL isValid = NO;
    NSString *trimmedUsernameStr = [self.mUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([trimmedUsernameStr rangeOfString:@"@"].location == NSNotFound)
    {
        //validate username
        isValid = [Validator isUserNameValid:self.mUsernameTextField.text];
        if (isValid)
        {
            *isUsernamePointer = 1;
            [self.mUsernameTextField setTextColor:[UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0]];
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
        }
        else
        {
            self.mErrorMsgLabel.text = @"Account not found";
            [self.mUsernameTextField setTextColor:[UIColor redColor]];
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        }
    }
    else
    {
        //validate emailid
        isValid = [Validator isEmailValid:self.mUsernameTextField.text];
        if (isValid)
        {
            *isUsernamePointer = 2;
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0];
            [self.mUsernameTextField setTextColor:[UIColor colorWithRed:133.0 / 255.0 green:200.0 / 255.0 blue:12.0 / 255.0 alpha:1.0]];
        }
        else
        {
            self.mErrorMsgLabel.text = @"Please Enter a valid email address";
            self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
            [self.mUsernameTextField setTextColor:[UIColor redColor]];
        }
    }
    return isValid;
}

- (void)onSuccessFullResetPasswordForUsernameResponse:(NSDictionary *)aResponseDict
{ //[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]
    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameUpdatePassword andUserId:[Utilities getCurrentUserId]];
    NSString *aEmailStr = [aResponseDict objectForKey:@"email"];
    UIFont *font2 = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
    NSDictionary *attr = @{NSFontAttributeName : font2, NSForegroundColorAttributeName : [UIColor blackColor]};

    NSString *aStr = [NSString stringWithFormat:@"We've sent instructions on how to change your password to %@", aEmailStr];
    NSMutableAttributedString *aAttributedString = [[NSMutableAttributedString alloc] initWithString:aStr attributes:attr];
    //[self.mUsernameTextField setTextColor:[UIColor blackColor]];

    self.mEmailSentLabel.attributedText = aAttributedString;
    // self.mForgotPasswordBGView.hidden=YES;
    //self.mForgotPasswordBGView.hidden=YES;
    // self.mSuccessOverLayView.hidden=NO;
    [self createSuccessFullyEmailedViewWithMailId:aAttributedString];
}
- (void)onSuccessFullResetPasswordForEmailResponse:(NSDictionary *)aResponseDict
{
    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameUpdatePassword andUserId:[Utilities getCurrentUserId]];
    NSString *aEmailStr = [aResponseDict objectForKey:@"email"];
    NSString *aFirstCharStr = nil;
    NSMutableString *aDotStr = nil;
    NSString *aLastCharStr = nil;
    NSString *aEmailDomain = nil;
    NSRange range = [aEmailStr rangeOfString:@"@"];
    if (range.location != NSNotFound)
    {
        aEmailDomain = [aEmailStr substringFromIndex:range.location];
        NSString *aEmail = [aEmailStr substringToIndex:range.location];
        NSRange aRange = NSMakeRange(1, aEmail.length - 2);
        aFirstCharStr = [aEmail substringToIndex:1];
        if (aEmail.length > 1)
        {
            aLastCharStr = [aEmail substringFromIndex:aEmail.length - 1];
            aDotStr = [[NSMutableString alloc] init];
            for (int x = 0; x < aRange.length; x++)
            {
                [aDotStr appendString:@"*"];
            }
        }
    }

    NSAttributedString *aDotString = nil;

    if (aDotStr)
    {
        // self.mEmailSentLabel.text=@"We've emailed you at pt@gmail.com";
        UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0]; //[UIFont fontWithName:@"AvenirNext-DemiBold" size:12.0];
        NSDictionary *Dotattr = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor blackColor]};

        aDotString = [[NSAttributedString alloc] initWithString:aDotStr attributes:Dotattr];
    }

    UIFont *font2 = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
    NSDictionary *attr = @{NSFontAttributeName : font2, NSForegroundColorAttributeName : [UIColor blackColor]};

    NSString *aStr = [NSString stringWithFormat:@"We've sent instructions on how to change your password to %@", aFirstCharStr];
    NSMutableAttributedString *aAttributedString = [[NSMutableAttributedString alloc] initWithString:aStr attributes:attr];

    if (aDotString)
        [aAttributedString appendAttributedString:aDotString];

    NSString *aCompleteDomainNameWithLastEmailStr = [NSString stringWithFormat:@"%@%@", aLastCharStr.length ? aLastCharStr : @"", aEmailDomain];
    NSAttributedString *aAttributedString2 = [[NSAttributedString alloc] initWithString:aCompleteDomainNameWithLastEmailStr attributes:attr];
    [aAttributedString appendAttributedString:aAttributedString2];
    self.mEmailSentLabel.attributedText = aAttributedString;
    //self.mForgotPasswordBGView.hidden=YES;
    //self.mForgotPasswordBGView.hidden=YES;
    //self.mSuccessOverLayView.hidden=NO;        //if success
    [self createSuccessFullyEmailedViewWithMailId:aAttributedString];
}

- (void)onFailureResetPasswordResponse:(NSError *)error
{
    __weak ForgotPasswordViewController *weakSelf = self;
    // response error
    if (error.code == kUserNameEmailUnavailableErrorCode)
    {
        self.mErrorMsgLabel.text = error.localizedDescription;
        self.mErrorMsgLabel.hidden = NO;
        self.mErrorLineUserNameEmail.backgroundColor = [UIColor redColor];
        [self.mUsernameTextField setTextColor:[UIColor redColor]];
    }
    else if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    /*else
    {
        self.mErrorMsgLabel.text=aError.localizedDescription;
        self.mErrorMsgLabel.hidden=NO;
    }*/
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIViewController cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc
{
}

//-(NSDictionary*)getTheBody{
//
//    NSDictionary * body = nil;
//
//    if([Validator isEmailValid:self.mUsernameTextField.text])
//    {
//
//    }
//    return body;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)createSuccessFullyEmailedViewWithMailId:(NSAttributedString *)aDescriptionStr
{
    CGRect aFrame = self.view.bounds;

    UIView *aBGView = [[UIView alloc] initWithFrame:aFrame];

    aBGView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.6];

    [self.view addSubview:aBGView];
    self.mConfirmationSuccessView = aBGView;

    float aViewheight = 30 * (aFrame.size.height / 100);
    if (aViewheight < 150)
    {
        aViewheight = 150.0;
    }
    CGRect aViewFrame = self.view.bounds;

    aViewFrame.size.width = aViewFrame.size.width - (2 * 20);
    aViewFrame.size.height = aViewheight;

    UIView *aView = [[UIView alloc] initWithFrame:aViewFrame];
    aView.backgroundColor = [UIColor whiteColor];
    [aBGView addSubview:aView];
    aView.center = aBGView.center;

    NSString *aViewTitleStr = @"Check your email!";

    NSString *aButtonTitleStr = @"Ok, I'll check!";

    aViewFrame.size.height = 40;
    aViewFrame.origin.x = 20;
    aViewFrame.origin.y = 5;
    aViewFrame.size.width = aViewFrame.size.width - (2 * 20);

    UILabel *aTitleLabel = [[UILabel alloc] initWithFrame:aViewFrame];
    aTitleLabel.backgroundColor = [UIColor clearColor];
    aTitleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    aTitleLabel.textColor = [UIColor colorWithRed:74.0 / 255.0 green:74.0 / 255.0 blue:74.0 / 255.0 alpha:1.0];
    aTitleLabel.text = aViewTitleStr;
    [aView addSubview:aTitleLabel];

    UILabel *aDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, aTitleLabel.frame.origin.y + aTitleLabel.frame.size.height + 5, aTitleLabel.frame.size.width, 60)];
    aDescLabel.backgroundColor = [UIColor clearColor];
    aDescLabel.numberOfLines = 3;
    aDescLabel.textColor = [UIColor colorWithRed:74.0 / 255.0 green:74.0 / 255.0 blue:74.0 / 255.0 alpha:1.0];
    aDescLabel.attributedText = aDescriptionStr;
    [aView addSubview:aDescLabel];

    UIButton *aOKButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aOKButton setBackgroundColor:[UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:0.9]];
    aOKButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];

    float buttonheight = 40;

    aOKButton.frame = CGRectMake(0, aView.frame.size.height - buttonheight, aView.frame.size.width, buttonheight);
    [aOKButton addTarget:self action:@selector(onClickingOKButton) forControlEvents:UIControlEventTouchUpInside];
    [aOKButton setTitle:aButtonTitleStr forState:UIControlStateNormal];
    [aView addSubview:aOKButton];
}

- (void)onClickingOKButton
{
    if (self.mConfirmationSuccessView)
    {
        [self.mConfirmationSuccessView removeFromSuperview];
        self.mConfirmationSuccessView = nil;
    }
}

@end
