//
//  EditProfileViewController.m
//  Watchable
//
//  Created by Abhilash on 5/18/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "EditProfileViewController.h"

#import "DBHandler.h"
#import "EditProfileTableViewCell.h"
#import "GAUtilities.h"
#import "ServerConnectionSingleton.h"
#import "UIColor+HexColor.h"
#import "UserProfile.h"
#import "Validator.h"
#import "Watchable-Swift.h"

@interface EditProfileViewController () <UITextFieldDelegate>
{
    NSArray *headers;
    //    NSString *mailT;
    //    NSString *userName;
}
@property (nonatomic, readwrite) BOOL isUserNameError;
@property (nonatomic, readwrite) BOOL isEmailError;
@property (weak, nonatomic) IBOutlet UILabel *userNameHeader;
@property (weak, nonatomic) IBOutlet UILabel *emailHeader;
@property (weak, nonatomic) IBOutlet UITextField *userNameFiled;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIView *HeaderView;
@property (weak, nonatomic) IBOutlet UIView *headerviewM;
@property (weak, nonatomic) IBOutlet UILabel *userNameErrorLabel;
@property (weak, nonatomic) IBOutlet UIView *diffView;
@property (weak, nonatomic) IBOutlet UILabel *emailErrorLabel;
@property (nonatomic, weak) UITextField *mCurrentTextFieldRef;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *emailId;
@property (nonatomic, strong) NSString *mLoggedInUserName;
@property (nonatomic, strong) NSString *mLoggedInUserEmail;
@property (nonatomic, assign) BOOL isSaveClicked;
@property (nonatomic, assign) BOOL isTickMarkVisible;
@end

@implementation EditProfileViewController

#pragma mark View Lifecycle Methods

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor blackColor];
    [super viewDidLoad];
    if (self.isFromConfirmEmail)
    {
        self.resendConfirmationBGView.hidden = NO;
        self.resendConfirmationEmailButton.layer.borderColor = [UIColor colorWithRed:241.0 / 255.0 green:241.0 / 255.0 blue:241.0 / 255.0 alpha:1.0].CGColor;
        self.resendConfirmationEmailButton.layer.borderWidth = 1.0;
        self.userNameFiled.returnKeyType = UIReturnKeyDefault;
    }
    else
    {
        self.resendConfirmationBGView.hidden = YES;
        self.userNameFiled.returnKeyType = UIReturnKeyDone;
    }
    [self createNavBarWithHidden:NO];
    [self setBackButtonOnNavBar];
    [self setEditProfileButtonsOnNavBar];
    self.userNameFiled.delegate = self;
    //self.emailField.delegate = self;
    if (self.isEditUserName)
    {
        [self setNavigationBarTitle:@"USERNAME" withFont:nil withTextColor:nil];
    }

    else
    {
        [self setNavigationBarTitle:@"EMAIL" withFont:nil withTextColor:nil];
    }
    headers = @[ @"USERNAME", @"EMAIL" ];
    self.aSaveButton.enabled = NO;
    self.isUserNameError = NO;
    self.isEmailError = NO;
    self.view.backgroundColor = [UIColor colorFromHexString:@"#1B1D1E"];

    self.userNameErrorLabel.backgroundColor = [UIColor clearColor];
    self.emailErrorLabel.backgroundColor = [UIColor clearColor];
    _userNameHeader.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:16];
    _userNameHeader.textColor = [UIColor colorFromHexString:@"#6A6E71"];

    _emailHeader.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:16];
    _emailHeader.textColor = [UIColor colorFromHexString:@"#6A6E71"];

    _HeaderView.backgroundColor = [UIColor colorFromHexString:@"#000000"];
    _headerviewM.backgroundColor = [UIColor colorFromHexString:@"#000000"];
    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
    [self setTickMarkWithVisibleMode:NO];
    [self.userNameFiled addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    //[self.emailField setRightViewMode:UITextFieldViewModeAlways];

    /*  UIImage *aCheckImage=[UIImage imageNamed:@"Check.png"];
    UIImageView *aEmailTickImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 15, 16, 16)];
    aEmailTickImageView.image=aCheckImage;
   // [self.emailField setRightView:aEmailTickImageView];
    
    UIImageView *aUserNameTickImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 15, 16, 16)];
    aUserNameTickImageView.image=aCheckImage;
    [self.userNameFiled setRightView:aUserNameTickImageView];*/

    UserProfile *aUserProfile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];
    self.mLoggedInUserName = aUserProfile.mUserName;
    self.mLoggedInUserEmail = aUserProfile.mUserEmail;

    if (self.isEditUserName)
    {
        self.userNameFiled.text = self.mLoggedInUserName;
    }
    else
    {
        self.userNameFiled.text = self.mLoggedInUserEmail;
    }

    self.emailField.hidden = true;
    self.emailErrorLabel.hidden = true;

    //self.emailField.text=self.mLoggedInUserEmail;

    [self enableEditProfileSaveButton:NO];
}

- (IBAction)textChanged:(id)sender
{
    if (self.isEditUserName)
    {
        BOOL sameUsername = [self.userNameFiled.text isEqualToString:self.mLoggedInUserName];
        [self enableEditProfileSaveButton:!sameUsername];
    }
}

- (void)setTickMarkWithVisibleMode:(BOOL)isTickMarkVisible
{
    UIView *aView = nil;
    if (self.isFromConfirmEmail)
    {
        aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 65, 46)];
        UIImage *aAttentionImage = [UIImage imageNamed:@"error.png"];
        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 3, 40, 40)];
        aImageView.image = aAttentionImage;
        [aView addSubview:aImageView];
    }
    if (!aView)
    {
        aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 46)];
    }

    UIImage *aCheckImage = [UIImage imageNamed:@"Check.png"];
    UIImageView *aTickImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 15, 16, 16)];
    aTickImageView.image = aCheckImage;
    aTickImageView.hidden = !isTickMarkVisible;
    self.isTickMarkVisible = isTickMarkVisible;
    [aView addSubview:aTickImageView];
    [self.userNameFiled setRightView:aView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"EditProfileScreen"];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor colorFromHexString:@"#1B1D1E"];
    self.navigationController.navigationBar.translucent = NO;
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.mCurrentTextFieldRef = textField;
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.userNameFiled == textField)
    {
        [self setUsernameErrorMessage:@""];
        [textField setRightViewMode:UITextFieldViewModeAlways];
        [self setTickMarkWithVisibleMode:NO];
    }

    else if (self.emailField == textField)
    {
        [self setEmailIdErrorMessage:@""];
        [textField setRightViewMode:UITextFieldViewModeAlways];
        [self setTickMarkWithVisibleMode:NO];
    }

    [self enableEditProfileSaveButton:YES];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == self.userNameFiled && self.isEditUserName)
    {
        BOOL isValidUserName = [self validateUserName];
        if (isValidUserName)
        {
            //validate against server
            if (![self.userNameFiled.text isEqualToString:self.mLoggedInUserName])
            {
                NSLog(@"self.userNameFiled.text=%@", self.userNameFiled.text);
                NSLog(@"self.mLoggedInUserName=%@", self.mLoggedInUserName);
                NSLog(@"validateUserNameFromServer1");
                [self validateUserNameFromServer];
            }
        }
        else
        {
            NSString *theUserName = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            if (theUserName.length == 0)
            {
                [self setUsernameErrorMessage:@"Minimum 6 characters. Special characters _ and - are allowed"];
            }
        }
    }
    else if (textField == self.userNameFiled && !self.isEditUserName)
    {
        BOOL isValidEmailId = [self validateEmailId];
        if (isValidEmailId)
        {
            //validate against server
            if (![self.userNameFiled.text isEqualToString:self.mLoggedInUserEmail])
                [self validateEmailIdFromServer];
        }
        else
        {
            NSString *theEmail = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (theEmail.length == 0)
            {
                [self setEmailIdErrorMessage:@"Please Enter a valid email address"];
            }
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (!self.isFromConfirmEmail)
        [self onClickingSaveButton];
    return YES;
}

- (BOOL)validateUserName
{
    BOOL isValidUserName = NO;
    if (self.userNameFiled.text.length)
    {
        isValidUserName = [Validator isUserNameValid:self.userNameFiled.text];
        if (!isValidUserName)
        {
            [self setUsernameErrorMessage:@"Minimum 6 characters. Special characters _ and - are allowed"];
        }
        else
        {
            [self setUsernameErrorMessage:@""];
        }
    }
    else
    {
        [self setUsernameErrorMessage:@""];
    }
    return isValidUserName;
}

- (BOOL)validateEmailId
{
    BOOL isValidEmail = NO;
    if (self.userNameFiled.text.length)
    {
        isValidEmail = [Validator isEmailValid:self.userNameFiled.text];
        if (!isValidEmail)
        {
            [self setEmailIdErrorMessage:@"Please Enter a valid email address"];
        }
        else
        {
            [self setEmailIdErrorMessage:@""];
        }
    }
    else
    {
        [self setEmailIdErrorMessage:@""];
    }
    return isValidEmail;
}

- (void)setUsernameErrorMessage:(NSString *)aErrorMsg
{
    self.userNameErrorLabel.text = aErrorMsg;
}

- (void)setEmailIdErrorMessage:(NSString *)aErrorMsg
{
    self.userNameErrorLabel.text = aErrorMsg;
}

- (IBAction)onClickingResendConfirmationEmailButton
{
    __weak EditProfileViewController *weakSelf = self;
    if ([self.mLoggedInUserEmail isEqualToString:self.userNameFiled.text])
    {
        NSString *theUserEmail = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSDictionary *aRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:theUserEmail, @"email", nil];
        [[ServerConnectionSingleton sharedInstance] sendRequestToSendConfirmEmail:aRequestDict
            withResponseBlock:^(NSDictionary *responseDict) {
              [weakSelf performSelectorOnMainThread:@selector(onSuccessFullResendConfirmationEmail) withObject:nil waitUntilDone:NO];

            }
            errorBlock:^(NSError *error) {

              [weakSelf performSelectorOnMainThread:@selector(onFailureResendConfirmationEmail:) withObject:error waitUntilDone:NO];
            }];
    }
    else
    {
        NSString *message = NSLocalizedString(@"Please save your email id before sending confirmation.", @"One of the 'generic Watchable' alert's messages");
        UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onSuccessFullResendConfirmationEmail
{
    NSString *message = NSLocalizedString(@"Your confirmation email has been re-sent.", @"One of the 'generic Watchable' alert's messages");
    UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onFailureResendConfirmationEmail:(NSError *)error
{
    __weak EditProfileViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
}
- (void)onClickingSaveButton
{
    __weak EditProfileViewController *weakSelf = self;
    if (self.mErrorView)
    {
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
    }
    [self.mCurrentTextFieldRef resignFirstResponder];
    self.mCurrentTextFieldRef = nil;

    //if([self validateUserName] && [self validateEmailId])

    if (self.isEditUserName)
    {
        if ([self.userNameFiled.text isEqualToString:self.mLoggedInUserName])
        {
            NSString *message = NSLocalizedString(@"Please Edit Username to save profile.", @"One of the 'generic Watchable' alert's messages");
            UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
            [self presentViewController:alert animated:YES completion:nil];

            return;
        }
    }
    else if (!self.isEditUserName)
    {
        if ([self.userNameFiled.text isEqualToString:self.mLoggedInUserEmail])
        {
            NSString *message = NSLocalizedString(@"Please Edit Email Id to save profile.", @"One of the 'generic Watchable' alert's messages");
            UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
            [self presentViewController:alert animated:YES completion:nil];

            return;
        }
    }

    if (self.isEditUserName)
    {
        if ([self validateUserName])
        {
            self.isSaveClicked = YES;

            if (!self.isTickMarkVisible && (![self.userNameFiled.text isEqualToString:self.mLoggedInUserName]))
            {
                [self disableUIElementsForWhileConnectingServer];
                [self validateUserNameFromServer];
                return;
            }
        }
        else
        {
            NSString *theUserName = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            if (theUserName.length == 0)
            {
                [self setUsernameErrorMessage:@"Minimum 6 characters. Special characters _ and - are allowed"];
            }
            return;
        }
    }
    else
    {
        if ([self validateEmailId])
        {
            self.isSaveClicked = YES;
            if (!self.isTickMarkVisible && (![self.emailField.text isEqualToString:self.mLoggedInUserEmail]))
            {
                [self disableUIElementsForWhileConnectingServer];
                [self validateEmailIdFromServer];
                return;
            }
        }
        else
        {
            NSString *theEmail = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            if (theEmail.length == 0)
            {
                [self setEmailIdErrorMessage:@"Please Enter a valid email address"];
            }
            return;
        }
    }
    self.isSaveClicked = NO;

    if (self.isEditUserName)
    {
        if ((self.isTickMarkVisible || [self.userNameFiled.text isEqualToString:self.mLoggedInUserName]))
        {
            if ([self.userNameFiled.text isEqualToString:self.mLoggedInUserName])
            {
                NSString *message = NSLocalizedString(@"Please Edit Username to save profile.", @"One of the 'generic Watchable' alert's messages");
                UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                [self updateProfile];
            }
        }
    }
    else if (!self.isEditUserName)
    {
        if (self.isTickMarkVisible || [self.userNameFiled.text isEqualToString:self.mLoggedInUserEmail])
        {
            if ([self.userNameFiled.text isEqualToString:self.mLoggedInUserEmail])
            {
                NSString *message = NSLocalizedString(@"Please Edit Email Id to save profile.", @"One of the 'generic Watchable' alert's messages");
                UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                [self updateProfile];
            }
        }
    }
}

- (void)validateUserNameFromServer
{
    __weak EditProfileViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToValidateSignUpUserName:self.userNameFiled.text
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

          [weakSelf performSelectorOnMainThread:@selector(onUsernameValidationFailur:) withObject:error waitUntilDone:NO];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)validateEmailIdFromServer
{
    __weak EditProfileViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToValidateSignUpEmailId:self.userNameFiled.text
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

          [weakSelf performSelectorOnMainThread:@selector(onEmailValidationFailur:) withObject:error waitUntilDone:NO];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)onUsernameValidationFailur:(NSError *)aError
{
    [self enableUIElements];
    self.isUserNameError = YES;
    [self setUsernameErrorMessage:aError.localizedDescription];
    //self.userNameErrorLabel.text=aError.localizedDescription;
    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
    [self setTickMarkWithVisibleMode:NO];
}

- (void)onUsernameValidationSuccess
{
    self.isUserNameError = NO;
    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
    [self setTickMarkWithVisibleMode:YES];
    if (self.isSaveClicked)
    {
        [self onClickingSaveButton];
    }
}

- (void)onEmailValidationFailur:(NSError *)aError
{
    self.isUserNameError = YES;
    [self enableUIElements];
    [self setUsernameErrorMessage:aError.localizedDescription];
    //self.userNameErrorLabel.text=aError.localizedDescription;
    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];

    [self setTickMarkWithVisibleMode:NO];
}

- (void)onEmailValidationSuccess
{
    self.isUserNameError = NO;
    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
    [self setTickMarkWithVisibleMode:YES];
    if (self.isSaveClicked)
    {
        [self onClickingSaveButton];
    }
}

//
//#pragma mark TextFields delegate Methods
//
//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
//{
//    self.mCurrentTextFieldRef=textField;
//    return YES;
//}
//
//
//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
//{
//    if(textField==self.userNameFiled)
//    {
//        BOOL isValidUserName= [self validateUserName];
//        if(isValidUserName)
//        {
//            //validate against server
//            [self validateUserNameFromServer];
//        }
//    }
//    else if(textField==self.emailField)
//    {
//        BOOL isValidEmailId= [self validateEmailId];
//        if(isValidEmailId)
//        {
//            //validate against server
//            [self validateEmailIdFromServer];
//        }
//    }
//    [self validateAndEnableEditProfileSaveButton];
//    return YES;
//}
//
//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    if(textField==self.userNameFiled)
//    {
//        [self.emailField becomeFirstResponder];
//    }
//
//    if(textField==self.emailField)
//    {
//        [textField resignFirstResponder];
//        [self onClickingSaveButton];
//    }
//    return YES;
//
//}
//
//
//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
//{
//    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:text];
//    BOOL isPressedBackspaceAfterSingleSpaceSymbol = [text isEqualToString:@""] && resultString.length >0  && text.length==0 && range.length == 1;
//
//    if (isPressedBackspaceAfterSingleSpaceSymbol) {
//        if (textField.tag == 0)
//            self.userNameErrorLabel.hidden = YES;
//        else
//            self.emailErrorLabel.hidden = YES;
//        //        if (textField.tag == 0) {
//        //            userName =resultString;
//        //            [self CheckUsernameisAvailable];
//        //        }else{
//        //            mailT = resultString;
//        //        [self checkEmailIsAvailable];
//        //        }
//    }
//    [self validateAndEnableEditProfileSaveButton];
//    return YES;
//}
//
//
//#pragma mark Error Label Methods
//
//
//-(void)showUsernameErrorMessage:(NSString*)aErrorMsg
//{
//    if (self.isUserNameError) {
//        self.userNameErrorLabel.hidden = NO;
//        _userNameErrorLabel.text = aErrorMsg;
//        [self.headerviewM setFrame:CGRectMake(self.headerviewM.frame.origin.x,self.userNameErrorLabel.frame.origin.y+25 , self.headerviewM.frame.size.width, self.headerviewM.frame.size.height)];//self.userNameErrorLabel.frame.origin.y+21
//        [self.emailField setFrame:CGRectMake(self.emailField.frame.origin.x, self.headerviewM.frame.origin.y+self.headerviewM.frame.size.height, self.emailField.frame.size.width, self.emailField.frame.size.height)];
//        [self.view bringSubviewToFront:self.userNameErrorLabel];
//
//    }else{
//
//        self.userNameErrorLabel.hidden = YES;
//    }
//}
//
//-(void)showEmailIdErrorMessage:(NSString*)aErrorMsg
//{
//    if (self.isEmailError) {
//        self.emailErrorLabel.hidden = NO;
//        _emailErrorLabel.text = aErrorMsg;
//        [self.view bringSubviewToFront:self.emailErrorLabel];
//        [self.diffView setFrame:CGRectMake(self.diffView.frame.origin.x, self.diffView.frame.origin.y, self.diffView.frame.size.width, self.diffView.frame.size.height)];
//    }else{
//
//        self.emailErrorLabel.hidden = YES;
//    }
//
//}
//
//#pragma mark Navigationbar buttion Action Methods
//
//-(void)onClickingCancelButton
//{
//    [self.navigationController popViewControllerAnimated:YES];
//}
//-(void)onClickingSaveButton
//{
//    __weak EditProfileViewController *weakSelf = self;
//    if(self.mErrorView){
//        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
//    }
//    [self.mCurrentTextFieldRef resignFirstResponder];
//
//    if (self.userNameFiled.rightViewMode == UITextFieldViewModeAlways || self.emailField.rightViewMode == UITextFieldViewModeAlways){
//
//        [self updateProfile];
//    }
//}
//
- (void)updateProfile
{
    //if error update error label with error msg

    self.emailField.enabled = NO;
    NSDictionary *body = [self getBody];

    // NSDictionary *body =@{@"userProfile":profileDict};
    __weak EditProfileViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToUpdateUserProfile:body
        withResponseBlock:^(NSDictionary *responseDict) {
          self.emailField.enabled = YES;
          NSNumber *aStatus = [responseDict objectForKey:@"Success"];
          NSNumber *aShouldConfirmEmailSend = [responseDict objectForKey:@"shouldConfirmEmailSend"];

          if (aShouldConfirmEmailSend.boolValue)
          {
              [weakSelf triggerResentConfirmEmailService];
          }

          if (aStatus.boolValue)
          {
              [weakSelf performSelectorOnMainThread:@selector(onUpdateProfileSuccess) withObject:nil waitUntilDone:NO];
              [weakSelf.mDelegate profileUpdated];
          }
          else
          {
          }

        }
        errorBlock:^(NSError *error) {
          self.emailField.enabled = YES;
          [self enableUIElements];
          if (weakSelf)
          {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (error.code == kUserNameEmailUnavailableErrorCode)
                {
                    [weakSelf performSelectorOnMainThread:@selector(onUpdateProfileFailure:) withObject:error waitUntilDone:NO];
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

- (void)triggerResentConfirmEmailService
{
    //__weak EditProfileViewController *weakSelf = self;
    NSString *theUserEmail = [self.userNameFiled.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSDictionary *aRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:theUserEmail, @"email", nil];
    [[ServerConnectionSingleton sharedInstance] sendRequestToSendConfirmEmail:aRequestDict
                                                            withResponseBlock:^(NSDictionary *responseDict) {
                                                              //   [weakSelf performSelectorOnMainThread:@selector(onSuccessFullResendConfirmationEmail) withObject:nil waitUntilDone:NO];

                                                            }
                                                                   errorBlock:^(NSError *error){

                                                                       // [weakSelf performSelectorOnMainThread:@selector(onFailureResendConfirmationEmail:) withObject:error waitUntilDone:NO];
                                                                   }];
}

- (void)disableUIElementsForWhileConnectingServer
{
    self.emailField.enabled = NO;
    [self enableEditProfileSaveButton:NO];
    self.resendConfirmationEmailButton.enabled = NO;
}

- (void)enableUIElements
{
    self.emailField.enabled = YES;
    [self enableEditProfileSaveButton:YES];
    self.resendConfirmationEmailButton.enabled = YES;
}
- (void)onUpdateProfileSuccess
{
    [[DBHandler sharedInstance] updateLoginUserProfileWithUsername:self.userName andWithEmailId:self.emailId];

    NSString *message = NSLocalizedString(@"Your profile has been updated", @"One of the 'generic Watchable' alert's messages");
    UIAlertController *alert = [AlertFactory genericWatchableWithTitle:nil andMessage:message];
    [self presentViewController:alert animated:YES completion:nil];

    self.userNameErrorLabel.text = @"";

    NSString *aUsernameOrEmailStr = [Utilities getValueFromUserDefaultsForKey:@"LoginUserNameOrEmailKey"];
    NSString *aUsernameOrEmailKey = @"username";
    NSRange range = [aUsernameOrEmailStr rangeOfString:@"@"];
    if (range.location != NSNotFound)
    {
        aUsernameOrEmailKey = @"email";
    }

    if (self.isEditUserName)
    {
        if (self.userName.length)
        {
            self.mLoggedInUserName = self.userName;
            if ([aUsernameOrEmailKey isEqualToString:@"username"])
            {
                [Utilities setValueForKeyInUserDefaults:self.mLoggedInUserName key:@"LoginUserNameOrEmailKey"];
            }
        }
    }
    else
    {
        if (self.emailId.length)
        {
            self.mLoggedInUserEmail = self.emailId;
            if ([aUsernameOrEmailKey isEqualToString:@"email"])
            {
                [Utilities setValueForKeyInUserDefaults:self.mLoggedInUserEmail key:@"LoginUserNameOrEmailKey"];
            };

            AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
            aSharedDelegate.isEmailConfirmedForUser = NO;
            aSharedDelegate.isEmailConfirmedStatusReceived = YES;
            [Utilities setValueForKeyInUserDefaults:[NSNumber numberWithBool:NO] key:@"emailStatus"];
            //isAppFromBGToFGFirstTimeToPlayListViewWillAppear = yes, so that the email toast will be visible in playlist
            aSharedDelegate.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = YES;
            //[((AppDelegate*)kSharedApplicationDelegate) getLoggedInUserEmailConfirmStatus];
        }
    }

    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
    [self setTickMarkWithVisibleMode:NO];
    [self enableEditProfileSaveButton:NO];
    self.emailField.enabled = YES;
    self.resendConfirmationEmailButton.enabled = YES;

    // [self resetTextFields];
}

- (void)resetTextFields
{
    _userNameFiled.text = nil;
    _emailField.text = nil;
    [self enableEditProfileSaveButton:NO];
}

- (void)onUpdateProfileFailure:(NSError *)aError
{
    UIAlertController *alert = [AlertFactory genericWatchableWithTitle:nil andMessage:aError.localizedDescription];
    [self presentViewController:alert animated:YES completion:nil];

    //[self resetTextFields];
    //    [self performSelector:@selector(removeErrorToastView) withObject:nil afterDelay:10];
    //    self.mErrorToastViewLabel.text=aError.localizedDescription;
    //
    //    self.mErrorViewTopConstraint.constant=64;
    //    self.mErrorToastView.hidden=NO;
    //
    //    //    [UIView animateWithDuration:.5
    //    //                     animations:^{
    //    //
    //    //                         self.mErrorViewTopConstraint.constant=64;
    //    //                         self.mErrorToastView.hidden=NO;
    //    //
    //    //                     }
    //    //                     completion:^(BOOL finished){
    //    //
    //    //
    //    //                     }];
}

- (NSDictionary *)getBody
{
    NSDictionary *body = [NSDictionary new];

    if (!self.isEditUserName)
    {
        body = @{ @"email" : self.userNameFiled.text,
                  @"emailStatus" : [NSNumber numberWithInt:0] /*,@"notifyUserOnCreation":@"EMAIL",@"confirmEmail":[NSNumber numberWithInt:1]*/ };
    }
    else
    {
        body = @{ @"userName" : self.userNameFiled.text };
    }

    if (self.isEditUserName)
    {
        _userName = self.userNameFiled.text;
        _emailId = @"";
    }
    else
    {
        _emailId = self.userNameFiled.text;
        _userName = @"";
    }

    return body;
}

//#pragma mark Validation Methods
//
//-(void)validateAndEnableEditProfileSaveButton
//{
//
//    if(self.userNameFiled.rightViewMode == UITextFieldViewModeAlways  || self.emailField.rightViewMode == UITextFieldViewModeAlways)
//    {
//        [self enableEditProfileSaveButton:YES];
//    }
//    else
//    {
//        [self enableEditProfileSaveButton:NO];
//    }
//}
//
//
//-(void)validateEmailIdFromServer
//{
//    __weak EditProfileViewController *weakSelf = self;
//    [[ServerConnectionSingleton sharedInstance]sendRequestToValidateSignUpEmailId:self.emailField.text withResponseBlock:^(NSDictionary* responseDict) {
//        NSNumber *aStatus=[responseDict objectForKey:@"Success"];
//
//        if(aStatus.boolValue)
//        {
//            [weakSelf performSelectorOnMainThread:@selector(onEmailValidationSuccess) withObject:nil waitUntilDone:NO];
//        }
//        else
//        {
//            NSLog(@"Error in validating Email id");
//        }
//
//
//
//    } errorBlock:^(NSError *error) {
//
//        [weakSelf performSelectorOnMainThread:@selector(onEmailValidationFailur:) withObject:error waitUntilDone:NO];
//
//        NSLog(@"error block=%@,%@",error.localizedDescription,error.localizedFailureReason);
//    }];
//}
//
//-(void)onEmailValidationFailur:(NSError*)aError
//{
//    self.isEmailError = YES;
//    [self showEmailIdErrorMessage:aError.localizedDescription];
//    //self.emailErrorLabel.text=aError.localizedDescription;
//    [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//}
//
//-(void)onEmailValidationSuccess
//{
//    self.isEmailError = NO;
//    [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//    [self validateAndEnableEditProfileSaveButton];
//}
//
//
//-(void)validateUserNameFromServer
//{
//    __weak EditProfileViewController *weakSelf = self;
//    [[ServerConnectionSingleton sharedInstance]sendRequestToValidateSignUpUserName:self.userNameFiled.text withResponseBlock:^(NSDictionary* responseDict) {
//        NSNumber *aStatus=[responseDict objectForKey:@"Success"];
//
//        if(aStatus.boolValue)
//        {
//            [weakSelf performSelectorOnMainThread:@selector(onUsernameValidationSuccess) withObject:nil waitUntilDone:NO];
//        }
//        else
//        {
//            NSLog(@"Error in validating Email id");
//        }
//
//
//
//    } errorBlock:^(NSError *error) {
//
//        [weakSelf performSelectorOnMainThread:@selector(onUsernameValidationFailur:) withObject:error waitUntilDone:NO];
//
//        NSLog(@"error block=%@,%@",error.localizedDescription,error.localizedFailureReason);
//    }];
//}
//
//-(void)onUsernameValidationFailur:(NSError*)aError
//{
//    self.isUserNameError = YES;
//    [self showUsernameErrorMessage:aError.localizedDescription];
//    //self.userNameErrorLabel.text=aError.localizedDescription;
//    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
//
//}
//
//-(void)onUsernameValidationSuccess
//{
//    self.isUserNameError = NO;
//    [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
//    [self validateAndEnableEditProfileSaveButton];
//}
//
//
//-(void)onEmailValidationFailur:(NSError*)aError
//{
//    self.isEmailError = YES;
//    [self showEmailIdErrorMessage:aError.localizedDescription];
//    //self.emailErrorLabel.text=aError.localizedDescription;
//    [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//}
//
//-(void)onEmailValidationSuccess
//{
//    self.isEmailError = NO;
//    [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//    [self validateAndEnableEditProfileSaveButton];
//}
//
//-(BOOL)validateUserName
//{
//    BOOL isValidUserName=NO;
//    if(self.userNameFiled.text.length)
//    {
//        isValidUserName =[Validator isUserNameValid:self.userNameFiled.text];
//        self.isUserNameError = !isValidUserName;
//        if(!isValidUserName)
//        {
//
//            [self showUsernameErrorMessage:@"Minimum 6 characters required. Special characters _ and - are allowed"];
//
//            [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
//
//        }
//
//    }
//    else
//    {
//       [self.userNameFiled setRightViewMode:UITextFieldViewModeAlways];
//    }
//    return isValidUserName;
//}
//
//-(BOOL)validateEmailId
//{
//    BOOL isValidEmail=NO;
//    if(self.emailField.text.length)
//    {
//        isValidEmail=[Validator isEmailValid:self.emailField.text];
//        self.isEmailError = !isValidEmail;
//        if(!isValidEmail)
//        {
//            [self showEmailIdErrorMessage:@"Please Enter a valid email address"];
//            [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//        }
//
//    }
//    else
//    {
//      [self.emailField setRightViewMode:UITextFieldViewModeAlways];
//    }
//    return isValidEmail;
//}
//*/

@end
