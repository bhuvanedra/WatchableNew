//
//  Validator.m
//  Watchable
//
//  Created by Raja Indirajith on 20/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "Validator.h"

@implementation Validator

/*
 * Method Name	: isEmailValid
 * Description	: to validate Email
 * Parameters	: aEmailStr
 * Return value	: BOOL
 */

+ (BOOL)isEmailValid:(NSString *)aEmailStr
{
    BOOL isValid = FALSE;
    NSString *theEmail = [aEmailStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    isValid = [self validateEmail:theEmail];
    return isValid;
}

/*
 * Method Name	: validateEmail
 * Description	: to validate Email with required regex
 * Parameters	: aEmailStr
 * Return value	: BOOL
 */

+ (BOOL)validateEmail:(NSString *)aEmailStr
{
    BOOL isValid = NO;

    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    isValid = [emailTest evaluateWithObject:aEmailStr];

    return isValid;
}

+ (BOOL)isUserNameValid:(NSString *)aNameStr
{
    BOOL isValid = NO;

    NSString *nameRegex = @"[A-Z0-9a-z\\_\\-]*";
    NSPredicate *TestResult = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];

    isValid = [TestResult evaluateWithObject:aNameStr];
    if (isValid)
    {
        if (aNameStr.length < 6)
        {
            isValid = NO;
        }
    }

    return isValid;
}

+ (BOOL)isSignUpPasswordValid:(NSString *)aPasswordStr withErrorMessage:(NSString **)aErrorStr
{
    BOOL isValid = NO;

    NSRange whiteSpaceRange = [aPasswordStr rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whiteSpaceRange.location != NSNotFound)
    {
        isValid = NO;
        *aErrorStr = @"Password cannot contain spaces";
        return isValid;
    }

    if (aPasswordStr.length >= 6)
    {
        NSCharacterSet *set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789!#$^&*()/\\?,_-+\"%';:<>=|[]{}~`@."] invertedSet];

        if ([aPasswordStr rangeOfCharacterFromSet:set].location != NSNotFound)
        {
            isValid = NO;
        }
        else
        {
            isValid = YES;
        }

        /*NSString *passowrdRegex = @"[A-Z0-9a-z]{5,32}";
        
        NSPredicate *PasswordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passowrdRegex];
        isValid = [PasswordTest evaluateWithObject:aPasswordStr];*/

        if (!isValid)
        {
            *aErrorStr = @"Invalid character entered";
        }
    }
    else
    {
        *aErrorStr = @"Requires minimum of 6 characters";
    }

    return isValid;
}

@end
