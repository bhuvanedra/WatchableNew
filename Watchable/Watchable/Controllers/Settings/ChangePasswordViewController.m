//
//  ChangePasswordViewController.m
//  Watchable
//
//  Created by Abhilash on 6/3/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ChangePasswordViewController.h"

#import "AnalyticsEventsHandler.h"
#import "GAUtilities.h"
#import "ServerConnectionSingleton.h"
#import "Validator.h"
#import "Watchable-Swift.h"

@interface ChangePasswordViewController ()

@property (weak, nonatomic) IBOutlet UITextField *oldPassword;

@property (weak, nonatomic) IBOutlet UITextField *passwordFiled_;
@property (weak, nonatomic) IBOutlet UITextField *reEnterPassField_;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@end

@implementation ChangePasswordViewController

#pragma mark View Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:27 / 255.0 green:29 / 255.0 blue:30 / 255.0 alpha:1];
    [super viewDidLoad];
    [self createNavBarWithHidden:NO];
    [self setBackButtonOnNavBar];
    [self setEditProfileButtonsOnNavBar];
    _errorLabel.backgroundColor = [UIColor clearColor];
    _errorLabel.text = @"";
    [self setNavigationBarTitle:@"CHANGE PASSWORD" withFont:nil withTextColor:nil];

    self.oldPassword.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Old password"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.5],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:15.0]
                                        }];

    self.passwordFiled_.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"New password"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.5],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:15.0]
                                        }];

    self.reEnterPassField_.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Confirm new password"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.5],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:15.0]
                                        }];

    [self.passwordFiled_ setRightViewMode:UITextFieldViewModeNever];
    [self.reEnterPassField_ setRightViewMode:UITextFieldViewModeNever];
    [self.oldPassword setRightViewMode:UITextFieldViewModeAlways];

    UIImage *aCheckImage = [UIImage imageNamed:@"Check.png"];
    UIImageView *passwordTickImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 15, 16, 16)];
    passwordTickImageView.image = aCheckImage;
    [self.passwordFiled_ setRightView:passwordTickImageView];

    UIImageView *confirmPasswordTickImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 15, 16, 16)];
    confirmPasswordTickImageView.image = aCheckImage;
    [self.reEnterPassField_ setRightView:confirmPasswordTickImageView];

    [self.oldPassword setTintColor:[UIColor darkGrayColor]];
    [self.passwordFiled_ setTintColor:[UIColor darkGrayColor]];
    [self.reEnterPassField_ setTintColor:[UIColor darkGrayColor]];
    [self validateAndEnableSaveButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"ChangePasswordScreen"];
}

#pragma mark Navigation bar button action Methods
- (void)onClickingCancelButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickingSaveButton

{
    if (self.oldPassword.rightViewMode == UITextFieldViewModeAlways && self.passwordFiled_.rightViewMode == UITextFieldViewModeAlways && (self.reEnterPassField_.rightViewMode == UITextFieldViewModeNever || self.reEnterPassField_.rightViewMode == UITextFieldViewModeAlways))
    {
        if ([self.passwordFiled_.text isEqualToString:self.reEnterPassField_.text])
        {
            NSString *trimmedUsernameStr = [self.oldPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (trimmedUsernameStr.length > 0)
            {
                [self changePassword];
            }
            else if (trimmedUsernameStr == 0)
            {
                [self setErrorMessage:@"Please enter valid old password"];
            }
            else
            {
                [self setErrorMessage:@"Please enter old password"];
            }
        }
        else
        {
            [self setErrorMessage:@"New passwords must match"];
            self.reEnterPassField_.rightViewMode = UITextFieldViewModeNever;
            [self enableEditProfileSaveButton:YES];
        }
    }
}

- (void)changePassword
{
    //if error update error label with error msg

    NSDictionary *body = @{ @"oldPassword" : self.oldPassword.text,
                            @"newPassword" : self.passwordFiled_.text };

    // NSDictionary *body =@{@"userProfile":profileDict};
    __weak ChangePasswordViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToUpdateUserProfile:body
        withResponseBlock:^(NSDictionary *responseDict) {

          NSNumber *aStatus = [responseDict objectForKey:@"Success"];

          if (aStatus.boolValue)
          {
              [weakSelf performSelectorOnMainThread:@selector(onPasswordChangeSuccess) withObject:nil waitUntilDone:NO];
          }
          else
          {
          }

        }
        errorBlock:^(NSError *error) {

          if (weakSelf)
          {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                if (error.code == kWrongOldPassword)
                {
                    [weakSelf performSelectorOnMainThread:@selector(onChangePasswordFailure:) withObject:error waitUntilDone:NO];
                }
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                else if (error.code == kServerErrorCode)
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

- (void)onPasswordChangeSuccess
{
    NSString *message = NSLocalizedString(@"Your password has been changed", @"One of the 'generic Watchable' alert's messages");
    UIAlertController *alert = [AlertFactory genericWatchableWithTitle:nil andMessage:message];
    [self presentViewController:alert animated:YES completion:nil];

    [self resetTextFields];
    //    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameUpdatePassword andUserId:[Utilities getCurrentUserId]];
}

- (void)resetTextFields
{
    _oldPassword.text = nil;
    _passwordFiled_.text = nil;
    _reEnterPassField_.text = nil;
    _oldPassword.rightViewMode = UITextFieldViewModeAlways;
    _passwordFiled_.rightViewMode = UITextFieldViewModeNever;
    _reEnterPassField_.rightViewMode = UITextFieldViewModeNever;
    [self enableEditProfileSaveButton:NO];
}

- (void)onChangePasswordFailure:(NSError *)aError
{
    UIAlertController *alert = [AlertFactory genericWatchableWithTitle:nil andMessage:aError.localizedDescription];
    [self presentViewController:alert animated:YES completion:nil];

    [self resetTextFields];
}

#pragma mark validation Methods
//-(void)hideErrorLabel:(BOOL)hidden forTextField:(UITextField*)textField andMessage:(NSString*)message{
//
//    NSString *errorString = nil;
//    if(textField == _oldPassword){
//
//        errorString = [NSString stringWithFormat:@"Old %@",[message lowercaseString]];
//    }else if(textField == _passwordFiled_){
//
//        errorString = [NSString stringWithFormat:@"New %@",[message lowercaseString]];
//    }else{
//
//        errorString = [NSString stringWithFormat:@"Confirm %@",[message lowercaseString]];
//    }
//
//    _errorLabel.hidden = hidden;
//    _errorLabel.text = errorString;
//}

- (void)setErrorMessage:(NSString *)aErrorMsg
{
    self.errorLabel.text = aErrorMsg;
}

- (void)validateAndEnableSaveButton
{
    if (self.oldPassword.rightViewMode == UITextFieldViewModeAlways && self.passwordFiled_.rightViewMode == UITextFieldViewModeAlways && (self.reEnterPassField_.rightViewMode == UITextFieldViewModeNever || self.reEnterPassField_.rightViewMode == UITextFieldViewModeAlways))
    {
        //        if([self.passwordFiled_.text isEqualToString:self.reEnterPassField_.text])
        //        {

        [self enableEditProfileSaveButton:YES];

        //        }else{
        //
        //            [self setErrorMessage:@"New passwords must match"];
        //            self.reEnterPassField_.rightViewMode = UITextFieldViewModeNever;
        //            [self enableEditProfileSaveButton:YES];
        //        }
    }
    else
    {
        [self enableEditProfileSaveButton:NO];
    }
}

- (BOOL)validatePasswordForField:(UITextField *)textField
{
    BOOL isValidPassword = NO;
    if (textField.text.length)
    {
        NSString *aErrorMsgStr = nil;
        isValidPassword = [Validator isSignUpPasswordValid:textField.text withErrorMessage:&aErrorMsgStr];
        if (isValidPassword)
        {
            textField.rightViewMode = UITextFieldViewModeAlways;
            [self setErrorMessage:@""];
        }
        else if (textField == _oldPassword)
        {
            textField.rightViewMode = UITextFieldViewModeAlways;
            [self setErrorMessage:@""];
        }
        else
        {
            [self setErrorMessage:aErrorMsgStr];
            textField.rightViewMode = UITextFieldViewModeNever;
        }
    }
    if (textField == _oldPassword)
    {
        textField.rightViewMode = UITextFieldViewModeAlways;
    }
    return isValidPassword;
}

#pragma mark UITextField delegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField.text.length == 0)
    {
        [self setErrorMessage:@""];
    }
    if (textField == self.reEnterPassField_)
    {
        [self enableEditProfileSaveButton:YES];
        [self setErrorMessage:@""];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField != _oldPassword)
    {
        BOOL isValidPassword = [self validatePasswordForField:textField];
        if (textField == self.reEnterPassField_)
        {
            if (isValidPassword)
            {
                [self validateAndEnableSaveButton];
            }
            else
            {
                [self.reEnterPassField_ setRightViewMode:UITextFieldViewModeNever];
            }
        }
    }
    else
    {
        [self.oldPassword setRightViewMode:UITextFieldViewModeAlways];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self validateAndEnableSaveButton];

    if (textField == self.oldPassword)
    {
        [self.passwordFiled_ becomeFirstResponder];
    }

    if (textField == self.passwordFiled_)
    {
        [self.reEnterPassField_ becomeFirstResponder];
        [self enableEditProfileSaveButton:YES];
    }

    if (textField == self.reEnterPassField_)
    {
        if (textField.text.length == 0)
        {
            [self setErrorMessage:@""];
        }
        [textField resignFirstResponder];
        [self onClickingSaveButton];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self setErrorMessage:@""];

    if (textField == _oldPassword)
    {
        [textField setRightViewMode:UITextFieldViewModeAlways];
    }

    [textField setRightViewMode:UITextFieldViewModeNever];

    [self validateAndEnableSaveButton];

    return YES;
}

#pragma mark memory warnings Method

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
