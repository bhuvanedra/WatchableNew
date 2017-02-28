//
//  BrightCovePlayerSingleton.m
//  Watchable
//
//  Created by valtech on 09/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "BrightCovePlayerSingleton.h"
#import "BCOVPlayerSDKManager.h"
#import "BCOVVideo.h"
#import "BCOVPlaylist.h"
#import "BCOVPlaybackSessionProvider.h"
#import "BCOVCatalogService.h"
#import "BCOVPlaybackSession.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "BCOVPlaybackController.h"
#import <AdManager/FWSDK.h>
#import "BCOVFWSessionProvider.h"
#import "BCOVFWComponent.h"
#import "AnalyticsEventsHandler.h"
#import "WatchableConstants.h"
#import "Utilities.h"

static NSString *const kViewControllerSlotId = @"300x250";

/* For Free Wheel Demo Account Configuration use the below 5 code lines*/

//
//static int const kFreeWheel_NetworkId= 90750;
//static NSString * const kFreeWheel_ServerURL= @"http://demo.v.fwmrm.net";
//static NSString * const kFreeWheel_PlayerProfile= @"90750:3pqa_ios";
//static NSString * const kFreeWheel_SiteSectionID= @"brightcove_ios";
//static NSString * const kFreeWheel_AssetId= @"brightcove_demo_video";

/* For Watchable Production use the below code  5 code lines*/

static int const kFreeWheel_NetworkId = 392025;
static NSString *const kFreeWheel_ServerURL = @"5fb59.v.fwmrm.net";
static NSString *const kFreeWheel_PlayerProfile = @"392025:watchable_ios_prod";
static NSString *const kFreeWheel_SiteSectionID = @"watchable_iphone";
static NSString *const kFreeWheel_SiteSectionIDForAppStore = @"watchable_test_iphone";

//static NSString * const kFreeWheel_SiteSectionID= @"watchables_as3_section_test";
//static NSString * const kFreeWheel_AssetId= @"Watchable_";

static id<BCOVPlaybackController> aMoviePlaybackcontroller = nil;

@interface BrightCovePlayerSingleton () <BCOVPlaybackSessionConsumer>
{
    float adCurrentProgress;
}
@property (nonatomic, weak) id<FWContext> adContext;
@property (nonatomic, strong) id<FWAdManager> adManager;
@property (nonatomic) BOOL videoPlaying;
@property (nonatomic) BOOL adPlaying;
@property (nonatomic) BOOL adPaused;
@property (nonatomic) BOOL playerReady;
@property (nonatomic) BOOL adPlayed;
@property (nonatomic, strong) NSString *currentlyPlayingAssetId;
@property (nonatomic, weak) id<FWSlot> currentSlot;
@property (nonatomic, strong) NSString *assetIdForcurrentlyPlayingAd;
@property (nonatomic, assign) __block BOOL isPlayerLocked;

@end
@implementation BrightCovePlayerSingleton

- (id<FWAdManager>)adManager
{
    // The FWAdManager will be responsible for creating all the ad contexts.
    // We use it in the BCOVFWSessionProviderAdContextPolicy created by
    // the -[ViewController adContextPolicy] block.

    if (_adManager == nil)
    {
        _adManager = newAdManager();
        [_adManager setNetworkId:kFreeWheel_NetworkId];
        [_adManager setServerUrl:kFreeWheel_ServerURL];
    }

    return _adManager;
}

+ (BrightCovePlayerSingleton *)sharedInstance
{
    static BrightCovePlayerSingleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BrightCovePlayerSingleton alloc] init];
      //        [BrightCovePlayerSingleton moviePlayer];

    });
    return sharedInstance;
}

- (void)resumeAdIfNeeded
{
    if (self.adPaused)
    {
        [aMoviePlaybackcontroller resumeAd];
        self.adPlaying = YES;
        self.adPaused = NO;
    }
}

- (id)moviePlayer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

      BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

      aMoviePlaybackcontroller = [manager createFWPlaybackControllerWithAdContextPolicy:[self adContextPolicy] viewStrategy:[manager defaultControlsViewStrategy]];

      //aMoviePlaybackcontroller = [[BCOVPlayerSDKManager sharedManager] createPlaybackController];
      [aMoviePlaybackcontroller addSessionConsumer:self];
      aMoviePlaybackcontroller.autoAdvance = NO;
      aMoviePlaybackcontroller.autoPlay = YES;
      [aMoviePlaybackcontroller setAllowsExternalPlayback:YES];
      self.playerReady = YES;
      self.adPlaying = NO;

      aMoviePlaybackcontroller.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
      [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

      for (UIView *viewMediaPlayer in aMoviePlaybackcontroller.view.subviews)
      {
          NSLog(@"viewMediaPlayer View  in moviePlayer :- %@", viewMediaPlayer);
          if ([viewMediaPlayer isKindOfClass:NSClassFromString(@"BCOVBasicControlsView")])
          {
              NSLog(@"moviePlayer BCOVBasicControlsView viewMediaPlayer View are :- %@", viewMediaPlayer);

              viewMediaPlayer.backgroundColor = [UIColor clearColor];

              for (UIView *subviewMediaPlayer in viewMediaPlayer.subviews)
              {
                  NSLog(@"moviePlayer BCOVBasicControlsView subviewMediaPlayer View are :- %@", viewMediaPlayer);
                  subviewMediaPlayer.hidden = YES;

                  //if(![subviewMediaPlayer isKindOfClass:NSClassFromString(@"MPVolumeView")])
                  {
                      [subviewMediaPlayer removeFromSuperview];
                  }

                  //MPVolumeView

                  //[subviewMediaPlayer removeFromSuperview];
              }
              //[viewMediaPlayer removeFromSuperview];
          }
      }

      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(receiveNotification:)
                                                   name:FW_NOTIFICATION_SLOT_STARTED
                                                 object:nil];

      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(receiveNotification:)
                                                   name:FW_NOTIFICATION_SLOT_ENDED
                                                 object:nil];

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:FW_NOTIFICATION_RENDERER_EVENT object:nil]; // to observe ad impression event

    });
    return aMoviePlaybackcontroller;
}

- (BCOVFWSessionProviderAdContextPolicy)adContextPolicy
{
    BrightCovePlayerSingleton *__weak weakSelf = self;

    return [^id<FWContext>(BCOVVideo *video, BCOVSource *source, NSTimeInterval videoDuration) {
      [BrightCovePlayerSingleton stopMoviePlayer];

      BrightCovePlayerSingleton *strongSelf = weakSelf;
      NSLog(@"********** FW_NOTIFICATION_SLOT_STARTED **********");
      // This block will get called before every session is delivered. The source,
      // video, and videoDuration are provided in case you need to use them to
      // customize the these settings.
      // The values below are specific to this sample app, and should be changed
      // appropriately. For information on what values need to be provided,
      // please refer to your Freewheel documentation or contact your Freewheel
      // account executive. Basic information is provided below.
      id<FWContext> adContext = [strongSelf.adManager newContext];

      // These are player/app specific values.
      [adContext setPlayerProfile:kFreeWheel_PlayerProfile defaultTemporalSlotProfile:nil defaultVideoPlayerSlotProfile:nil defaultSiteSectionSlotProfile:nil];
      NSString *aUsernameOrEmailStr = [[Utilities getValueFromUserDefaultsForKey:@"LoginUserNameOrEmailKey"] lowercaseString];

      NSString *aFreeWheelSiteSectionId = kFreeWheel_SiteSectionID;
      if ([aUsernameOrEmailStr isEqualToString:kAppStoreUserAccount])
      {
          aFreeWheelSiteSectionId = kFreeWheel_SiteSectionIDForAppStore;
      }

      [adContext setSiteSectionId:aFreeWheelSiteSectionId idType:FW_ID_TYPE_CUSTOM pageViewRandom:0 networkId:0 fallbackId:0];

      // This is an asset specific value.
      NSString *playingAssetId = [NSString stringWithFormat:@"Watchable_%@", self.currentlyPlayingAssetId];
      NSLog(@"currentlyPlayingAssetIdForAd self.mCurrentlyPlayingVideoId=%@", playingAssetId);

      [adContext setVideoAssetId:playingAssetId idType:FW_ID_TYPE_CUSTOM duration:videoDuration durationType:FW_VIDEO_ASSET_DURATION_TYPE_EXACT location:nil autoPlayType:true videoPlayRandom:0 networkId:0 fallbackId:0];

      // This is the view where the ads will be rendered.
      [adContext setVideoDisplayBase:aMoviePlaybackcontroller.view];

      // These are required to use Freewheel's OOTB ad controls.
      [adContext setParameter:FW_PARAMETER_USE_CONTROL_PANEL withValue:@"NO" forLevel:FW_PARAMETER_LEVEL_GLOBAL];
      [adContext setParameter:FW_PARAMETER_CLICK_DETECTION withValue:@"NO" forLevel:FW_PARAMETER_LEVEL_GLOBAL];

      // This registers a companion view slot with size 300x250. If you don't
      // need companion ads, this can be removed.
      [adContext addSiteSectionNonTemporalSlot:kViewControllerSlotId adUnit:nil width:300 height:250 slotProfile:nil acceptCompanion:YES initialAdOption:FW_SLOT_OPTION_INITIAL_AD_STAND_ALONE acceptPrimaryContentType:nil acceptContentType:nil compatibleDimensions:nil];

      // We save the adContext to the class so that we can access outside the
      // block. In this case, we will need to retrieve the companion ad slot.
      strongSelf.adContext = adContext;

      return adContext;

    } copy];
}

- (void)receiveNotification:(NSNotification *)notification
{
    if (!self.isPlayerLocked)
    {
        [self stopAdPlay];
        return;
    }

    if ([[notification name] isEqualToString:FW_NOTIFICATION_SLOT_STARTED])
    {
        NSLog(@"********** FW_NOTIFICATION_SLOT_STARTED **********");
        if (self.playerReady)
        {
            self.adPlaying = YES;
            self.adPaused = NO;
            //  [MoviePlayerSingleton removeDefaultControls];

            _currentSlot = [self.adContext getSlotByCustomId:[[notification userInfo] objectForKey:FW_INFO_KEY_CUSTOM_ID]];
            NSTimeInterval slotDuration = [_currentSlot totalDuration];

            NSLog(@"Slot duration: %f", slotDuration);

            if (slotDuration > 0.0)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsAvailable" object:nil userInfo:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayEvent" object:nil userInfo:nil];
            }

            for (UIView *viewMediaPlayer in aMoviePlaybackcontroller.view.subviews)
            {
                // NSLog(@"viewMediaPlayer View are :- %@",viewMediaPlayer);
                if ([viewMediaPlayer isKindOfClass:NSClassFromString(@"BCOVBasicControlsView")])
                {
                    //   NSLog(@"FW_NOTIFICATION_SLOT_STARTED BCOVBasicControlsView viewMediaPlayer View are :- %@",viewMediaPlayer);

                    viewMediaPlayer.hidden = YES;
                    break;
                }
            }

            NSDictionary *userInfo = @{ @"slotDuration" : @(slotDuration) };

            [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsStarted" object:nil userInfo:userInfo];
        }
    }
    else if ([[notification name] isEqualToString:FW_NOTIFICATION_SLOT_ENDED])
    {
        NSLog(@"********** FW_NOTIFICATION_SLOT_ENDED **********");
        if (self.playerReady)
        {
            self.adPlaying = NO;
            self.adPaused = NO;
            //   [MoviePlayerSingleton setDefaultControls];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsEnd" object:nil];

            BOOL isSameAsset = [_currentlyPlayingAssetId isEqualToString:_assetIdForcurrentlyPlayingAd];

            if (_adPlayed && isSameAsset)
            {
                [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypeAd
                                                                            eventName:kEventNameAdend
                                                                           playListId:_mplayListId
                                                                      previousVideoId:_mpreviousVideoId
                                                                            channelId:_mchannelId
                                                                              assetId:_massetId
                                                                       progressMarker:_mprogressMarker
                                                                andPerceivedBandwidth:_mPerceivedBandwidth
                                                                    withResponseBlock:^(BOOL status){

                                                                    }];

                [NSTimer scheduledTimerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(playevent_afterAdd)
                                               userInfo:nil
                                                repeats:NO];
                _adPlayed = NO;
            }
        }
    }
    else if ([[notification name] isEqualToString:FW_NOTIFICATION_RENDERER_EVENT])
    {
        NSLog(@"********** FW_NOTIFICATION_RENDERER_EVENT **********");
        if (self.playerReady)
        {
            NSString *eventName = [[notification userInfo] objectForKey:FW_INFO_KEY_SUB_EVENT_NAME];

            if ([eventName isEqualToString:FW_EVENT_AD_IMPRESSION])
            {
                id<FWAdInstance> adInstance = [[notification userInfo] objectForKey:FW_INFO_KEY_ADINSTANCE];

                NSTimeInterval slotDuration = [adInstance duration];
                NSLog(@"Slot duration FW_NOTIFICATION_RENDERER_EVENT: %f", slotDuration);

                NSDictionary *userInfo = @{ @"slotDuration" : @(slotDuration),
                                            @"CurrentSlot" : (_currentSlot) };

                [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsRenderer" object:nil userInfo:userInfo];
            }

            else if ([eventName isEqualToString:FW_EVENT_AD_BUFFERING_START])
            {
                NSLog(@"FW_EVENT_AD_BUFFERING_STARTED");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsPause" object:nil];
            }
            else if ([eventName isEqualToString:FW_EVENT_AD_BUFFERING_END])
            {
                // Resume the timer
                NSLog(@"FW_EVENT_AD_BUFFERING_ENDED");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsResume" object:nil];
            }
        }
    }
}

- (void)playevent_afterAdd
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayEvent" object:nil userInfo:nil];
}
+ (void)setMoviePlayerFrame:(CGRect)aFrame
{
    aMoviePlaybackcontroller.view.frame = aFrame;
}

+ (void)stopMoviePlayer
{
    [aMoviePlaybackcontroller pause];

    [self pauseAd];
}

- (void)setVideoLocked
{
    self.isPlayerLocked = YES;
}

- (void)stopAdPlay
{
    [aMoviePlaybackcontroller setVideos:nil];
    self.isPlayerLocked = NO;
    [BrightCovePlayerSingleton stopMoviePlayer];
    if (self.adContext)
    {
        NSArray *slotArray = [self.adContext temporalSlots];
        BOOL isAdSlotFound = NO;
        for (id<FWSlot> aSlot in slotArray)
        {
            [aSlot pause];
            [aSlot stop];
            isAdSlotFound = YES;
        }

        if (isAdSlotFound)
        {
            self.adPlaying = NO;
            self.adPaused = NO;
            _adPlayed = NO;

            [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsEnd" object:nil];
        }
    }
}

+ (void)pauseAd
{
    [aMoviePlaybackcontroller pauseAd];
    NSLog(@"aMoviePlaybackcontroller:stopMoviePlayer");

    //if([[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
    [[BrightCovePlayerSingleton sharedInstance] setIsAdPaused:YES];
    // [[BrightCovePlayerSingleton sharedInstance] setIsAdPlaying:NO];
    for (UIView *viewMediaPlayer in aMoviePlaybackcontroller.view.subviews)
    {
        // NSLog(@"stopMoviePlayer viewMediaPlayer View are :- %@",viewMediaPlayer);
        if ([viewMediaPlayer isKindOfClass:NSClassFromString(@"BCOVBasicControlsView")])
        {
            //   NSLog(@"stopMoviePlayer BCOVBasicControlsView viewMediaPlayer View are :- %@",viewMediaPlayer);

            viewMediaPlayer.hidden = YES;
            break;
        }
    }
}

+ (void)playMoviePlayer
{
    for (UIView *viewMediaPlayer in aMoviePlaybackcontroller.view.subviews)
    {
        // NSLog(@"playMoviePlayer viewMediaPlayer View are :- %@",viewMediaPlayer);
        if ([viewMediaPlayer isKindOfClass:NSClassFromString(@"BCOVBasicControlsView")])
        {
            //   NSLog(@"playMoviePlayer BCOVBasicControlsView viewMediaPlayer View are :- %@",viewMediaPlayer);

            viewMediaPlayer.hidden = YES;
            break;
        }
    }
    [aMoviePlaybackcontroller play];
}

+ (void)playMoviePlayerWithContentURLStr:(NSString *)aStr
{
    NSLog(@"call playMoviePlayerWithContentURLStr");
    [[BrightCovePlayerSingleton sharedInstance] setVideoLocked];
    //    [[NSNotificationCenter defaultCenter]postNotificationName:kMoviePlayerStopNotification object:nil];
    if (!aMoviePlaybackcontroller)
    {
        aMoviePlaybackcontroller = [[BrightCovePlayerSingleton sharedInstance] moviePlayer];
    }

    for (UIView *viewMediaPlayer in aMoviePlaybackcontroller.view.subviews)
    {
        //  NSLog(@"viewMediaPlayer View are :- %@",viewMediaPlayer);
        if ([viewMediaPlayer isKindOfClass:NSClassFromString(@"BCOVBasicControlsView")])
        {
            //    NSLog(@"playMoviePlayerWithContentURLStr BCOVBasicControlsView viewMediaPlayer View are :- %@",viewMediaPlayer);

            viewMediaPlayer.hidden = YES;
            break;
        }
    }
    //    NSString *aString=   [[NSBundle mainBundle]pathForResource:@"v1.mp4" ofType:nil];
    //
    //   BOOL aSuccess= [[NSFileManager defaultManager]fileExistsAtPath:aString];
    BCOVVideo *video = nil;
    if (aStr)
    {
        video = [BCOVVideo videoWithURL:[NSURL URLWithString:aStr]];
    }
    else
    {
        video = [BCOVVideo videoWithURL:[NSURL URLWithString:@"http://cilhlsvod-f.akamaihd.net/i/MP4/demo3/2014-09-24/654587_8042_(8042_,R23MP45000,R23MP45000,R23MP44000,R23MP44000,R23MP43000,R23MP43000,R23MP42000,R23MP42000,R23MP41500,R23MP41500,R23MP41000,R23MP41000,R23MP4500,R23MP4500,R23MP4350,R23MP4350,R22MP464,R22MP464,)_v2.mp4.csmil/master.m3u8"]];
    }

    BCOVPlaylist *playlist = [[BCOVPlaylist alloc] initWithVideo:video];
    [aMoviePlaybackcontroller setVideos:playlist];
    [aMoviePlaybackcontroller play];
}

- (void)setIsAdPlaying:(BOOL)isAdPlaying
{
    self.adPlaying = isAdPlaying;
}

- (BOOL)getIsAdPlaying
{
    return self.adPlaying;
}

- (BOOL)getIsAdPaused
{
    return self.adPaused;
}

- (void)setIsAdPaused:(BOOL)isAdPaused
{
    self.adPaused = isAdPaused;
}

- (void)setPlayingAssetId:(NSString *)playingVideoAssetId
{
    if (playingVideoAssetId)
    {
        //NSLog(@"currentlyPlayingAssetId self.mCurrentlyPlayingVideoId=%@",playingVideoAssetId);
        self.currentlyPlayingAssetId = playingVideoAssetId;
    }
}
/*
 -(NSString*)getCurrentlyPlayingAssetId
 {
 return self.currentlyPlayingAssetId ;
 }*/

+ (UIView *)getMoviePlayerView
{
    return aMoviePlaybackcontroller.view;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)adsProgressTimeDuration:(float)aDuration
{
    NSLog(@"Ad-Duration=%f", aDuration);

    if (aDuration > 0.0 && aDuration < 1.2 && aDuration != adCurrentProgress && !_adPlayed)
    {
        [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypeAd
                                                                    eventName:kEventNameAdStart
                                                                   playListId:_mplayListId
                                                              previousVideoId:_mpreviousVideoId
                                                                    channelId:_mchannelId
                                                                      assetId:_massetId
                                                               progressMarker:_mprogressMarker
                                                        andPerceivedBandwidth:_mPerceivedBandwidth
                                                            withResponseBlock:^(BOOL status){

                                                            }];

        _adPlayed = YES;
        adCurrentProgress = aDuration;
        _assetIdForcurrentlyPlayingAd = _currentlyPlayingAssetId;
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session ad:(BCOVAd *)ad didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"++++++playbackSession BCOVAd getIsAdPlaying %f", progress);
}
- (void)setAdPlayerEventsPlayListID:(NSString *)aplayListID PreviousVideoID:(NSString *)aPreviousVideoID ChannelID:(NSString *)aChannelID AssetID:(NSString *)aAssetID ProgressMarket:(NSString *)aProgressMarker PerceivedBandwidth:(NSString *)aPerceivedbandwidth
{
    _mplayListId = aplayListID;
    _mpreviousVideoId = aPreviousVideoID;
    _mchannelId = aChannelID;
    _massetId = aAssetID;
    _mprogressMarker = aProgressMarker;
    _mPerceivedBandwidth = aPerceivedbandwidth;
}
@end
