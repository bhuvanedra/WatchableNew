//
//  Utilities.h
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Utilities : NSObject

+ (void)setValueForKeyInUserDefaults:(NSObject *)objVal key:(NSString *)strKey;
+ (void)removeObjectFromPreferencesForKey:(NSString *)aKey;
+ (void)clearSessionToken;
+ (NSString *)getValueFromUserDefaultsForKey:(NSString *)strKey;
+ (NSDate *)dateFromString:(NSString *)value;
+ (NSString *)postDateFromString:(NSString *)value;
+ (void)addGradientToView:(UIView *)aView;
+ (void)addGradientToPlayListCellImageView:(UIView *)aView;
+ (void)addGradientToPlayDetailFirstCellImageView:(UIView *)aView;
+ (void)addGradientToView:(UIView *)aView withEndGradientColor:(UIColor *)aEndColor;
+ (void)addGradientToView:(UIView *)aView withStartGradientColor:(UIColor *)aStartColor withEndGradientColor:(UIColor *)aEndColor;
+ (UIImage *)imageWithColor:(UIColor *)color;
#pragma mark Genre

+ (UIImage *)getGenreImagesForGenereId:(NSString *)aGenreId;
+ (UIImage *)getNewGenreImagesWithTitleName:(NSString *)strTitleName;
+ (NSString *)getGenreTitlesForGenereId:(NSString *)aGenreId;

+ (BOOL)isNetworkConnectionAvaliable;
+ (NSString *)getVersionOfApplicationFromPlist;
+ (void)resetPreferences;
+ (NSString *)timeStamp;
+ (void)addGradientToNavBarView:(UIView *)aView withAplha:(float)aEndAlpha;

+ (void)addGradientToGenreDetailFirstCellImageView:(UIView *)aView withFrame:(CGRect)aRect;
+ (void)addGradientToNavBarViewToShowStatusBar:(UIView *)aView withAplha:(float)aAplha;
+ (void)setAppBackgroundcolorForView:(UIView *)aView;
+ (NSString *)getCurrentUserId;
+ (BOOL)isUserAlreadyLoggedIn;

//Bitly

+ (NSString *)getBitlyUrlForKey:(NSString *)aKey;
@end
