//
//  BrightCovePlayerSingleton.h
//  Watchable
//
//  Created by valtech on 09/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ControlsViewController.h"

@interface BrightCovePlayerSingleton : NSObject <ControlsViewControllersAdsDelegate>

+ (BrightCovePlayerSingleton *)sharedInstance;
- (id)moviePlayer;
+ (void)setMoviePlayerFrame:(CGRect)aFrame;
+ (UIView *)getMoviePlayerView;
+ (void)stopMoviePlayer;
+ (void)playMoviePlayer;
+ (void)playMoviePlayerWithContentURLStr:(NSString *)aStr;
- (BOOL)getIsAdPlaying;
- (void)setIsAdPlaying:(BOOL)isAdPlaying;
- (void)setPlayingAssetId:(NSString *)assetId;
- (void)resumeAdIfNeeded;
+ (void)pauseAd;
- (BOOL)getIsAdPaused;
- (void)setIsAdPaused:(BOOL)isAdPaused;
- (void)stopAdPlay;

- (void)setAdPlayerEventsPlayListID:(NSString *)aplayListID PreviousVideoID:(NSString *)aPreviousVideoID ChannelID:(NSString *)aChannelID AssetID:(NSString *)aAssetID ProgressMarket:(NSString *)aProgressMarker PerceivedBandwidth:(NSString *)aPerceivedbandwidth;

@property (nonatomic, weak) NSString *mplayListId;
@property (nonatomic, weak) NSString *mpreviousVideoId;
@property (nonatomic, weak) NSString *mchannelId;
@property (nonatomic, weak) NSString *massetId;
@property (nonatomic, weak) NSString *mprogressMarker;
@property (nonatomic, weak) NSString *mPerceivedBandwidth;

@end
