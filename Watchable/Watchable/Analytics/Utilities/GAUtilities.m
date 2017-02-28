//
//  GAUtilities.m
//  Watchable
//
//  Created by Gudkesh Yaduvanshi on 1/14/16.
//  Copyright © 2016 comcast. All rights reserved.
//

#import "GAUtilities.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation GAUtilities

+ (void)setWatchbaleScreenName:(NSString *)screenName
{
    // May return nil if a tracker has not already been initialized with a
    // property ID.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
    [tracker set:kGAIScreenName
           value:screenName];
    tracker.allowIDFACollection = YES;

    // New SDK versions
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+ (void)sendWatchableEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label andValue:(NSNumber *)value
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    tracker.allowIDFACollection = YES;

    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:label
                                                           value:value] build]];
}

@end
