//
//  GAUtilities.h
//  Watchable
//
//  Created by Gudkesh Yaduvanshi on 1/14/16.
//  Copyright © 2016 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAUtilities : NSObject

+ (void)setWatchbaleScreenName:(NSString *)screenName;
+ (void)sendWatchableEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label andValue:(NSNumber *)value;

@end
