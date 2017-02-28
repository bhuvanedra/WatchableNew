//
//  WatchableConstants.m
//  Watchable
//
//  Created by valtech on 07/07/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "WatchableConstants.h"

const NSTimeInterval kSessionTimeoutSec = 1799;
const NSTimeInterval kTrackingSessionTimeoutSec = 21600;
const NSTimeInterval kHeartBeatTimeInterval = 60;
const NSTimeInterval kHistoryPullToRefreshTimeInterval = 30;
const NSTimeInterval kHistoryUpdateDataFetchInterval = 120;

NSString *const kAppStoreUserAccount = @"guestofhelen";
NSString *const kSecretKey = @"9a5901f0-63f9-4938-87cc-7a9b733788c1_3a5a0a7f-3e23-4fb2-9e16-4df426cf2190";
NSString *const kGoogleAnalyticsTrackingId = @"UA-53374959-3";
NSString *const kGoogleAnalyticsUserActionEvent = @"UserAction";

//BaseUrls
//Prod

#ifdef Prod

NSString *const kBaseURL = @"http://fabric.xidio.com";
//NSString *const kAnalyticsBaseURL = @"http://fabric.xidio.com";
NSString *const kAnalyticsBaseURL = @"http://fas.xidio.com";
//NSString *const kAnalyticsBaseURLforSessionIDs = @"http://fabric.xidio.com";
NSString *const kAnalyticsBaseURLforSessionIDs = @"http://fuuids.xidio.com";
NSString *const kZincBaseURL = @"http://fabric.xidio.com";
NSString *const kSecureZincBaseURL = @"https://fabric.xidio.com";
NSString *const kIPAddressUrl = @"http://geoip.watchable.com/json";
NSString *const isProduction = @"yes";

//Swrve Configuration
const int kSwrveAppId = 3438;
NSString *const kSwrveApiKey = @"06xDJN2Vgat9fGhqtuXf";

#else

NSString *const kBaseURL = @"http://zinc.demo.xidio.net";
//NSString *const kAnalyticsBaseURL = @"http://zinc.demo.xidio.net";
NSString *const kAnalyticsBaseURL = @"http://fas.xidio.com";
//NSString *const kAnalyticsBaseURLforSessionIDs = @"http://fabric.xidio.com";
NSString *const kAnalyticsBaseURLforSessionIDs = @"http://fuuids.xidio.com";
NSString *const kZincBaseURL = @"http://zinc.demo.xidio.net";
NSString *const kSecureZincBaseURL = @"https://zinc.demo.xidio.net";
NSString *const kIPAddressUrl = @"https://demoanalytics.xidio.com:1443/json/";
//NSString *const kIPAddressUrl = @"http://demo.ipdetection.xidio.com:8080/json/";
NSString *const isProduction = @"no";

//Swrve Configuration
//Development
const int kSwrveAppId = 3328;
NSString *const kSwrveApiKey = @"J9dXgPFGwrBF8fAhaKE";

//Production- Zinc server
//const int kSwrveAppId = 3438;
//NSString *const kSwrveApiKey = @"06xDJN2Vgat9fGhqtuXf";

#endif

//const BOOL isCoreSpotLightEnable = true;

const BOOL isNewGenreAPIEnable = true;

//NSString *const kAcceptTypeWithVersion =@"application/vnd.fmds.v4+json";
NSString *const kAcceptTypeWithVersion = @"application/json";

NSString *const kAcceptTypeWithVersionForGenre = isNewGenreAPIEnable ? @"application/vnd.fmds.v4+json" : @"application/json";

NSString *const kSwrve_userId_key = @"swrve_user_id";

NSString *const kFabricGroupUrl = @"http://fabricgroup.xidio.com";

NSString *const kFabricHybrid = @"http://fabrichybrid.xidio.com";

//NSString *const kBaseURL = @"http://fabric.xidio.com";
//NSString *const kAnalyticsBaseURL = @"http://fabric.xidio.com";
//NSString *const kZincBaseURL = @"http://fabric.xidio.com";
//NSString *const kSecureZincBaseURL = @"https://fabric.xidio.com";
//NSString *const kIPAddressUrl = @"https://demoanalytics.xidio.com:1443/json/";
//
////NSString *const kAnalyticsBaseURL = @"http://zinc.demo.xidio.net";
////NSString *const kZincBaseURL = @"http://zinc.demo.xidio.net";
////NSString *const kSecureZincBaseURL = @"https://fabricgroup.xidio.com";
////NSString *const kSecureZincBaseURL = @"https://zinc.demo.xidio.net";

//keys
NSString *const kSessionTokenKey = @"SessionToken";
NSString *const kAuthorizationKey = @"Authorization";
NSString *const kSessionTokenSavedDate = @"SessionTokenDate";
NSString *const kCuratedItemKey = @"curatedItem";
NSString *const kCuratedItemsKey = @"curatedItems";
NSString *const kItemKey = @"items";
NSString *const kFabricDeviceIdKey = @"Fabric-Device-Id";

//pathtemplates and uris
NSString *const kURLAuthenticationPathTemplate = @"/fmds/api/watchable/iptv/authenticate";
NSString *const kURLPlayListPathTemplate = @"/fmds/api/watchable/iptv/curatedlists";
NSString *const kURLMyShowsListPathTemplate = @"/fmds/api/watchable/iptv/users/channels/follow";
NSString *const kURLForGenrePathTemplate = @"/fmds/api/watchable/iptv/genres";
NSString *const kURLForFeaturedShowPathTemplate = @"/fmds/api/watchable/iptv/curated/panels/carousal";

NSString *const kLoginURI = @"/fmds/api/watchable/iptv/users/authenticate";
NSString *const kLogoutURI = @"/fmds/api/watchable/iptv/users/logout";
NSString *const kSignUpURI = @"/fmds/api/watchable/iptv/users/profile";
NSString *const kForgotPasswordPathTemplateForEmail = @"/fmds/api/watchable/iptv/users/passwordResetEmail";
NSString *const kForgotPasswordPathTemplateForUsername = @"/fmds/api/watchable/iptv/users/passwordreset/username";
NSString *const kUserHistoryVideoListURL = @"/fmds/api/watchable/iptv/users/viewhistory/videos";
NSString *const kDeleteUserHistoryVideoListURL = @"/fmds/api/watchable/iptv/users/viewhistory/videos";
//NSString *const kPrivatePolicyWebLink = @"http://docs.demo.xidio.com/config/getfooterlinks-html.py?docname=privacy";
//NSString *const kTermsOfServiceWebLink = @"http://docs.demo.xidio.com/config/getfooterlinks-html.py?docname=terms";
NSString *const kPrivatePolicyWebLink = @"http://my.xfinity.com/privacy/";
NSString *const kTermsOfServiceWebLink = @"http://my.xfinity.com/terms/web/";

//notifications
NSString *const kMoviePlayerStopNotification = @"onMoviePlayerStop";
NSString *const kUpdatedHistoryAssetInCoreDataNotification = @"HistoryAssetsUpdated";

//Watchable URL
NSString *const kWatchableURLForShare = @"www.watchable.com";
//NSString *const kFeedBackEmailCc = @"appsupport@watchable.com";
NSString *const kFeedBackEmailId = @"support@watchable.com";

//others
NSString *const kNavTitleFeatured = @"FEATURED";
NSString *const kNavTitleBrowse = @"BROWSE";
NSString *const kNavTitleMyShows = @"MY SHOWS";
NSString *const kNavTitleHistory = @"HISTORY";
NSString *const kNavTitleSettings = @"SETTINGS";
NSString *const kWatchLatestEpisode = @"Watch Latest Video";
NSString *const kUserCredentialBody = @"UserCredentialBody";
NSString *const kYearToSecondsDataFormate = @"YYYY-MM-dd HH:mm:ss";
NSString *const kNumberOfAssetsToFetch = @"10000";
NSString *const kNavTitlePlaylists = @"TODAY'S PLAYLISTS";

//Analytics token keys

NSString *const kSessionTrackingId = @"SessionTrackingId";
NSString *const kSubSessionId = @"SubSessionId";
NSString *const kDeviceId = @"DeviceId";
NSString *const kAnalyticsSessionId = @"AnalyticsSessionId";
NSString *const kSessionTrackingIdSavingDate = @"SessionTrackingIdSavingDate";
NSString *const kAnalyticsSessionIdSavingDate = @"AnalyticsSessionIdSavingDate";
NSString *const kAnalyticsEventPathTemplate = @"/fas/api/event";
NSString *const kTempSessionTrackingId = @"TemSessionTrackingId";
NSString *const kTempSubSessionId = @"TemSubSessionId";

//Analytics EventTypes

NSString *const kEventTypeLifeCycle = @"LifeCycle";
NSString *const kEventTypeHeartBeat = @"HeartBeat";
NSString *const kEventTypeUserAction = @"UserAction";
NSString *const kEventTypePlayer = @"Player";
NSString *const kEventTypeAd = @"Ad";
NSString *const kEventTypeSearch = @"Search";

//Analytics EventNames for Error

NSString *const kEventTypeError = @"Error";
NSString *const kEventNameError = @"error";

//Analytics EventNames for Lifecycle

NSString *const kEventNameAppStart = @"appStart";
NSString *const kEventNameAppEnd = @"appEnd";
NSString *const kEventNameHeartBeat = @"heartBeat";

//Analytics EventNames for UserAction

NSString *const kEventNameTwitterSharingVideo = @"twitterShareVideo";
NSString *const kEventNameFaceBookSharingVideo = @"facebookShareVideo";
NSString *const kEventNameTwitterSharingPlaylist = @"twitterSharePlaylist";
NSString *const kEventNameFaceBookSharingPlaylist = @"facebookSharePlaylist";
NSString *const kEventNameEmailSharingVideo = @"emailShareVideo";
NSString *const kEventNameCopyUrlShareVideo = @"copyUrlShareVideo";
NSString *const kEventNameEmailSharingPlaylist = @"emailSharePlaylist";
NSString *const kEventNameCopyUrlSharePlaylist = @"copyUrlSharePlaylist";
NSString *const kEventNameFollow = @"follow";
NSString *const kEventNameUnFollow = @"unfollow";
NSString *const kEventNameSignIn = @"SignIn";
NSString *const kEventNameSignUp = @"SignUp";
NSString *const kEventNameSignOut = @"Logout";
NSString *const kEventNameUpdatePassword = @"ForgotPassword";

//Analytics EventNames for Ad and Search

NSString *const kEventNameSearch = @"search";
NSString *const kEventNameAdStart = @"adStart";
NSString *const kEventNameAdPause = @"adPause";
NSString *const kEventNameAdend = @"adEnd";

//Analytics EventNames for player

NSString *const kEventNamePlayerPlay = @"play";
NSString *const kEventNamePlayerPause = @"pause";
NSString *const kEventNamePlayerResume = @"resume";
NSString *const kEventNamePlayerProgress = @"progress";
NSString *const kEventNamePlayerEnd = @"end";
NSString *const kEventNamePlayerStart = @"start";
NSString *const kEventNamePlayerRewind = @"rewind";

//Swrve login/Sign up error codes

NSString *const kSUUsernameShort = @"SUUsernameShort";
NSString *const kSUUsernameSpec = @"SUUsernameSpec";
NSString *const kSUUsernameTaken = @"SUUsernameTaken";
NSString *const kSUEmailNotValid = @"SUEmailNotValid";
NSString *const kSUEmailTaken = @"SUEmailTaken";
NSString *const kSUPasswordInvalid = @"SUPasswordInvalid";
NSString *const kSUServerError = @"SUServerError";

NSString *const kLIUserDoesNotExist = @"LIUserDoesNotExist";
NSString *const kLIServerError = @"LIServerError";

//Swrve EventNames

NSString *const kSwrveregisterEnter = @"register.enter";
NSString *const kSwrveregisterStart_sign_up = @"register.start_sign_up";
NSString *const kSwrveregisterFinish_sign_up = @"register.finish_sign_up";
NSString *const kSwrveregisterStart_log_in = @"register.start_log_in";
NSString *const kSwrveregisterFinish_log_in = @"register.finish_log_in";
NSString *const kSwrveregisterTry_without_account = @"register.try_without_account";
NSString *const kSwrveDiagnosticsErrors = @"diagnostics.errors";
NSString *const kSwrveDiagnosticsCannotLogIn = @"diagnostics.cannot_log_in ";

NSString *const kSwrvebrowseEntertainment = @"browse.entertainment";
NSString *const kSwrvebrowseFunny = @"browse.funny";
NSString *const kSwrvebrowseGaming = @"browse.gaming";
NSString *const kSwrvebrowseFashion_and_style = @"browse.fashion_and_style";
NSString *const kSwrvebrowseFood_and_travel = @"browse.food_and_travel";
NSString *const kSwrvebrowseScience_and_tech = @"browse.science_and_tech";
NSString *const kSwrvebrowseNews = @"browse.news";
NSString *const kSwrvebrowseSports = @"browse.sports";
NSString *const kSwrvebrowseAutomotive = @"browse.automotive";
NSString *const kSwrvebrowseMusic = @"browse.music";

NSString *const kSwrvefeedView = @"feed.view";
NSString *const kSwrvefeedFollow = @"feed.follow";
NSString *const kSwrvefeedUnfollow = @"feed.unfollow";
NSString *const kSwrvefeedCannotFollowNotLoggedIn = @"feed.cannot_follow_not_logged_in";
NSString *const kSwrvefeedCannotShareNotLoggedIn = @"feed.cannot_share_not_logged_in";

NSString *const kSwrvevideoWatch = @"video.watch";
NSString *const kSwrvevideoShare = @"video.share";

NSString *const kSwrveplaylistView = @"playlist.view";
NSString *const kSwrveplaylistFollow = @"playlist.follow";
NSString *const kSwrveplaylistUnfollow = @"playlist.unfollow";
NSString *const kSwrveplaylistHome = @"playlist.home";
NSString *const kSwrveplaylistVideoView = @"playlist.video.view";
NSString *const kSwrveHistoryVideoView = @"history.video.view";

//
