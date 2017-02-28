//
//  ServerConnectionSingleton.h
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoModel;
@class PlaylistModel;
@class ChannelModel;
typedef void (^ServerResponseBlock)(NSDictionary *responseDict);
typedef void (^ServerPlaylistResponseBlock)(NSArray *responseArray);
typedef void (^ServerErrorBlock)(NSError *error);
typedef void (^ServerNextVideoResponseBlock)(VideoModel *videoModal);
typedef void (^ServerChannelSubscriptionResponseBlock)(BOOL success);
typedef void (^AnalyticsServerResponseBlock)(NSString *responseString);

typedef void (^ServerResponseBlockForGetPlayListModel)(PlaylistModel *playlistModal);
typedef void (^ServerResponseBlockForGetChannelModel)(ChannelModel *channelModal);

@interface ServerConnectionSingleton : NSObject <NSURLSessionDelegate>
+ (ServerConnectionSingleton *)sharedInstance;

- (void)sendRequestToGetSessionTokenFromServer:(BOOL)shouldFetchFromServer WithresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetPlayListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//TODO:Not in use, need to be removed.
- (void)sendRequestToGetVideoForShowId:(NSString *)aShowId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
//
- (void)sendRequestTogetGenreWithResponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetVideoForPlaylist:(NSString *)videoListUrl withPlayListUniqueId:(NSString *)aPlayListUniqueId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock withPlayListModelResponseBlock:(ServerResponseBlockForGetPlayListModel)inPlayListModelResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//-(void)sendRequestToGetChannelresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forGenreId:(NSString*)genreID withPageNumber:(NSString*)aPageNo;

- (void)sendRequestToGetChannelresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forGenreId:(NSString *)genreID;

- (void)sendRequestToGetVideoForChannelId:(NSString *)aChannelId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)sendRequestToGetChannelForPublisherresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forAPiFormat:(NSString *)apiStr;

- (void)sendRequestToGetPublisherresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forAPiFormat:(NSString *)apiStr;

- (void)sendRequestToGetMyShowListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetMyHistoryListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToDeleteMyHistoryListresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToDeleteMyHistoryVideoId:(NSString *)aVideoId responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetPlaybackURIForVideoId:(NSDictionary *)aVideoInfo responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToAuthenticateUserCrediential:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToSignUpNewUser:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetPasswordResetLinkForEmailId:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToSendConfirmEmail:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetPasswordResetLinkForUsername:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToValidateSignUpEmailId:(NSString *)aEmailId withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToValidateSignUpUserName:(NSString *)aUserName withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetUserProfile:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock withVimondCookie:(BOOL)isVimondCookieNeed;
- (void)sendRequestToGetNextVideoForChannelId:(NSString *)channelId responseBlock:(ServerNextVideoResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestTogetGenreForChannel:(NSString *)genreLink WithResponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//Methods related to channel subscription

- (void)sendrequestToGetSubscriptionStatusForChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)sendrequestToSubscribeChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)sendrequestToUnSubscribeChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)getNewAuthorizationOrSessionTokenWithSelectorForSuccess:(SEL)aSelector withParameter:(NSArray *)aParameterArray isForAuthorization:(BOOL)isAuthorisation;

//Methods related to search

- (void)sendRequestToGetSearchResultForString:(NSString *)searchString withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetChannelInfoWithURL:(NSString *)aRelativeURL responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToGetVideoForVideoId:(NSString *)aVideoId responseBlock:(ServerNextVideoResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToUpdateVideoProgressTime:(NSDictionary *)aDict responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestToUpdateVideoCount:(NSDictionary *)aDict responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)cancelSearchServerAPICall;

//LogOut Method

- (void)sendRequestToLogOutwithResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//update Profile

- (void)sendRequestToUpdateUserProfile:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

// Analytics FAS Methods

- (void)getAnalyticsTrackingSessionIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)getAnalyticsDeviceForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)getAnalyticsSubsessionIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
- (void)getAnalyticsUUIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)postAnalyticsEventWithEventData:(NSDictionary *)eventData withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)getIPAddressWithResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//Getting channelInfo
- (void)sendRequestToGetChannelInfo:(NSString *)aChannelId responseBlock:(ServerResponseBlockForGetChannelModel)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

//bitly
- (void)sendRequestToGetBitlyShareUrl:(NSString *)aShareLongUrl withShareData:(NSString *)aShareData withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;

- (void)sendRequestTogetFeaturedShowWithResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock;
@end
