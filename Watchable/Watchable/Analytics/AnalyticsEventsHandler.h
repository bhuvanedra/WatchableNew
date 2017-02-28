//
//  AnalyticsEventsHandler.h
//  Watchable
//
//  Created by valtech on 21/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResponseBlock)(BOOL status);
@interface AnalyticsEventsHandler : NSObject
+ (AnalyticsEventsHandler *)sharedInstance;

- (void)postAnalyticsEventType:(NSString *)eventType eventName:(NSString *)eventName playListId:(NSString *)playlistId channelId:(NSString *)channelId andAssetId:(NSString *)assetId andFromPlaylistPage:(BOOL)isFromPlaylist;

- (void)postAnalyticsPlayerEventType:(NSString *)eventType
                           eventName:(NSString *)eventName
                          playListId:(NSString *)playlistId
                     previousVideoId:(NSString *)previousVideoId
                           channelId:(NSString *)channelId
                             assetId:(NSString *)assetId
                      progressMarker:(NSString *)progressMarker
               andPerceivedBandwidth:(NSString *)bandwith
                   withResponseBlock:(ResponseBlock)inResponseBlock;

- (void)postAnalyticsGeneralForEventType:(NSString *)eventType eventName:(NSString *)eventName andUserId:(NSString *)userId;

- (void)postAnalyticsErrorForEventType:(NSString *)eventType eventName:(NSString *)eventName errorCode:(NSString *)errorCode offendingUrl:(NSString *)offendingUrl andUUID:(NSString *)uuid;

- (void)postAnalyticsSearchEventType:(NSString *)eventType eventName:(NSString *)eventName searchQuery:(NSString *)searchQuery andSearchResults:(NSString *)searchResults;
@end
