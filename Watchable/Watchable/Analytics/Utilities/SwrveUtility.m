//
//  SwrveUtility.m
//  Watchable
//
//  Created by Gudkesh Yaduvanshi on 12/8/15.
//  Copyright © 2015 comcast. All rights reserved.
//

#import "SwrveUtility.h"
#import "Swrve.h"

@implementation SwrveUtility

+ (SwrveUtility *)sharedInstance
{
    static SwrveUtility *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[SwrveUtility alloc] init];
      // mReachability=[[Reachability alloc]init];
    });
    return sharedInstance;
}

+ (NSDictionary *)getErrorEventPayloadForCode:(NSString *)errorCode

{
    NSMutableDictionary *payload = [NSMutableDictionary new];

    [payload setObject:errorCode forKey:@"error_code"];

    return payload;
}

+ (NSDictionary *)getPayloadforSwrveEventWithAssetTitle:(NSString *)assetTitle
                                                assetId:(NSString *)assetId
                                           channleTitle:(NSString *)channleTitle
                                              channleId:(NSString *)channleId
                                             genreTitle:(NSString *)genreTitle
                                                genreId:(NSString *)genreId
                                         publisherTitle:(NSString *)publisherTitle
                                            publisherId:(NSString *)publisherId
                                          playlistTitle:(NSString *)playlistTitle
                                             playlistId:(NSString *)playlistId
{
    NSMutableDictionary *payload = [NSMutableDictionary new];

    if (assetTitle)
    {
        [payload setObject:assetTitle forKey:@"Video_Title"];
    }
    if (assetId)
    {
        [payload setObject:assetId forKey:@"Video_Id"];
    }
    if (channleTitle)
    {
        [payload setObject:channleTitle forKey:@"Channle_Title"];
    }
    if (channleId)
    {
        [payload setObject:channleId forKey:@"Channle_Id"];
    }
    if (genreTitle)
    {
        [payload setObject:genreTitle forKey:@"Genre_Title"];
    }
    if (genreId)
    {
        [payload setObject:genreId forKey:@"Genre_Id"];
    }
    if (publisherTitle)
    {
        [payload setObject:publisherTitle forKey:@"Publisher_Title"];
    }
    if (publisherId)
    {
        [payload setObject:publisherId forKey:@"Publisher_Id"];
    }
    if (playlistTitle)
    {
        [payload setObject:playlistTitle forKey:@"Playlist_Title"];
    }
    if (playlistId)
    {
        [payload setObject:playlistId forKey:@"Playlist_Id"];
    }

    return payload;
}

+ (void)updateSwrveUserProperty:(BOOL)isLoggedIn
{
    [[Swrve sharedInstance] userUpdate:@{ @"is_logged_in" : [NSNumber numberWithBool:isLoggedIn] }];
}

- (void)intializeSwrveSdk
{
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = NO;
    [Swrve sharedInstanceWithAppID:kSwrveAppId apiKey:kSwrveApiKey config:config];
}

- (void)postSwrveEvent:(NSString *)eventName
{
    if (eventName)
        [[Swrve sharedInstance] event:eventName];
}

- (void)postSwrveEvent:(NSString *)eventName withPayload:(NSDictionary *)payload
{
    if (eventName)
    {
        [[Swrve sharedInstance] event:eventName payload:payload];
    }
}

@end
