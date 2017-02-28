//
//  AnalyticsTokens.m
//  Watchable
//
//  Created by valtech on 17/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "AnalyticsTokens.h"
#import "WatchableConstants.h"
#import "ServerConnectionSingleton.h"
#import "Utilities.h"

@implementation AnalyticsTokens

- (void)analyticsSessionTrackingIdShouldFetchFromServer:(BOOL)fetchFromserver
{
    if (!fetchFromserver)
    {
        NSString *token = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        BOOL isValidToken = [self isSessionTrackingIdValid];
        if (isValidToken && token != nil)
        {
            return;
        }
    }

    [[ServerConnectionSingleton sharedInstance] getAnalyticsTrackingSessionIdForPathTemplate:@"/fuuids/api/uuid/session"
        withResponseBlock:^(NSString *responseString) {

          if (responseString)
          {
              [Utilities setValueForKeyInUserDefaults:responseString key:kSessionTrackingId];
              [Utilities setValueForKeyInUserDefaults:[NSDate date] key:kSessionTrackingIdSavingDate];
              [Utilities removeObjectFromPreferencesForKey:kTempSessionTrackingId];
              [Utilities setValueForKeyInUserDefaults:responseString key:kTempSessionTrackingId];
          }

        }
        errorBlock:^(NSError *error) {

          NSLog(@"error block=%@", error.localizedDescription);

        }];
}

- (void)analyticsDeviceId
{
    NSString *token = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
    if (!token)
    {
        [[ServerConnectionSingleton sharedInstance] getAnalyticsDeviceForPathTemplate:@"/fuuids/api/uuid/device"
            withResponseBlock:^(NSString *responseString) {

              if (responseString)
              {
                  [Utilities setValueForKeyInUserDefaults:responseString key:kDeviceId];
              }

            }
            errorBlock:^(NSError *error) {

              NSLog(@"error block=%@", error.localizedDescription);

            }];
    }
}

- (void)analyticsSubSessionId
{
    NSString *token = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
    if (!token)
    {
        [[ServerConnectionSingleton sharedInstance] getAnalyticsSubsessionIdForPathTemplate:@"/fuuids/api/uuid/session/sub"
            withResponseBlock:^(NSString *responseString) {

              if (responseString)
              {
                  [Utilities setValueForKeyInUserDefaults:responseString key:kSubSessionId];
                  [Utilities removeObjectFromPreferencesForKey:kTempSubSessionId];
                  [Utilities setValueForKeyInUserDefaults:responseString key:kTempSubSessionId];
              }

            }
            errorBlock:^(NSError *error) {

              NSLog(@"error block=%@", error.localizedDescription);

            }];
    }
}

- (void)analyticsEventSessionTokenShouldFetchFromServer:(BOOL)fetchFromServer
{
    if (!fetchFromServer)
    {
        NSString *token = [Utilities getValueFromUserDefaultsForKey:kAnalyticsSessionId];
        BOOL isValidToken = [self isAnalyticsSessionIdValid];
        if (isValidToken && token != nil)
        {
            return;
        }
    }

    [[ServerConnectionSingleton sharedInstance] getAnalyticsUUIdForPathTemplate:@"/fuuids/api/uuid"
        withResponseBlock:^(NSString *responseString) {

          if (responseString)
          {
              [Utilities setValueForKeyInUserDefaults:responseString key:kAnalyticsSessionId];
              [Utilities setValueForKeyInUserDefaults:[NSDate date] key:kAnalyticsSessionIdSavingDate];
          }

        }
        errorBlock:^(NSError *error) {

          NSLog(@"error block=%@", error.localizedDescription);

        }];
}

- (BOOL)isSessionTrackingIdValid
{
    NSDate *aDate = (NSDate *)[Utilities getValueFromUserDefaultsForKey:kSessionTrackingIdSavingDate];
    if (aDate)
    {
        NSDate *currentDate = [NSDate date];
        double aDifference = [currentDate timeIntervalSinceDate:aDate];

        if (aDifference < kTrackingSessionTimeoutSec)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isAnalyticsSessionIdValid
{
    NSDate *aDate = (NSDate *)[Utilities getValueFromUserDefaultsForKey:kAnalyticsSessionIdSavingDate];
    if (aDate)
    {
        NSDate *currentDate = [NSDate date];
        double aDifference = [currentDate timeIntervalSinceDate:aDate];

        if (aDifference < kSessionTimeoutSec)
        {
            return YES;
        }
    }
    return NO;
}

- (void)getAnalyticsTokens
{
    [self performSelectorOnMainThread:@selector(analyticsDeviceId) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(analyticsSessionTrackingIdShouldFetchFromServer:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(analyticsSubSessionId) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(analyticsEventSessionTokenShouldFetchFromServer:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
}

@end
