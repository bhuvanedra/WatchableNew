//
//  AnalyticsEventBodyConstructer.m
//  Watchable
//
//  Created by valtech on 17/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "AnalyticsEventBodyConstructer.h"
#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <sys/sysctl.h>
#import "Utilities.h"
#import "WatchableConstants.h"
#import "DBHandler.h"
#import "UserProfile.h"
#import "ServerConnectionSingleton.h"

@implementation AnalyticsEventBodyConstructer

+ (AnalyticsEventBodyConstructer *)sharedInstance
{
    static AnalyticsEventBodyConstructer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[AnalyticsEventBodyConstructer alloc] init];
    });
    return sharedInstance;
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL)
        {
            if (temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (NSString *)platformRawString
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (NSString *)platformNiceString
{
    NSString *modelIdentifier = [self platformRawString];

    if ([modelIdentifier isEqualToString:@"iPhone3,1"])
        return @"iPhone4";
    if ([modelIdentifier isEqualToString:@"iPhone4,1"])
        return @"iPhone4S";
    if ([modelIdentifier isEqualToString:@"iPhone5,1"])
        return @"iPhone5";
    if ([modelIdentifier isEqualToString:@"iPhone5,1"])
        return @"iPhone5";
    if ([modelIdentifier isEqualToString:@"iPhone5,2"])
        return @"iPhone5";
    if ([modelIdentifier isEqualToString:@"iPhone5,3"])
        return @"iPhone5c";
    if ([modelIdentifier isEqualToString:@"iPhone5,4"])
        return @"iPhone5c";
    if ([modelIdentifier isEqualToString:@"iPhone6,1"])
        return @"iPhone5s";
    if ([modelIdentifier isEqualToString:@"iPhone6,2"])
        return @"iPhone5s";
    if ([modelIdentifier isEqualToString:@"iPhone7,1"])
        return @"iPhone6Plus";
    if ([modelIdentifier isEqualToString:@"iPhone7,2"])
        return @"iPhone6";
    if ([modelIdentifier isEqualToString:@"i386"])
        return @"Simulator";
    if ([modelIdentifier isEqualToString:@"x86_64"])
        return @"Simulator";

    return modelIdentifier;
}

- (NSString *)getTheSystemVersion
{
    NSString *version = [[UIDevice currentDevice] systemVersion];
    return [NSString stringWithFormat:@"iOS_%@", version];
}

- (NSString *)getUserAgent
{
    return [NSString stringWithFormat:@"%@/%@", [self platformNiceString], [self getTheSystemVersion]];
}

- (NSString *)getTimeZone
{
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSInteger gmt = [timeZone secondsFromGMT] / 60;
    NSString *tzName = [NSString stringWithFormat:@"%ld", (long)gmt];
    return tzName;
}

- (NSString *)getCurrentUserId
{
    if ([self isUserAlreadyLoggedIn])
    {
        UserProfile *profile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];

        if (profile.mUserId && ![profile.mUserId isKindOfClass:[NSNull class]])
        {
            NSLog(@"The UserId=%@", profile.mUserId);
            return profile.mUserId;
        }
        else
        {
            return @"-1";
        }
    }

    return @"-1";
}

- (BOOL)isUserAlreadyLoggedIn
{
    NSString *aAuthorizationStr = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];

    if (aAuthorizationStr.length)
        return YES;

    return NO;
}

- (NSDictionary *)getBodyForEventType:(NSString *)eventType EventName:(NSString *)eventName playListId:(NSString *)playlistId ipAddress:(NSString *)ipAddress channelId:(NSString *)channelId andAsset:(NSString *)assetId andFromPlaylistPage:(BOOL)isFromPlaylist
{
    NSDictionary *body = nil;
    @try
    {
        NSString *deviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
        NSString *subSessionId = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
        NSString *trackingSessionId = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        NSString *timeStamp = [Utilities timeStamp];
        NSString *timezone = [self getTimeZone];
        NSString *userId = [self getCurrentUserId];
        NSString *userAgent = [self getUserAgent];

        body =

            @{
                @"EventType" : eventType,

                @"EventName" : eventName,

                @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : @"trackingSessionId",

                @"UserId" : (userId) ? userId : @"-1",

                @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                @"ZipCode" : @"-1",

                @"SubSessionId" : (subSessionId) ? subSessionId : @"subSessionId",

                @"AppType" : @"iOS App",

                @"AppId" : @"Watchable",

                @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                @"TimeZone" : (timezone) ? timezone : @"-1",

                @"UserAgent" : (userAgent) ? userAgent : @"-1",

                @"IsProduction" : isProduction,

                @"DeviceType" : @"iPhone",

                @"ReportFrom" : @"iOS App"

            };
        NSMutableDictionary *aBody = [body mutableCopy];

        if (isFromPlaylist)
        {
            if ([eventName rangeOfString:@"Playlist" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [aBody setObject:(playlistId) ? playlistId : @"-1" forKey:@"PlaylistId"];
            }
            else
            {
                [aBody setObject:(playlistId) ? playlistId : @"-1" forKey:@"PlaylistId"];
                [aBody setObject:(channelId) ? channelId : @"-1" forKey:@"ChannelId"];
                [aBody setObject:(assetId) ? assetId : @"-1" forKey:@"AssetId"];
            }
        }
        else
        {
            if ([eventName rangeOfString:@"Playlist" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [aBody setObject:(playlistId) ? playlistId : @"-1" forKey:@"PlaylistId"];
            }
            else
            {
                [aBody setObject:(channelId) ? channelId : @"-1" forKey:@"ChannelId"];
                [aBody setObject:(assetId) ? assetId : @"-1" forKey:@"AssetId"];
            }
        }

        body = aBody;
    }
    @catch (NSException *exception)
    {
        NSLog(@"AnalyticsEventBodyException eventname:%@ and eventType :%@  = %@", eventName, eventType, exception);
    }

    return body;
}

- (NSDictionary *)getGeneralBodyForEventType:(NSString *)eventType EventName:(NSString *)eventName userId:(NSString *)userId andIpAddress:(NSString *)ipAddress
{
    NSDictionary *body = nil;

    @try
    {
        NSString *deviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
        NSString *subSessionId = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
        NSString *trackingSessionId = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        NSString *tempsubSessionId = [Utilities getValueFromUserDefaultsForKey:kTempSubSessionId];
        NSString *temptrackingSessionId = [Utilities getValueFromUserDefaultsForKey:kTempSessionTrackingId];
        NSString *timeStamp = [Utilities timeStamp];
        NSString *timezone = [self getTimeZone];
        //NSString *userId = [self getCurrentUserId];
        NSString *userAgent = [self getUserAgent];

        body =

            @{

                @"EventType" : eventType,

                @"EventName" : eventName,

                @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : temptrackingSessionId,

                @"UserId" : (userId) ? userId : @"-1",

                @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                @"ZipCode" : @"-1",

                @"SubSessionId" : (subSessionId) ? subSessionId : tempsubSessionId,

                @"AppType" : @"iOS App",

                @"AppId" : @"Watchable",

                @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                @"TimeZone" : (timezone) ? timezone : @"-1",

                @"UserAgent" : (userAgent) ? userAgent : @"-1",

                @"IsProduction" : isProduction,

                @"DeviceType" : @"iPhone",

                @"ReportFrom" : @"iOS App"

            };

        if ([eventName rangeOfString:kEventNameAppStart options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            NSMutableDictionary *aBody = [body mutableCopy];
            [aBody setObject:@"-1" forKey:@"Referral_code"];
            body = aBody;
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"AnalyticsEventBodyException eventname:%@ and eventType :%@  = %@", eventName, eventType, exception);
    }

    return body;
}

- (NSDictionary *)getBodyForErrorEventType:(NSString *)eventType EventName:(NSString *)eventName ipAddress:(NSString *)ipAddress errorCode:(NSString *)errorCode offendingUrl:(NSString *)offendingUrl andUUID:(NSString *)uuid
{
    NSDictionary *body = nil;

    @try
    {
        NSString *deviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
        NSString *subSessionId = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
        NSString *trackingSessionId = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        NSString *timeStamp = [Utilities timeStamp];
        NSString *timezone = [self getTimeZone];
        NSString *userId = [self getCurrentUserId];
        NSString *userAgent = [self getUserAgent];

        body =

            @{

                @"EventType" : eventType,

                @"EventName" : eventName,

                @"ErrorCode" : (errorCode) ? errorCode : @"-1",

                @"OffendingURI" : (offendingUrl) ? offendingUrl : @"offendingUrl",

                @"UUID" : (uuid) ? uuid : @"-1",

                @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : @"trackingSessionId",

                @"UserId" : (userId) ? userId : @"-1",

                @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                @"ZipCode" : @"-1",

                @"SubSessionId" : (subSessionId) ? subSessionId : @"subSessionId",

                @"AppType" : @"iOS App",

                @"AppId" : @"Watchable",

                @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                @"TimeZone" : (timezone) ? timezone : @"-1",

                @"UserAgent" : (userAgent) ? userAgent : @"-1",

                @"IsProduction" : isProduction,

                @"DeviceType" : @"iPhone",

                @"ReportFrom" : @"iOS App"

            };
    }
    @catch (NSException *exception)
    {
        NSLog(@"AnalyticsEventBodyException eventname:%@ and eventType :%@  = %@", eventName, eventType, exception);
    }

    return body;
}

- (NSDictionary *)getBodyForSearchEventType:(NSString *)eventType EventName:(NSString *)eventName ipAddress:(NSString *)ipAddress searchQuery:(NSString *)searchQuery andSearchResults:(NSString *)searchResults
{
    NSDictionary *body = nil;

    @try
    {
        NSString *deviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
        NSString *subSessionId = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
        NSString *trackingSessionId = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        NSString *timeStamp = [Utilities timeStamp];
        NSString *timezone = [self getTimeZone];
        NSString *userId = [self getCurrentUserId];
        NSString *userAgent = [self getUserAgent];

        body =

            @{

                @"EventType" : eventType,

                @"EventName" : eventName,

                @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : @"trackingSessionId",

                @"UserId" : (userId) ? userId : @"-1",

                @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                @"ZipCode" : @"-1",

                @"SubSessionId" : (subSessionId) ? subSessionId : @"subSessionId",

                @"AppType" : @"iOS App",

                @"AppId" : @"Watchable",

                @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                @"TimeZone" : (timezone) ? timezone : @"-1",

                @"UserAgent" : (userAgent) ? userAgent : @"-1",

                @"IsProduction" : isProduction,

                @"DeviceType" : @"iPhone",

                @"ReportFrom" : @"iOS App",

                @"SearchQuery" : (searchQuery) ? searchQuery : @"",

                @"SearchResults" : (searchResults) ? searchResults : @""

            };
    }
    @catch (NSException *exception)
    {
        NSLog(@"AnalyticsEventBodyException eventname:%@ and eventType :%@  = %@", eventName, eventType, exception);
    }
    return body;
}

- (NSDictionary *)getBodyForPlayerEventType:(NSString *)eventType
                                  EventName:(NSString *)eventName
                                  ipAddress:(NSString *)ipAddress
                                 playListId:(NSString *)playlistId
                            previousVideoId:(NSString *)previousVideoId
                                    assetId:(NSString *)assetId
                                  channelId:(NSString *)channelId
                             progressMarker:(NSString *)progressMarker
                      andPerceivedBandwidth:(NSString *)bandwith
{
    NSDictionary *body = nil;

    @try
    {
        NSString *deviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
        NSString *subSessionId = [Utilities getValueFromUserDefaultsForKey:kSubSessionId];
        NSString *trackingSessionId = [Utilities getValueFromUserDefaultsForKey:kSessionTrackingId];
        NSString *timeStamp = [Utilities timeStamp];
        NSString *timezone = [self getTimeZone];
        NSString *userId = [self getCurrentUserId];
        NSString *userAgent = [self getUserAgent];

        if ([kEventTypeAd isEqualToString:eventType])
        {
            body =

                @{

                    @"EventType" : eventType,

                    @"EventName" : eventName,

                    @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                    @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : @"trackingSessionId",

                    @"UserId" : (userId) ? userId : @"-1",

                    @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                    @"ZipCode" : @"-1",

                    @"SubSessionId" : (subSessionId) ? subSessionId : @"subSessionId",

                    @"AppType" : @"iOS App",

                    @"AppId" : @"Watchable",

                    @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                    @"TimeZone" : (timezone) ? timezone : @"-1",

                    @"UserAgent" : (userAgent) ? userAgent : @"-1",

                    @"IsProduction" : isProduction,

                    @"DeviceType" : @"iPhone",

                    @"ReportFrom" : @"iOS App",

                    @"AssetId" : (assetId) ? assetId : @"-1",

                    @"ChannelId" : (channelId) ? channelId : @"-1",

                    @"PlaylistId" : (playlistId) ? playlistId : @"-1",

                    @"PreviousVideoId" : (previousVideoId) ? previousVideoId : @"-1",

                    @"PerceivedBandwidth" : (bandwith) ? bandwith : @"-1"

                };
        }
        else
        {
            body =

                @{

                    @"EventType" : eventType,

                    @"EventName" : eventName,

                    @"DeviceId" : (deviceId) ? deviceId : @"deviceId",

                    @"TrackingSessionId" : (trackingSessionId) ? trackingSessionId : @"trackingSessionId",

                    @"UserId" : (userId) ? userId : @"-1",

                    @"IpAddress" : (ipAddress) ? ipAddress : @"-1",

                    @"ZipCode" : @"-1",

                    @"SubSessionId" : (subSessionId) ? subSessionId : @"subSessionId",

                    @"AppType" : @"iOS App",

                    @"AppId" : @"Watchable",

                    @"TimeStamp" : (timeStamp) ? timeStamp : @"-1",

                    @"TimeZone" : (timezone) ? timezone : @"-1",

                    @"UserAgent" : (userAgent) ? userAgent : @"-1",

                    @"IsProduction" : isProduction,

                    @"DeviceType" : @"iPhone",

                    @"ReportFrom" : @"iOS App",

                    @"AssetId" : (assetId) ? assetId : @"-1",

                    @"ChannelId" : (channelId) ? channelId : @"-1",

                    @"PlaylistId" : (playlistId) ? playlistId : @"-1",

                    @"PreviousVideoId" : (previousVideoId) ? previousVideoId : @"-1",

                    @"ProgressMarker" : (progressMarker) ? progressMarker : @"-1",

                    @"PerceivedBandwidth" : (bandwith) ? bandwith : @"-1"

                };
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"AnalyticsEventBodyException eventname:%@ and eventType :%@  = %@", eventName, eventType, exception);
    }

    return body;
}

@end
