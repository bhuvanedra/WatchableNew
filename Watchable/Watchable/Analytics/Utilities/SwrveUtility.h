//
//  SwrveUtility.h
//  Watchable
//
//  Created by Gudkesh Yaduvanshi on 12/8/15.
//  Copyright © 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwrveUtility : NSObject

+ (SwrveUtility *)sharedInstance;
+ (NSDictionary *)getErrorEventPayloadForCode:(NSString *)errorCode;
+ (NSDictionary *)getPayloadforSwrveEventWithAssetTitle:(NSString *)assetTitle
                                                assetId:(NSString *)assetId
                                           channleTitle:(NSString *)channleTitle
                                              channleId:(NSString *)channleId
                                             genreTitle:(NSString *)genreTitle
                                                genreId:(NSString *)genreId
                                         publisherTitle:(NSString *)publisherTitle
                                            publisherId:(NSString *)publisherId
                                          playlistTitle:(NSString *)playlistTitle
                                             playlistId:(NSString *)playlistId;

+ (void)updateSwrveUserProperty:(BOOL)isLoggedIn;

- (void)intializeSwrveSdk;
- (void)postSwrveEvent:(NSString *)eventName;
- (void)postSwrveEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;

@end
