//
//  AnalyticsEventsHandler.m
//  Watchable
//
//  Created by valtech on 21/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "AnalyticsEventsHandler.h"
#import "AnalyticsEventBodyConstructer.h"
#import "AnalyticsTokens.h"
#import "ServerConnectionSingleton.h"

@implementation AnalyticsEventsHandler

+ (AnalyticsEventsHandler *)sharedInstance
{
    static AnalyticsEventsHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[AnalyticsEventsHandler alloc] init];
    });
    return sharedInstance;
}

- (void)postAnalyticsEventType:(NSString *)eventType eventName:(NSString *)eventName playListId:(NSString *)playlistId channelId:(NSString *)channelId andAssetId:(NSString *)assetId andFromPlaylistPage:(BOOL)isFromPlaylist

{
    [[AnalyticsTokens new] getAnalyticsTokens];
    [[ServerConnectionSingleton sharedInstance] getIPAddressWithResponseBlock:^(NSString *responseString) {

      NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForEventType:eventType EventName:eventName playListId:playlistId ipAddress:responseString channelId:channelId andAsset:assetId andFromPlaylistPage:isFromPlaylist];
      if (body)
      {
          [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                    withResponseBlock:^(NSString *responseString) {

                                                                      NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                    }
                                                                           errorBlock:^(NSError *error){

                                                                           }];
      }

    }
        errorBlock:^(NSError *error) {

          NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForEventType:eventType EventName:eventName playListId:playlistId ipAddress:nil channelId:channelId andAsset:assetId andFromPlaylistPage:isFromPlaylist];

          if (body)
          {
              [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                        withResponseBlock:^(NSString *responseString) {

                                                                          NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                        }
                                                                               errorBlock:^(NSError *error){

                                                                               }];
          }
        }];
}

- (void)postAnalyticsPlayerEventType:(NSString *)eventType
                           eventName:(NSString *)eventName
                          playListId:(NSString *)playlistId
                     previousVideoId:(NSString *)previousVideoId
                           channelId:(NSString *)channelId
                             assetId:(NSString *)assetId
                      progressMarker:(NSString *)progressMarker
               andPerceivedBandwidth:(NSString *)bandwith
                   withResponseBlock:(ResponseBlock)inResponseBlock

{
    if ([previousVideoId isEqualToString:assetId])
    {
        NSLog(@"Asset ID and Previous ID's are same");
    }

    [[AnalyticsTokens new] getAnalyticsTokens];

    [[ServerConnectionSingleton sharedInstance] getIPAddressWithResponseBlock:^(NSString *responseString) {

      NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForPlayerEventType:eventType
                                                                                           EventName:eventName
                                                                                           ipAddress:responseString
                                                                                          playListId:playlistId
                                                                                     previousVideoId:previousVideoId
                                                                                             assetId:assetId
                                                                                           channelId:channelId
                                                                                      progressMarker:progressMarker
                                                                               andPerceivedBandwidth:bandwith];
      if (body)
      {
          [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                    withResponseBlock:^(NSString *responseString) {

                                                                      NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);
                                                                      inResponseBlock(true);

                                                                    }
                                                                           errorBlock:^(NSError *error){

                                                                           }];
      }

    }
        errorBlock:^(NSError *error) {

          NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForPlayerEventType:eventType
                                                                                               EventName:eventName
                                                                                               ipAddress:nil
                                                                                              playListId:playlistId
                                                                                         previousVideoId:previousVideoId
                                                                                                 assetId:assetId
                                                                                               channelId:channelId
                                                                                          progressMarker:progressMarker
                                                                                   andPerceivedBandwidth:bandwith];

          if (body)
          {
              [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                        withResponseBlock:^(NSString *responseString) {

                                                                          NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);
                                                                          inResponseBlock(true);

                                                                        }
                                                                               errorBlock:^(NSError *error){

                                                                               }];
          }

        }];
}

- (void)postAnalyticsGeneralForEventType:(NSString *)eventType eventName:(NSString *)eventName andUserId:(NSString *)userId

{
    [[AnalyticsTokens new] getAnalyticsTokens];

    [[ServerConnectionSingleton sharedInstance] getIPAddressWithResponseBlock:^(NSString *responseString) {

      NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getGeneralBodyForEventType:eventType EventName:eventName userId:userId andIpAddress:responseString];

      if (body)
      {
          [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                    withResponseBlock:^(NSString *responseString) {

                                                                      NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                    }
                                                                           errorBlock:^(NSError *error){

                                                                           }];
      }

    }
        errorBlock:^(NSError *error) {

          NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getGeneralBodyForEventType:eventType EventName:eventName userId:userId andIpAddress:nil];

          if (body)
          {
              [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                        withResponseBlock:^(NSString *responseString) {

                                                                          NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                        }
                                                                               errorBlock:^(NSError *error){

                                                                               }];
          }

        }];
}

- (void)postAnalyticsErrorForEventType:(NSString *)eventType eventName:(NSString *)eventName errorCode:(NSString *)errorCode offendingUrl:(NSString *)offendingUrl andUUID:(NSString *)uuid

{
    [[AnalyticsTokens new] getAnalyticsTokens];
    [[ServerConnectionSingleton sharedInstance] getIPAddressWithResponseBlock:^(NSString *responseString) {

      NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForErrorEventType:eventType EventName:eventName ipAddress:responseString errorCode:errorCode offendingUrl:offendingUrl andUUID:uuid];

      if (body)
      {
          [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                    withResponseBlock:^(NSString *responseString) {

                                                                      NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                    }
                                                                           errorBlock:^(NSError *error){

                                                                           }];
      }

    }
        errorBlock:^(NSError *error) {

          NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForErrorEventType:eventType EventName:eventName ipAddress:nil errorCode:errorCode offendingUrl:offendingUrl andUUID:uuid];

          if (body)
          {
              [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                        withResponseBlock:^(NSString *responseString) {

                                                                          NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                        }
                                                                               errorBlock:^(NSError *error){

                                                                               }];
          }

        }];
}

- (void)postAnalyticsSearchEventType:(NSString *)eventType eventName:(NSString *)eventName searchQuery:(NSString *)searchQuery andSearchResults:(NSString *)searchResults

{
    [[AnalyticsTokens new] getAnalyticsTokens];
    [[ServerConnectionSingleton sharedInstance] getIPAddressWithResponseBlock:^(NSString *responseString) {

      NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForSearchEventType:eventType EventName:eventName ipAddress:responseString searchQuery:searchQuery andSearchResults:searchResults];

      if (body)
      {
          [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                    withResponseBlock:^(NSString *responseString) {

                                                                      NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                    }
                                                                           errorBlock:^(NSError *error){

                                                                           }];
      }

    }
        errorBlock:^(NSError *error) {

          NSDictionary *body = [[AnalyticsEventBodyConstructer sharedInstance] getBodyForSearchEventType:eventType EventName:eventName ipAddress:nil searchQuery:searchQuery andSearchResults:searchResults];

          if (body)
          {
              [[ServerConnectionSingleton sharedInstance] postAnalyticsEventWithEventData:body
                                                                        withResponseBlock:^(NSString *responseString) {

                                                                          NSLog(@"%@ ==>>>>>>>>>>>>>>>>>>> %@", eventName, responseString);

                                                                        }
                                                                               errorBlock:^(NSError *error){

                                                                               }];
          }

        }];
}

@end
