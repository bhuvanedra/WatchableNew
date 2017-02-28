//
//  Validator.h
//  Watchable
//
//  Created by Raja Indirajith on 20/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Validator : NSObject

+ (BOOL)isEmailValid:(NSString *)aEmailStr;
+ (BOOL)isUserNameValid:(NSString *)aNameStr;
+ (BOOL)isSignUpPasswordValid:(NSString *)aPasswordStr withErrorMessage:(NSString **)aErrorStr;
@end
