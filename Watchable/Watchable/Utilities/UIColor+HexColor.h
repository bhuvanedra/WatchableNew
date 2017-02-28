//
//  UIColor+HexColor.h
//  signupValidation
//
//  Created by Abhilash on 4/17/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColor)
+ (UIColor *)colorFromHexString:(NSString *)hexString;

@end
