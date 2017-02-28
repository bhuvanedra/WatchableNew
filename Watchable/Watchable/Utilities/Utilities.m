//
//  Utilities.m
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "Utilities.h"
#import "UserProfile.h"

@implementation Utilities

+ (NSString *)getVersionOfApplicationFromPlist
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *buildVersion = nil;
    if (bundleVersion.length)
    {
        buildVersion = [NSString stringWithFormat:@"%@ (%@)", version, bundleVersion];
    }
    else
    {
        buildVersion = [NSString stringWithFormat:@"%@", version];
    }
    return buildVersion;
}

+ (void)setValueForKeyInUserDefaults:(NSObject *)objVal key:(NSString *)strKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:objVal forKey:strKey];
    [defaults synchronize];
}

+ (void)clearSessionToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSessionTokenKey];
    [defaults removeObjectForKey:kSessionTokenSavedDate];
    [defaults synchronize];
}

+ (void)removeObjectFromPreferencesForKey:(NSString *)aKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:aKey];
    [defaults synchronize];
}

+ (void)resetPreferences
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultsDictionary = [defaults persistentDomainForName:appDomain];
    for (NSString *key in [defaultsDictionary allKeys])
    {
        if ([key isEqualToString:kDeviceId] || [key isEqualToString:kSubSessionId] || [key isEqualToString:kSessionTrackingId] || [key isEqualToString:kSessionTrackingIdSavingDate] || [key isEqualToString:kSwrve_userId_key])
        {
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }

    [defaults synchronize];
}

+ (NSObject *)getValueFromUserDefaultsForKey:(NSString *)strKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:strKey];
    if (val)
    {
        return val;
    }
    else
    {
        return nil;
    }
}

- (id)getDataFromNumOrString:(id)data
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    id retValue = nil;
    if ([data isKindOfClass:[NSString class]])
    {
        retValue = [formatter numberFromString:data];
    }
    else
    {
        retValue = data;
    }
    return retValue;
}

+ (NSDate *)dateFromString:(NSString *)value
{
    NSArray *dateFormats = @[
        @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
        @"yyyy'-'MM'-'dd'T'HH':'mm':'ssz",
    ];
    NSDateFormatter *formatter = [NSDateFormatter new];
    for (NSString *format in dateFormats)
    {
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:value];
        if (date != nil)
        {
            return date;
        }
    }
    return nil;
}

+ (NSString *)postDateFromString:(NSString *)value
{
    NSDate *date = [Utilities dateFromString:value];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    NSString *postDate = nil;
    if (date != nil)
    {
        postDate = [formatter stringFromDate:date];
    }
    return postDate;
}

+ (void)addGradientToView:(UIView *)aView
{
    aView.layer.sublayers = nil;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = aView.frame;
    // Add colors to layer
    UIColor *startColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    UIColor *middleColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.1];
    UIColor *endColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];
    gradient.colors = [NSArray arrayWithObjects:
                                   (id)[startColor CGColor], (id)[middleColor CGColor], (id)[endColor CGColor], nil];

    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToPlayListCellImageView:(UIView *)aView
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = aView.frame;
    // Add colors to layer
    UIColor *startColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    UIColor *middleColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    UIColor *endColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    gradient.colors = [NSArray arrayWithObjects:
                                   (id)[startColor CGColor], (id)[middleColor CGColor], (id)[endColor CGColor], nil];

    NSArray *aArray = aView.layer.sublayers;
    for (CALayer *aLayer in aArray)
    {
        [aLayer removeFromSuperlayer];
    }

    // [aView.layer insertSublayer:nil atIndex:0];
    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToPlayDetailFirstCellImageView:(UIView *)aView
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(aView.frame.origin.x, aView.frame.origin.y, aView.frame.size.width, aView.frame.size.height + 100);
    // Add colors to layer

    UIColor *startColor0 = [UIColor clearColor];
    //UIColor *startColor1 = [UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0];

    UIColor *startColor1 = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.1];

    UIColor *startColor2 = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.5];

    UIColor *startColor3 = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];

    gradient.colors = [NSArray arrayWithObjects:(id)[startColor0 CGColor], (id)[startColor0 CGColor], (id)[startColor1 CGColor], (id)[startColor2 CGColor], (id)[startColor3 CGColor], (id)[startColor3 CGColor], nil];

    NSArray *aArray = aView.layer.sublayers;
    for (CALayer *aLayer in aArray)
    {
        [aLayer removeFromSuperlayer];
    }

    // [aView.layer insertSublayer:nil atIndex:0];
    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToGenreDetailFirstCellImageView:(UIView *)aView withFrame:(CGRect)aRect
{
    aView.layer.sublayers = nil;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = aRect;

    UIColor *startColor1 = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.0];

    UIColor *startColor2 = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];

    gradient.colors = [NSArray arrayWithObjects:(id)[startColor1 CGColor], (id)[startColor2 CGColor], nil];
    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToView:(UIView *)aView withEndGradientColor:(UIColor *)aEndColor
{
    aView.layer.sublayers = nil;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = aView.frame;
    // Add colors to layer
    UIColor *centerColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    UIColor *endColor = aEndColor;
    gradient.colors = [NSArray arrayWithObjects:
                                   (id)[centerColor CGColor], (id)[centerColor CGColor], (id)[endColor CGColor], nil];

    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToView:(UIView *)aView withStartGradientColor:(UIColor *)aStartColor withEndGradientColor:(UIColor *)aEndColor
{
    //aView.layer.sublayers = nil;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = aView.bounds;
    // Add colors to layer
    gradient.colors = [NSArray arrayWithObjects:
                                   (id)[aStartColor CGColor], (id)[aEndColor CGColor], nil];

    [aView.layer insertSublayer:gradient atIndex:0];
}

+ (void)addGradientToNavBarViewToShowStatusBar:(UIView *)aView withAplha:(float)aAplha
{
    @synchronized(self)
    {
        UIColor *startColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:.9 - (2 * aAplha)];

        UIColor *endColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:aAplha];

        NSArray *aColorArray = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];

        NSArray *aArray = aView.layer.sublayers;
        BOOL isGradientLayerPresents = NO;

        for (CALayer *aLayer in aArray)
        {
            if ([aLayer isMemberOfClass:[CAGradientLayer class]])
            {
                CAGradientLayer *aCAGradientLayer = (CAGradientLayer *)aLayer;
                aCAGradientLayer.colors = aColorArray;
                isGradientLayerPresents = YES;
                break;
            }
        }

        if (!isGradientLayerPresents)
        {
            CAGradientLayer *gradient = [CAGradientLayer layer];

            gradient.frame = CGRectMake(aView.frame.origin.x, aView.frame.origin.y

                                        ,
                                        aView.frame.size.width, aView.frame.size.height);

            gradient.colors = aColorArray;
            [aView.layer insertSublayer:gradient atIndex:0];
        }
    }
}

+ (void)addGradientToNavBarView:(UIView *)aView withAplha:(float)aEndAlpha
{
    @synchronized(self)
    {
        UIColor *startColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0];

        UIColor *endColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:aEndAlpha];

        NSArray *aColorArray = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];

        NSArray *aArray = aView.layer.sublayers;
        BOOL isGradientLayerPresents = NO;

        for (CALayer *aLayer in aArray)
        {
            if ([aLayer isMemberOfClass:[CAGradientLayer class]])
            {
                CAGradientLayer *aCAGradientLayer = (CAGradientLayer *)aLayer;
                aCAGradientLayer.colors = aColorArray;
                isGradientLayerPresents = YES;
                break;
            }
        }

        if (!isGradientLayerPresents)
        {
            CAGradientLayer *gradient = [CAGradientLayer layer];

            gradient.frame = CGRectMake(aView.frame.origin.x, aView.frame.origin.y

                                        ,
                                        aView.frame.size.width, aView.frame.size.height);

            gradient.colors = aColorArray;
            [aView.layer insertSublayer:gradient atIndex:0];
        }
    }
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark Image

+ (UIImage *)getGenreImagesForGenereId:(NSString *)aGenreId
{
    UIImage *aGenreImage = nil;

    if ([aGenreId isEqualToString:@"200"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_animation.png"];
    }
    else if ([aGenreId isEqualToString:@"201"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_auto.png"];
    }
    else if ([aGenreId isEqualToString:@"205"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_entertainment.png"];
    }
    else if ([aGenreId isEqualToString:@"204"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_fashionstyle.png"];
    }
    else if ([aGenreId isEqualToString:@"208"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_travel.png"];
    }
    else if ([aGenreId isEqualToString:@"202"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_funny.png"];
    }
    else if ([aGenreId isEqualToString:@"203"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_gaming.png"];
    }
    else if ([aGenreId isEqualToString:@"206"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_music.png"];
    }
    else if ([aGenreId isEqualToString:@"207"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_news.png"];
    }
    else if ([aGenreId isEqualToString:@"209"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_science.png"];
    }
    else if ([aGenreId isEqualToString:@"212"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_series.png"];
    }
    else if ([aGenreId isEqualToString:@"210"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_sports.png"];
    }
    else if ([aGenreId isEqualToString:@"211"])
    {
        aGenreImage = [UIImage imageNamed:@"genre_travel.png"];
    }

    return aGenreImage;
}

+ (UIImage *)getNewGenreImagesWithTitleName:(NSString *)strTitleName
{
    UIImage *aGenreImage = nil;
    aGenreImage = [UIImage imageNamed:strTitleName];
    return aGenreImage;
}

/*
 + (NSString*)getGenreTitlesForGenereId:(NSString*)aGenreId{
 
 NSString *aGenreTitle=nil;
 
 if([aGenreId isEqualToString:@"200"])
 {
 aGenreTitle=@"Animation";
 }
 else if([aGenreId isEqualToString:@"201"])
 {
 aGenreTitle=@"Auto";
 }
 else if([aGenreId isEqualToString:@"205"])
 {
 aGenreTitle=@"Entertainment";
 }
 else if([aGenreId isEqualToString:@"204"])
 {
 aGenreTitle=@"Fashion & Style";
 }
 else if([aGenreId isEqualToString:@"208"])
 {
 aGenreTitle=@"Food";
 }
 else if([aGenreId isEqualToString:@"202"])
 {
 aGenreTitle=@"Funny";
 }
 else if([aGenreId isEqualToString:@"203"])
 {
 aGenreTitle=@"Gaming";
 }
 else if([aGenreId isEqualToString:@"206"])
 {
 aGenreTitle=@"Music";
 }
 else if([aGenreId isEqualToString:@"207"])
 {
 aGenreTitle=@"News";
 }
 else if([aGenreId isEqualToString:@"209"])
 {
 aGenreTitle=@"Science & Tech";
 }
 else if([aGenreId isEqualToString:@"212"])
 {
 aGenreTitle=@"Series";
 }
 else if([aGenreId isEqualToString:@"210"])
 {
 aGenreTitle=@"Sports";
 }
 else if([aGenreId isEqualToString:@"211"])
 {
 aGenreTitle=@"Travel";
 }
 
 
 return aGenreTitle;
 
 }

 */

+ (NSString *)getGenreTitlesForGenereId:(NSString *)aGenreId
{
    NSString *aGenreTitle = nil;
    if ([aGenreId isEqualToString:@"200"])
    {
        aGenreTitle = @"Animation";
    }

    else if ([aGenreId isEqualToString:@"201"])
    {
        aGenreTitle = @"Automotive";
    }
    else if ([aGenreId isEqualToString:@"205"])
    {
        aGenreTitle = @"Entertainment";
    }
    else if ([aGenreId isEqualToString:@"204"])
    {
        aGenreTitle = @"Fashion & Style";
    }
    else if ([aGenreId isEqualToString:@"208"])
    {
        aGenreTitle = @"Food & Travel";
    }
    else if ([aGenreId isEqualToString:@"202"])
    {
        aGenreTitle = @"Funny";
    }
    else if ([aGenreId isEqualToString:@"203"])
    {
        aGenreTitle = @"Gaming";
    }
    else if ([aGenreId isEqualToString:@"206"])
    {
        aGenreTitle = @"Music";
    }
    else if ([aGenreId isEqualToString:@"207"])
    {
        aGenreTitle = @"News";
    }
    else if ([aGenreId isEqualToString:@"209"])
    {
        aGenreTitle = @"Science & Tech";
    }
    else if ([aGenreId isEqualToString:@"212"])
    {
        aGenreTitle = @"Series";
    }
    else if ([aGenreId isEqualToString:@"210"])
    {
        aGenreTitle = @"Sports";
    }
    else if ([aGenreId isEqualToString:@"211"])
    {
        aGenreTitle = @"Travel";
    }

    return aGenreTitle;
}

/*
+ (NSString*)getGenreImageNameForGenereId:(NSString*)aGenreId{
    
    NSString *aGenreTitle=nil;
    
    if([aGenreId isEqualToString:@"200"])
    {
        aGenreTitle=@"genre_animation_header.png";
    }
    else if([aGenreId isEqualToString:@"201"])
    {
        aGenreTitle=@"genre_auto_header.png";
    }
    else if([aGenreId isEqualToString:@"205"])
    {
        aGenreTitle=@"genre_entertainment_header.png";
    }
    else if([aGenreId isEqualToString:@"204"])
    {
        aGenreTitle=@"genre_fashionstyle_header.png";
    }
    else if([aGenreId isEqualToString:@"208"])
    {
        aGenreTitle=@"genre_food_header.png";
    }
    else if([aGenreId isEqualToString:@"202"])
    {
        aGenreTitle=@"genre_funny_header.png";
    }
    else if([aGenreId isEqualToString:@"203"])
    {
        aGenreTitle=@"genre_gaming_header.png";
    }
    else if([aGenreId isEqualToString:@"206"])
    {
        aGenreTitle=@"genre_music_header.png";
    }
    else if([aGenreId isEqualToString:@"207"])
    {
        aGenreTitle=@"genre_news_header.png";
    }
    else if([aGenreId isEqualToString:@"209"])
    {
        aGenreTitle=@"genre_science_header.png";
    }
    else if([aGenreId isEqualToString:@"212"])
    {
        aGenreTitle=@"genre_series_header.png";
    }
    else if([aGenreId isEqualToString:@"210"])
    {
        aGenreTitle=@"genre_sports_header.png";
    }
    else if([aGenreId isEqualToString:@"211"])
    {
        aGenreTitle=@"Travel_header.png";
    }
    
    
    return aGenreTitle;
    
}
*/

+ (BOOL)isNetworkConnectionAvaliable
{
    BOOL aStatus = YES;
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        aStatus = NO;
    }
    return aStatus;
}

+ (NSString *)timeStamp
{
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    double aTimestamp = timeInMiliseconds;
    aTimestamp = aTimestamp * 1000;
    NSLog(@"TimeInMiliSeconds:%@", [NSString stringWithFormat:@"%lld", (long long)aTimestamp]);
    return [NSString stringWithFormat:@"%lld", (long long)aTimestamp];
}

+ (void)setAppBackgroundcolorForView:(UIView *)aView
{
    aView.backgroundColor = [UIColor colorWithRed:0.105882 green:0.113725 blue:0.117647 alpha:1.0];
    aView.tintColor = [UIColor colorWithRed:0.0 green:0.478431 blue:1.0 alpha:1.0];
}

+ (NSString *)getCurrentUserId
{
    if ([[self class] isUserAlreadyLoggedIn])
    {
        //        UserProfile *profile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];
        //
        //        if (profile.mUserId && ![profile.mUserId isKindOfClass:[NSNull class]]) {
        //
        //            NSLog(@"The UserId=%@",profile.mUserId);
        //            return profile.mUserId;
        //
        //        }else{
        //
        //            return @"-1";
        //        }

        @try
        {
            NSString *aUserId = [Utilities getValueFromUserDefaultsForKey:kUserId];
            if (aUserId && aUserId != nil)
            {
                return aUserId;
            }
            else
            {
                return @"-1";
            }
        }
        @catch (NSException *exception)
        {
            NSLog(@"%@", exception);
            return @"-1";
        }
    }

    return @"-1";
}

+ (BOOL)isUserAlreadyLoggedIn
{
    NSString *aAuthorizationStr = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];

    if (aAuthorizationStr.length)
        return YES;

    return NO;
}

+ (NSString *)getBitlyUrlForKey:(NSString *)aKey
{
    return nil;
}

@end
