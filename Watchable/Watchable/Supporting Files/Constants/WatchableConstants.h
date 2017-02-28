//
//  WatchableConstants.h
//  Watchable
//
//  Created by valtech on 07/07/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define kSharedApplicationDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]

extern const NSTimeInterval kSessionTimeoutSec;
extern const NSTimeInterval kTrackingSessionTimeoutSec;
extern const NSTimeInterval kHeartBeatTimeInterval;
extern const NSTimeInterval kHistoryPullToRefreshTimeInterval;
extern const NSTimeInterval kHistoryUpdateDataFetchInterval;

extern NSString *const kSecretKey;
extern NSString *const kAppStoreUserAccount;
extern NSString *const kGoogleAnalyticsTrackingId;
extern NSString *const kGoogleAnalyticsUserActionEvent;

//Swrve Configuration
extern const int kSwrveAppId;
extern NSString *const kSwrveApiKey;
extern NSString *const kSwrve_userId_key;

//Swrve login/Sign up error codes

extern NSString *const kSUUsernameShort;
extern NSString *const kSUUsernameSpec;
extern NSString *const kSUUsernameTaken;
extern NSString *const kSUEmailNotValid;
extern NSString *const kSUEmailTaken;
extern NSString *const kSUPasswordInvalid;
extern NSString *const kSUServerError;

extern NSString *const kLIUserDoesNotExist;
extern NSString *const kLIServerError;

//Swrve EventNames

extern NSString *const kSwrveregisterEnter;
extern NSString *const kSwrveregisterStart_sign_up;
extern NSString *const kSwrveregisterFinish_sign_up;
extern NSString *const kSwrveregisterStart_log_in;
extern NSString *const kSwrveregisterFinish_log_in;
extern NSString *const kSwrveregisterTry_without_account;
extern NSString *const kSwrveDiagnosticsErrors;
extern NSString *const kSwrveDiagnosticsCannotLogIn;

extern NSString *const kSwrvebrowseEntertainment;
extern NSString *const kSwrvebrowseFunny;
extern NSString *const kSwrvebrowseGaming;
extern NSString *const kSwrvebrowseFashion_and_style;
extern NSString *const kSwrvebrowseFood_and_travel;
extern NSString *const kSwrvebrowseScience_and_tech;
extern NSString *const kSwrvebrowseNews;
extern NSString *const kSwrvebrowseSports;
extern NSString *const kSwrvebrowseAutomotive;
extern NSString *const kSwrvebrowseMusic;

extern NSString *const kSwrvefeedView;
extern NSString *const kSwrvefeedFollow;
extern NSString *const kSwrvefeedUnfollow;
extern NSString *const kSwrvefeedCannotFollowNotLoggedIn;
extern NSString *const kSwrvefeedCannotShareNotLoggedIn;

extern NSString *const kSwrvevideoWatch;
extern NSString *const kSwrvevideoShare;
extern NSString *const kSwrveplaylistView;

extern NSString *const kSwrveplaylistFollow;
extern NSString *const kSwrveplaylistUnfollow;
extern NSString *const kSwrveplaylistHome;
extern NSString *const kSwrveplaylistVideoView;
extern NSString *const kSwrveHistoryVideoView;

//production base urls
//@"http://fabric.xidio.com"

extern NSString *const kProductionBaseURL;
extern NSString *const kProductionAnalyticsBaseURL;
extern NSString *const kProductionZincBaseURL;
extern NSString *const kProductionSecureZincBaseURL;

// TestBaseUrls
extern NSString *const kBaseURL;
extern NSString *const kAnalyticsBaseURL;
extern NSString *const kAnalyticsBaseURLforSessionIDs;
extern NSString *const kZincBaseURL;
extern NSString *const kSecureZincBaseURL;
extern NSString *const kIPAddressUrl;

//keys
extern NSString *const kSessionTokenKey;
extern NSString *const kAuthorizationKey;
extern NSString *const kSessionTokenSavedDate;
extern NSString *const kCuratedItemKey;
extern NSString *const kCuratedItemsKey;
extern NSString *const kItemKey;
extern NSString *const kFabricDeviceIdKey;

//pathtemplates and uris
extern NSString *const kURLAuthenticationPathTemplate;
extern NSString *const kURLPlayListPathTemplate;
extern NSString *const kURLMyShowsListPathTemplate;
extern NSString *const kURLForGenrePathTemplate;
extern NSString *const kLoginURI;
extern NSString *const kLogoutURI;
extern NSString *const kSignUpURI;
extern NSString *const kForgotPasswordPathTemplateForEmail;
extern NSString *const kForgotPasswordPathTemplateForUsername;
extern NSString *const kUserHistoryVideoListURL;
extern NSString *const kDeleteUserHistoryVideoListURL;
extern NSString *const kPrivatePolicyWebLink;
extern NSString *const kTermsOfServiceWebLink;

extern NSString *const kURLForFeaturedShowPathTemplate;

extern NSString *const kNavTitlePlaylists;
extern NSString *const isProduction;

extern const BOOL isCoreSpotLightEnable;
extern const BOOL isNewGenreAPIEnable;

//notifications
extern NSString *const kMoviePlayerStopNotification;
extern NSString *const kUpdatedHistoryAssetInCoreDataNotification;

//Watchable URL
extern NSString *const kWatchableURLForShare;
extern NSString *const kFeedBackEmailId;
extern NSString *const kFeedBackEmailCc;

//others
extern NSString *const kNavTitleFeatured;
extern NSString *const kNavTitleBrowse;
extern NSString *const kNavTitleMyShows;
extern NSString *const kNavTitleHistory;
extern NSString *const kNavTitleSettings;
extern NSString *const kWatchLatestEpisode;
extern NSString *const kUserCredentialBody;
extern NSString *const kYearToSecondsDataFormate;
extern NSString *const kNumberOfAssetsToFetch;

//Analytics token keys

extern NSString *const kSessionTrackingId;
extern NSString *const kSubSessionId;
extern NSString *const kDeviceId;
extern NSString *const kAnalyticsSessionId;
extern NSString *const kSessionTrackingIdSavingDate;
extern NSString *const kAnalyticsSessionIdSavingDate;
extern NSString *const kAnalyticsEventPathTemplate;
extern NSString *const kTempSessionTrackingId;
extern NSString *const kTempSubSessionId;

//Analytics EventTypes

extern NSString *const kEventTypeLifeCycle;
extern NSString *const kEventTypeHeartBeat;
extern NSString *const kEventTypeUserAction;
extern NSString *const kEventTypePlayer;
extern NSString *const kEventTypeAd;
extern NSString *const kEventTypeSearch;
extern NSString *const kEventTypeError;

//Analytics EventNames for Error

extern NSString *const kEventNameError;

//Analytics EventNames for Lifecycle

extern NSString *const kEventNameAppStart;
extern NSString *const kEventNameAppEnd;
extern NSString *const kEventNameHeartBeat;

//Analytics EventNames for UserAction

extern NSString *const kEventNameTwitterSharingVideo;
extern NSString *const kEventNameFaceBookSharingVideo;
extern NSString *const kEventNameTwitterSharingPlaylist;
extern NSString *const kEventNameFaceBookSharingPlaylist;
extern NSString *const kEventNameEmailSharingVideo;
extern NSString *const kEventNameEmailSharingPlaylist;
extern NSString *const kEventNameCopyUrlShareVideo;
extern NSString *const kEventNameCopyUrlSharePlaylist;
extern NSString *const kEventNameFollow;
extern NSString *const kEventNameUnFollow;
extern NSString *const kEventNameSignIn;
extern NSString *const kEventNameSignUp;
extern NSString *const kEventNameSignOut;
extern NSString *const kEventNameUpdatePassword;

//Analytics EventNames for Ad and Search

extern NSString *const kEventNameSearch;
extern NSString *const kEventNameAdStart;
extern NSString *const kEventNameAdPause;
extern NSString *const kEventNameAdend;

//Analytics EventNames for player

extern NSString *const kEventNamePlayerPlay;
extern NSString *const kEventNamePlayerPause;
extern NSString *const kEventNamePlayerResume;
extern NSString *const kEventNamePlayerProgress;
extern NSString *const kEventNamePlayerEnd;
extern NSString *const kEventNamePlayerStart;
extern NSString *const kEventNamePlayerRewind;

//URL Accept type
extern NSString *const kAcceptTypeWithVersion;
extern NSString *const kAcceptTypeWithVersionForGenre;
//Bitly
extern NSString *const kFabricGroupUrl;
extern NSString *const kFabricHybrid;

typedef enum {
    DefaultType = 0,
    Cover_art,
    Two2One_logo,
    Horizontal_logo,
    Horizontal_lc_logo
} ImageType;

#define kNextVideoUnderChannelPathTemplate(channelId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/channels/%@/videos/next", channelId]

#define kURLVideoForShowIdPathTemplate(showId) [NSString stringWithFormat:@"/api/iptv/shows/%@/videos", showId]

#define kURLChannelForGenrePathPathTemplate(genreId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/genres/%@/channels", genreId]

#define kURLVideoForChannelIdPathTemplate(channelId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/channels/%@/videos", channelId]

#define kURLFollowChannelPathTemplate(channelId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/channels/%@/follow", channelId]

#define kURLChannelForPublisherPathTemplate(apiStr) [NSString stringWithFormat:@"%@/%@", apiStr, @"channels"]

#define kURLPublisherPathTemplate(apiStr) [NSString stringWithFormat:@"%@", apiStr]

//#define kURLGetPlayBackURITemplate(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/videos/%@/playbackuri?videoFormat=MP4&maxBitRate=1000",videoId]

#define kURLGetPlayBackURITemplate(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/videos/%@/playbackuri?videoFormat=MP4", videoId]

#define kURLGetPlayBackURIWithBitRateTemplate(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/videos/%@/playbackuri?videoFormat=MP4&maxBitRate=400", videoId]

#define kURLGetVideoInfo(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/videos/%@", videoId]

#define kValidateSignUpEmailId(emailId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/profiles/emails/%@", emailId]

#define kValidateSignUpUsername(userName) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/profiles/usernames/%@", userName]

#define kURLSearchPathTemplate(searchString) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/search/all/%@", searchString]

#define kDeleteUserHistoryVideoIdURL(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/viewhistory/videos/%@", videoId]

#define kUpdatePlayProgressTimeForVideo(videoId, progressInSeconds) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/videos/%@/%@", videoId, progressInSeconds]

#define kResendConfirmEmailURL(EmailId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/users/resendConfirmEmail?userEmail=%@", EmailId]

#define kURLPostLogData(videoId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/videos/%@/playbackuri", videoId]

#define kGetChannelInfo(channelId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/channels/%@", channelId]

#define kGetBitlyURL(LongURL, ShareData) [NSString stringWithFormat:@"/fbitlys/api/link/transform?longurl=%@&deeplink=%@", LongURL, ShareData]

#define kSwrveBrowseEvent(browseEvent) [NSString stringWithFormat:@"browse.%@", browseEvent]

#define kNavBarMaxAlphaValue 0.9

#define kErrorCodeNotReachable -1009
#define kServerErrorCode -99999
#define kUserNameEmailUnavailableErrorCode -100000
#define kWrongOldPassword -5555

#define kConfirmEmailToastRemovalTime 8

#define kPlayListVideoFetcingForDeeplinkingURL(PlayListId) [NSString stringWithFormat:@"/fmds/api/watchable/iptv/curatedlists/%@", PlayListId]

typedef enum {
    TutorialOverLayScreen = 0,
    TabbarScreenByFollowAction

} eSignUpLoginScreenPresentedFromScreen;

//AppsFlyer
#define kAppsFlyerDevKey @"wz7UUpEvgTH4AfSMxonmnU"
#define kAppsFlyerAppleAppID @"1028781813"

//Deeplinking
#define kDeepLinkingVideoUnAvailable @"The Video which your are looking for is currently not available."
#define kDeepLinkingPlayListUnAvailable @"The PlayList which your are looking for is currently not available."
#define kDeepLinkingShowUnAvailable @"The Show which your are looking for is currently not available."

#define kDeepLinkPlayListIdKey @"playlists"
#define kDeepLinkVideoIdKey @"videos"
#define kDeepLinkShowIdKey @"shows"
#define kDeepLinkScreenIdKey @"screens"

#define kDeepLinkPlaylistScreenValue @"playlists"
#define kDeepLinkGenreScreenValue @"genres"

#define kRobotoBold(fontSize) (UIFont *)[UIFont fontWithName:@"Roboto-Bold" size:fontSize]

#define kRobotoMedium(fontSize) (UIFont *)[UIFont fontWithName:@"Roboto-Medium" size:fontSize]

#define isCoreSpotLightAvaliable ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)

#define isCoreSpotLightEnable (isCoreSpotLightAvaliable ? true : false)

#define kUserId @"userId"
