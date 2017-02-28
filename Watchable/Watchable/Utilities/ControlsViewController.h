//
//  ControlsViewController.h
//  CustomControls
//
//  Created by Abhilash on 05/29/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCOVPlayerSDK.h"
#import "VideoModel.h"

@protocol ControlsViewControllersDelegate <NSObject>

- (void)handleEnterFullScreenButtonPressed;
- (void)handleExitFullScreenButtonPressed;
- (void)tapedOnPlayer;
- (void)sharePlayingVideo;
- (void)onSuccessfullVideoProgressPostForVideoModel:(NSDictionary *)aDict;
- (void)updateSelectedIndexFollowStatus:(BOOL)followStatus;
- (void)tapedOnInfoButton;
- (void)playNextVideo;
- (void)playPreviousVideo;
- (void)rewindButtonPressedForCurrentVideoModel;

@end

@protocol ControlsViewControllersAdsDelegate <NSObject>

- (void)adsProgressTimeDuration:(float)aDuration;

@end

@interface ControlsViewController : UIViewController <BCOVPlaybackSessionConsumer, UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<ControlsViewControllersDelegate> delegate;
@property (nonatomic, weak) id<ControlsViewControllersAdsDelegate> mBCOVAdsCallBack;
@property (nonatomic, readwrite) BOOL isEntredFullScreen;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *fullscreenButton;
@property (weak, nonatomic) IBOutlet UIButton *playerSkipBack;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mPlayerSkipBackWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *videoShareButton;
@property (weak, nonatomic) IBOutlet UIImageView *PublisherImg;
@property (weak, nonatomic) IBOutlet UILabel *placeholderText;
@property (strong, nonatomic) IBOutlet UIButton *infoButtonForShowingDetailsView;
@property (strong, nonatomic) VideoModel *videoModal;
@property (nonatomic) CGRect cgRectControlsContainer;
@property (nonatomic) CGRect cgRectTopControlView;
@property (nonatomic) long long totalProgress;
@property (strong, nonatomic) NSString *currentlyPlayingVideoPlaylistId;
@property (strong, nonatomic) NSString *previousVideoId;

- (void)hidePlyerControls;
- (void)showPlayerControls;
- (void)setCurrentPlayingVideoId:(NSString *)aVideoId withTimeProgress:(NSString *)aTimeProgress;
- (void)setChannelFollowStatus:(BOOL)isFollow;
- (void)tapDetected:(UIGestureRecognizer *)gestureRecognizer;
- (void)fadeControlsIn;
- (void)fadeControlsOut;
- (void)tooglePlayerControls;
- (void)addObserverForAirPlayConnect;
- (void)setCurrentPlayingVideoDuration:(NSString *)aVideoDuration;
- (void)setProviderImageForUrl:(NSString *)aString;
- (void)removeAllNotification;
- (void)startAdTimer;
- (void)endAd;
- (void)setframeForControls;
- (void)exitFullScrenWhenSignUpAndLogin;

- (IBAction)adPlayPause:(id)sender;
- (IBAction)handlePlayPauseButtonPressed:(UIButton *)sender;

//Guest User

- (void)pauseMoviePlayerWhenFlowWithSignUp;
- (void)PauseAds;

@end
