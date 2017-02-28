//
//  AnalyticsEventBodyConstructer.h
//  Watchable
//
//  Created by valtech on 17/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsEventBodyConstructer : NSObject

+ (AnalyticsEventBodyConstructer *)sharedInstance;

- (NSDictionary *)getBodyForEventType:(NSString *)eventType EventName:(NSString *)eventName playListId:(NSString *)playlistId ipAddress:(NSString *)ipAddress channelId:(NSString *)channelId andAsset:(NSString *)assetId andFromPlaylistPage:(BOOL)isFromPlaylist;

- (NSDictionary *)getBodyForPlayerEventType:(NSString *)eventType
                                  EventName:(NSString *)eventName
                                  ipAddress:(NSString *)ipAddress
                                 playListId:(NSString *)playlistId
                            previousVideoId:(NSString *)previousVideoId
                                    assetId:(NSString *)assetId
                                  channelId:(NSString *)channelId
                             progressMarker:(NSString *)progressMarker
                      andPerceivedBandwidth:(NSString *)bandwith;

- (NSDictionary *)getGeneralBodyForEventType:(NSString *)eventType EventName:(NSString *)eventName userId:(NSString *)userId andIpAddress:(NSString *)ipAddress;

- (NSDictionary *)getBodyForSearchEventType:(NSString *)eventType EventName:(NSString *)eventName ipAddress:(NSString *)ipAddress searchQuery:(NSString *)searchQuery andSearchResults:(NSString *)searchResults;

- (NSDictionary *)getBodyForErrorEventType:(NSString *)eventType EventName:(NSString *)eventName ipAddress:(NSString *)ipAddress errorCode:(NSString *)errorCode offendingUrl:(NSString *)offendingUrl andUUID:(NSString *)uuid;

- (NSString *)platformNiceString;

@end
