//
//  ControlsViewController.m
//  CustomControls
//
//  Created by Abhilash on 05/29/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ControlsViewController.h"
#import "BrightCovePlayerSingleton.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIColor+HexColor.h"
#import "ServerConnectionSingleton.h"
#import "Utilities.h"
#import "AnalyticsEventsHandler.h"
#import "WatchableConstants.h"
#import "ImageURIBuilder.h"
#import "UIImageView+WebCache.h"
#import <AdManager/FWSDK.h>
#import "LoginViewController.h"
#import "SignUpViewController.h"
#import "Watchable-Swift.h"

#define AIRPLAY_BUTTON_TAG 1001
// ** Customize these values **
static NSTimeInterval const kViewControllerControlsVisibleDuration = 3.;
static NSTimeInterval const kViewControllerFadeControlsInAnimationDuration = .1;
static NSTimeInterval const kViewControllerFadeControlsOutAnimationDuration = .2;

@interface ControlsViewController ()

@property (nonatomic, weak) AVPlayer *currentPlayer;
@property (nonatomic, weak) IBOutlet UIView *controlsContainer;
@property (nonatomic, weak) IBOutlet UILabel *playheadLabel;
@property (nonatomic, weak) IBOutlet UISlider *playheadSlider;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIView *airplayButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *addPlayList;
@property (strong, nonatomic) IBOutlet UIView *shareButton;
@property (weak, nonatomic) IBOutlet UIView *topControlsView;
@property (weak, nonatomic) IBOutlet UIView *airplayActiveView;
@property (weak, nonatomic) IBOutlet UIView *adOverlay;
@property (weak, nonatomic) IBOutlet UILabel *adTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *adOverlayBottom;
@property (weak, nonatomic) IBOutlet UIButton *adPlayPauseButton;
@property (nonatomic, weak) IBOutlet UISlider *adPlayheadSlider;
@property (strong, nonatomic) GradientView *adGradientView;
@property (strong, nonatomic) GradientView *adGradientViewBottom;
@property (nonatomic, weak) id<FWSlot> currentSlot;
@property (nonatomic, strong) NSTimer *adTimer;
@property (nonatomic) long long sliderQuePoint;
@property (nonatomic) long long progressDifference;

@property (strong, nonatomic) MPVolumeView *airPlayButtonView;
@property (strong, nonatomic) UIButton *airplayButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *durationLabelTrailingSpaceConstraint;

@property (nonatomic, strong) NSTimer *controlTimer;
@property (nonatomic, assign, getter=wasPlayingOnSeek) BOOL playingOnSeek;

@property (nonatomic, strong) NSString *mCurrentlyPlayingVideoId;
@property (nonatomic, strong) NSString *mCurrentlyPlayingVideoProgress;
@property (nonatomic, strong) NSString *mPreviouslyPostedVideoProgress;
@property (nonatomic, strong) NSString *mCurrentlyPlayingVideoDuration;
@property (nonatomic, strong) NSString *mPreviouslyPostedAnalyticsVideoProgress;
@property (nonatomic) NSInteger adRemainingTime;
@property (nonatomic) NSTimeInterval adDuration;
@property (nonatomic) NSInteger adProgress;
@property (nonatomic) BOOL isFromShowPlayerControls;
@property (nonatomic) BOOL isPlayStarted;
@property (nonatomic) BOOL isSliderDragged;
@property (nonatomic) BOOL isSliderDraggEnd;
@property (nonatomic) BOOL isRewindTapped;
@property (nonatomic, strong) NSString *mCurrentPostingVideoId;

- (IBAction)fullScreenCliked:(id)sender;
- (IBAction)shareClicked:(id)sender;
- (IBAction)addToPlayListClicked:(id)sender;
- (IBAction)playPauseActions:(id)sender;
- (IBAction)clickedOnrewind:(id)sender;
- (IBAction)taponInfoButtonForShowingDetailsView:(id)sender;
@end

@implementation ControlsViewController
@synthesize isEntredFullScreen, playPauseButton, fullscreenButton;
@synthesize playerSkipBack, PublisherImg, placeholderText, controlsContainer, airplayActiveView;
@synthesize durationLabelTrailingSpaceConstraint, infoButtonForShowingDetailsView, cgRectTopControlView, cgRectControlsContainer;

#pragma mark BCOVDelegatingSessionConsumerDelegate

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view layoutIfNeeded];

    self.PublisherImg.backgroundColor = [UIColor clearColor];
    self.PublisherImg.contentMode = UIViewContentModeScaleAspectFit;
    // Used for hiding and showing the controls.

    self.topControlsView.userInteractionEnabled = YES;
    self.controlsContainer.userInteractionEnabled = YES;
    self.mPreviouslyPostedAnalyticsVideoProgress = @"-1";
    UIImage *thumbimage = [UIImage imageNamed:@"playScrubber"];
    [self.playheadSlider setThumbImage:thumbimage forState:UIControlStateNormal];
    [self.adPlayheadSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];

    /*[Utilities addGradientToView:self.topControlsView withStartGradientColor:[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0.9] withEndGradientColor:[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0]];
    
    [Utilities addGradientToView:self.controlsContainer withStartGradientColor:[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0] withEndGradientColor:[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0.9]];*/

    GradientView *topGradient = [[GradientView alloc] initWithStartColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.9] endColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0]];

    [self.topControlsView insertSubview:topGradient atIndex:0];

    [self.topControlsView addConstraint:[NSLayoutConstraint constraintWithItem:self.topControlsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topGradient attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.topControlsView addConstraint:[NSLayoutConstraint constraintWithItem:self.topControlsView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:topGradient attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.topControlsView addConstraint:[NSLayoutConstraint constraintWithItem:self.topControlsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:topGradient attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.topControlsView addConstraint:[NSLayoutConstraint constraintWithItem:self.topControlsView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:topGradient attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];

    GradientView *topcontrolsContainer = [[GradientView alloc] initWithStartColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0] endColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.9]];

    [self.controlsContainer insertSubview:topcontrolsContainer atIndex:0];

    [self.controlsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.controlsContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topcontrolsContainer attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.controlsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.controlsContainer attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:topcontrolsContainer attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.controlsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.controlsContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:topcontrolsContainer attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.controlsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.controlsContainer attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:topcontrolsContainer attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];

    //CAGradientLayer *gradientLayer = (CAGradientLayer *)topGradient.layer;
    //[gradientLayer setColors:@[(__bridge id)[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0.9].CGColor,(__bridge id)[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:0].CGColor]];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];

    //Add airplay button view
    self.airPlayButtonView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.airplayButtonContainer.frame), CGRectGetHeight(self.airplayButtonContainer.frame))];
    self.airPlayButtonView.showsRouteButton = YES;
    self.airPlayButtonView.showsVolumeSlider = NO;

    [self.airplayButtonContainer addSubview:self.airPlayButtonView];
    [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPause"] forState:UIControlStateNormal];

    self.addPlayList.hidden = YES;
    //self.videoShareButton.hidden = YES;
    self.PublisherImg.hidden = YES;
    self.placeholderText.hidden = YES;
    self.adOverlayBottom.hidden = YES;

    // UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (statusBarOrientation == UIDeviceOrientationPortrait || statusBarOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        self.mPlayerSkipBackWidthConstraint.constant = 0.0;
    }
    else if (statusBarOrientation == UIDeviceOrientationLandscapeLeft || statusBarOrientation == UIDeviceOrientationLandscapeRight)
    {
        self.mPlayerSkipBackWidthConstraint.constant = 40.0;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(externalScreenDidConnect:)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(externalScreenDidDisconnect:)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startAdTimer)
                                                 name:@"AdsStarted"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endAd)
                                                 name:@"AdsEnd"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adsPause)
                                                 name:@"AdsPause"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adsPlay)
                                                 name:@"AdsResume"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onRendererEvent:)
                                                 name:@"AdsRenderer"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPause)
                                                 name:@"videoPause"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endEventWhenVideoChanged)
                                                 name:@"endEventWhenVideoChanged"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hidePlayEvent)
                                                 name:@"AdsAvailable"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(PlayEvent)
                                                 name:@"PlayEvent"
                                               object:nil];

    [self.adOverlay insertSubview:self.adGradientView atIndex:0];

    [self.adOverlay addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlay attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.adGradientView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.adOverlay addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlay attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.adGradientView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.adOverlay addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlay attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.adGradientView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.adOverlay addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlay attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.adGradientView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    self.adGradientView.hidden = YES;

    self.adPlayPauseButton.hidden = YES;
    self.adPlayheadSlider.hidden = YES;

    [self.adOverlayBottom insertSubview:self.adGradientViewBottom atIndex:0];

    [self.adOverlayBottom addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlayBottom attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.adGradientViewBottom attribute:NSLayoutAttributeTop multiplier:1 constant:0]];

    [self.adOverlayBottom addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlayBottom attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.adGradientViewBottom attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];

    [self.adOverlayBottom addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlayBottom attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.adGradientViewBottom attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.adOverlayBottom addConstraint:[NSLayoutConstraint constraintWithItem:self.adOverlayBottom attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.adGradientViewBottom attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    self.adGradientViewBottom.hidden = YES;

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];

    // Adding the swipe gesture on image view
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
    _isFromShowPlayerControls = NO;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe
{
    //    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
    //        NSLog(@"swipe.direction Left Swipe");
    //        if (self.isEntredFullScreen) {
    //            [_delegate playNextVideo];
    //        }
    //    }
    //
    //    else if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
    //            NSLog(@"swipe.direction Right Swipe");
    //            if (self.isEntredFullScreen) {
    //                [_delegate playPreviousVideo];
    //            }
    //        }
}

- (void)setProviderImageForUrl:(NSString *)aString
{
    __weak ControlsViewController *weakSelf = self;

    NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:aString ForImageType:Horizontal_lc_logo withSize:CGSizeMake(weakSelf.PublisherImg.frame.size.width, weakSelf.PublisherImg.frame.size.height)];

    weakSelf.PublisherImg.backgroundColor = [UIColor clearColor];
    if (providerImageUrlString)
    {
        weakSelf.PublisherImg.contentMode = UIViewContentModeScaleAspectFit;
        [weakSelf.PublisherImg sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                 placeholderImage:nil
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                        }];
    }
    else
    {
        weakSelf.PublisherImg.image = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // if([object isKindOfClass:[UIButton class]] && ((UIButton*)object).tag == AIRPLAY_BUTTON_TAG)
    CGFloat defaultSpacing = 8;
    if ([object isKindOfClass:[UIButton class]] && [[change valueForKey:NSKeyValueChangeNewKey] intValue] == 1 && ((UIButton *)object).tag == AIRPLAY_BUTTON_TAG)
    {
        //NSLog(@"Alpha Value = 1");
        self.durationLabelTrailingSpaceConstraint.constant = defaultSpacing * 2 + CGRectGetWidth(self.airplayButtonContainer.frame);

        AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if ((self.controlsContainer.alpha == 0 || self.controlsContainer.hidden) && self.adOverlayBottom.hidden)
        {
            self.airplayButtonContainer.hidden = YES;
            aAppDelegate.isAirplayConnected = NO;
        }
        else
        {
            self.airplayButtonContainer.hidden = NO;
            aAppDelegate.isAirplayConnected = YES;
        }
    }
    else if ([object isKindOfClass:[UIButton class]] && [[change valueForKey:NSKeyValueChangeNewKey] intValue] == 0 && ((UIButton *)object).tag == AIRPLAY_BUTTON_TAG)
    {
        // NSLog(@"Alpha Value = 0");
        self.durationLabelTrailingSpaceConstraint.constant = defaultSpacing;
    }

    //Update view with animation
    [self.controlsContainer updateConstraints];
    [UIView animateWithDuration:0.3
                     animations:^{
                       [self.controlsContainer layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)addAudioRouteChangeObserver
{
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success)
    {
        NSLog(@"Could not activate audio session for app");
    }

    //Add observer for audio route change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChangeNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];

    if ([self isAirplaySessionActive] && [[UIScreen screens] count] == 1)
    {
        self.airplayActiveView.hidden = NO;
    }
    else
    {
        self.airplayActiveView.hidden = YES;
    }
}

- (void)removeAudioRouteChangeObserver
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&error];

    //remove observer for audio route change
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)audioSessionRouteChangeNotification:(NSNotification *)notification
{
    if ([self isAirplaySessionActive] && [[UIScreen screens] count] == 1)
    {
        self.airplayActiveView.hidden = NO;
    }
    else
    {
        self.airplayActiveView.hidden = YES;
    }
}

- (void)externalScreenDidConnect:(NSNotification *)notification
{
    if ([[UIScreen screens] count] == 1 && [self isAirplaySessionActive])
    {
        self.airplayActiveView.hidden = NO;
    }
    else
    {
        self.airplayActiveView.hidden = YES;
    }
}

- (void)externalScreenDidDisconnect:(NSNotification *)notification
{
    if ([[UIScreen screens] count] == 1 && [self isAirplaySessionActive])
    {
        self.airplayActiveView.hidden = NO;
    }
    else
    {
        self.airplayActiveView.hidden = YES;
    }
}

- (BOOL)isAirplaySessionActive
{
    AVAudioSessionRouteDescription *currentAudioRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *outputAudioPorts = currentAudioRoute.outputs;
    if (outputAudioPorts.count)
    {
        for (AVAudioSessionPortDescription *audioPort in outputAudioPorts)
        {
            if ([audioPort.portType isEqualToString:AVAudioSessionPortAirPlay])
            {
                return YES;
            }
        }
    }

    return NO;
}

- (void)setCurrentPlayingVideoDuration:(NSString *)aVideoDuration
{
    self.mCurrentlyPlayingVideoDuration = aVideoDuration;

    NSLog(@"setCurrentPlayingVideoDuration=%@", aVideoDuration);
}

- (void)setChannelFollowStatus:(BOOL)isFollow
{
    //self.addPlayList.selected=isFollow;
    [self setFollowButtonSelectedMode:isFollow];
}

- (void)setFollowButtonSelectedMode:(BOOL)isSelected
{
    if (isSelected)
    {
        [self.addPlayList setImage:[self.addPlayList imageForState:UIControlStateSelected] forState:UIControlStateNormal];
    }
    else
    {
        UIImage *aFollowNormalImage = [UIImage imageNamed:@"navAdd.png"];
        [self.addPlayList setImage:aFollowNormalImage forState:UIControlStateNormal];
    }
    self.addPlayList.selected = isSelected;
}

- (void)setCurrentPlayingVideoId:(NSString *)aVideoId withTimeProgress:(NSString *)aTimeProgress
{
    self.mCurrentlyPlayingVideoId = aVideoId;
    self.mCurrentlyPlayingVideoProgress = aTimeProgress;
    self.mPreviouslyPostedVideoProgress = @"0";
    NSLog(@"self.mCurrentlyPlayingVideoId=%@", self.mCurrentlyPlayingVideoId);
}

- (void)monitorMovieProgressWithCurrentProgress:(long long)aCurrentProgressTime
{
    // NSLog(@"aCurrentProgressTime=%d",aCurrentProgressTime);
    //__weak ControlsViewController *aWeakSelf=self;

    self.mCurrentlyPlayingVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];

    long long aPreviousPosterProgress = [self.mPreviouslyPostedVideoProgress longLongValue];

    if (aCurrentProgressTime >= aPreviousPosterProgress + 10 || aCurrentProgressTime == 2)
    {
        self.mPreviouslyPostedVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];
        [self postVideoProgressToServerForVideoId:self.mCurrentlyPlayingVideoId withProgressStatus:self.mPreviouslyPostedVideoProgress];
    }

    if (aCurrentProgressTime < aPreviousPosterProgress)
    {
        self.mPreviouslyPostedVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];
    }

    if (aCurrentProgressTime == 7)
    {
        NSLog(@"***********COUNT POST ************* video id=%@", self.videoModal.uniqueId);
        if (self.videoModal && self.mCurrentPostingVideoId != self.videoModal.uniqueId)
        {
            NSLog(@"***********COUNT POSTING *************");
            NSLog(@"mCurrentPostingVideoId=%@ , UNIQU ID=%@", self.mCurrentPostingVideoId, self.videoModal.uniqueId);
            self.mCurrentPostingVideoId = self.videoModal.uniqueId;
            [self postVideoCountToServerForVideoModel:self.videoModal];
        }
    }
}

- (void)postVideoCountToServerForVideoModel:(VideoModel *)aVideoModel
{
    if (aVideoModel.logData)
    {
        NSLog(@"postVideoCountToServerForVideoId %@ WITHLogData=%@", aVideoModel.uniqueId, aVideoModel.logData);
        NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aVideoModel.uniqueId, @"videoId", aVideoModel.logData, @"logData", nil];
        [[ServerConnectionSingleton sharedInstance] sendRequestToUpdateVideoCount:aDict
                                                                    responseBlock:^(NSDictionary *responseDict) {
                                                                      NSLog(@"video count posted successfully");
                                                                    }
                                                                       errorBlock:^(NSError *error){

                                                                       }];
    }
}
- (void)updateAnalyticsPlayerEventForProgress:(NSTimeInterval)timeInterval eventName:(NSString *)eventName updateProgress:(BOOL)upDateProgress
{
    if (self.mCurrentlyPlayingVideoId)
    {
        NSString *progressMarker = [NSString stringWithFormat:@"%lld", (long long)timeInterval];

        BOOL sameProgressMarker = [progressMarker isEqualToString:self.mPreviouslyPostedAnalyticsVideoProgress];

        if (upDateProgress)
        {
            if (((int)timeInterval % 10) == 0)
            {
                self.mPreviouslyPostedAnalyticsVideoProgress = progressMarker;

                if (!sameProgressMarker)
                {
                    NSLog(@"updateAnalyticsPlayerEventForProgress-sEC-1 =%d", (int)timeInterval);
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypePlayer
                                                                                eventName:eventName
                                                                               playListId:_currentlyPlayingVideoPlaylistId
                                                                          previousVideoId:_previousVideoId
                                                                                channelId:_videoModal.channelId
                                                                                  assetId:_videoModal.uniqueId
                                                                           progressMarker:[NSString stringWithFormat:@"%lld", (long long)CMTimeGetSeconds([self.currentPlayer currentTime])]
                                                                    andPerceivedBandwidth:[NSString stringWithFormat:@"%f", [_currentPlayer rate]]
                                                                        withResponseBlock:^(BOOL status){

                                                                        }];

                    [[BrightCovePlayerSingleton sharedInstance] setAdPlayerEventsPlayListID:_currentlyPlayingVideoPlaylistId PreviousVideoID:_previousVideoId ChannelID:_videoModal.channelId AssetID:_videoModal.uniqueId ProgressMarket:[NSString stringWithFormat:@"%lld", (long long)CMTimeGetSeconds([self.currentPlayer currentTime])] PerceivedBandwidth:[NSString stringWithFormat:@"%f", [_currentPlayer rate]]];
                }
            }
        }
        else
        {
            NSLog(@"updateAnalyticsPlayerEventForProgress-eVENT- =%d", (int)timeInterval);
            if (!sameProgressMarker)
            {
                self.mPreviouslyPostedAnalyticsVideoProgress = progressMarker;
                [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypePlayer
                                                                            eventName:eventName
                                                                           playListId:_currentlyPlayingVideoPlaylistId
                                                                      previousVideoId:_previousVideoId
                                                                            channelId:_videoModal.channelId
                                                                              assetId:_videoModal.uniqueId
                                                                       progressMarker:([eventName isEqualToString:kEventNamePlayerPlay]) ? @"0" : [NSString stringWithFormat:@"%lld", (long long)CMTimeGetSeconds([self.currentPlayer currentTime])]
                                                                andPerceivedBandwidth:[NSString stringWithFormat:@"%f", [_currentPlayer rate]]
                                                                    withResponseBlock:^(BOOL status){

                                                                    }];

                [[BrightCovePlayerSingleton sharedInstance] setAdPlayerEventsPlayListID:_currentlyPlayingVideoPlaylistId PreviousVideoID:_previousVideoId ChannelID:_videoModal.channelId AssetID:_videoModal.uniqueId ProgressMarket:([eventName isEqualToString:kEventNamePlayerPlay]) ? @"0" : [NSString stringWithFormat:@"%lld", (long long)CMTimeGetSeconds([self.currentPlayer currentTime])] PerceivedBandwidth:[NSString stringWithFormat:@"%f", [_currentPlayer rate]]];
            }
        }
    }
}

- (void)postVideoProgressToServerForVideoId:(NSString *)aVideoId withProgressStatus:(NSString *)aProgressStatus
{
    if (!aVideoId || (((AppDelegate *)kSharedApplicationDelegate).isGuestUser))
        return;
    NSLog(@"postVideoProgressToServerForVideoId WITHID=%@", aVideoId);
    __weak ControlsViewController *weakSelf = self;

    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aVideoId, @"videoId", aProgressStatus, @"progressTime", nil];
    [[ServerConnectionSingleton sharedInstance] sendRequestToUpdateVideoProgressTime:aDict
                                                                       responseBlock:^(NSDictionary *responseDict) {
                                                                         [weakSelf performSelectorOnMainThread:@selector(onSuccessfullVideoProgressPost:) withObject:responseDict waitUntilDone:NO];
                                                                       }
                                                                          errorBlock:^(NSError *error){

                                                                          }];
}

- (void)onSuccessfullVideoProgressPost:(NSDictionary *)aDict
{
    if ([_delegate respondsToSelector:@selector(onSuccessfullVideoProgressPostForVideoModel:)])
    {
        [_delegate onSuccessfullVideoProgressPostForVideoModel:aDict];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
    //    [self setPlayerFrameInPotraitMode];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self addObserverForAirPlayConnect];
    self.controlsContainer.alpha = 0.f;
    self.topControlsView.alpha = 0.f;
}

- (void)viewDidDisappear:(BOOL)animated
{
    /* @try
    {
        [self.airplayButton removeObserver:self forKeyPath:@"alpha"];
    }
    @catch(NSException *exception)
    {
        
    }*/

    [super viewDidDisappear:animated];
}

- (void)addObserverForAirPlayConnect
{
    @try
    {
        [self.airplayButton removeObserver:self forKeyPath:@"alpha"];
    }
    @catch (NSException *exception)
    {
    }

    for (UIButton *button in self.airPlayButtonView.subviews)
    {
        if ([button isKindOfClass:[UIButton class]])
        {
            [button setTag:AIRPLAY_BUTTON_TAG];
            self.airplayButton = button;

            [self.airplayButton addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
            break;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // [self addObserverForAirPlayConnect];

    //UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    //    NSLog(@"The device orientation=%d",orientation);
    /*
     if(orientation==UIDeviceOrientationPortrait||orientation==UIDeviceOrientationPortraitUpsideDown)
     {
     CGRect frm = [[UIScreen mainScreen] bounds];
     
     CGFloat xAxis = self.playPauseButton.frame.origin.x+self.playPauseButton.frame.size.width+5;
     //    self.playheadSlider.frame = CGRectMake(xAxis, self.playheadSlider.frame.origin.y, self.durationLabel.frame.origin.x - xAxis, self.playheadSlider.frame.size.height);
     
     //        self.playheadSlider.frame = CGRectMake(xAxis, self.playheadSlider.frame.origin.y,frm.size.width- (100+xAxis), self.playheadSlider.frame.size.height);
     
     [self.playheadSlider setFrame:CGRectMake(xAxis, self.playheadSlider.frame.origin.y,frm.size.width- (100+xAxis), self.playheadSlider.frame.size.height)];
     
     self.durationLabel.frame = CGRectMake(self.playheadSlider.frame.origin.x+self.playheadSlider.frame.size.width+12, self.durationLabel.frame.origin.y, self.durationLabel.frame.size.width, self.durationLabel.frame.size.height);
     //self.durationLabel.frame.origin.x+self.durationLabel.frame.size.width+12
     //self.airPlayButton.frame = CGRectMake(self.view.frame.size.width- 40,self.airPlayButton.frame.origin.y,40 ,self.airPlayButton.frame.size.height );
     
     }*/
    [self.view bringSubviewToFront:self.infoButtonForShowingDetailsView];
}
- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.currentPlayer = session.player;
    // Reset State
    self.playingOnSeek = NO;
    //    self.playheadLabel.text = [ControlsViewController formatTime:0];
    self.durationLabel.text = [ControlsViewController formatTime:0];

    self.playheadSlider.value = 0.f;
    self.adPlayheadSlider.value = 0.f;
    [self invalidateTimerAndShowControls];
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration
{
    //    self.durationLabel.text = [ControlsViewController formatTime:duration];
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    self.durationLabel.text = [ControlsViewController formatTime:progress];

    NSTimeInterval duration = CMTimeGetSeconds(session.player.currentItem.duration);
    float percent = progress / duration;
    self.playheadSlider.value = isnan(percent) ? 0.0f : percent;

    long long aProgressTimeInSec = (long long)progress;
    if (aProgressTimeInSec >= 0 && !isnan(progress) && isfinite(progress))
    {
        [self monitorMovieProgressWithCurrentProgress:aProgressTimeInSec];
    }
    //    NSLog(@"++++++playbackSession did move to progress");
    //    if (!self.isPlayStarted && aProgressTimeInSec>=0) {
    //
    //        self.isPlayStarted = YES;
    //        [self updateAnalyticsPlayerEventForProgress:0 eventName:kEventNamePlayerPlay updateProgress:NO];
    //    }

    [self calculateEffectiveProgressOffset:progress];
}

- (void)hidePlayEvent
{
    NSLog(@"Player Play Event Hidden");
}

- (void)PlayEvent
{
    [self updateAnalyticsPlayerEventForProgress:0 eventName:kEventNamePlayerPlay updateProgress:NO];
}

- (void)calculateEffectiveProgressOffset:(NSTimeInterval)progress
{
    if (!isnan(progress) && isfinite(progress))
    {
        if (self.sliderQuePoint == 0 && !self.isSliderDragged)
        {
            if (progress >= 0 && !isnan(progress) && isfinite(progress))
            {
                self.totalProgress = ceil(progress);
            }
        }
        else
        {
            NSLog(@"Dragged");
            if (self.isSliderDraggEnd && self.isRewindTapped)
            {
                self.progressDifference = progress - self.sliderQuePoint;
                self.totalProgress += llabs(self.progressDifference);
                self.sliderQuePoint = progress;
            }
            else if (!self.isRewindTapped && !self.isSliderDraggEnd)
            {
                self.progressDifference = progress - self.sliderQuePoint;
                self.totalProgress += llabs(self.progressDifference);
                self.sliderQuePoint = progress;
            }
        }

        if (self.totalProgress > 0 && progress != [self.mCurrentlyPlayingVideoDuration doubleValue])
        {
            [self updateAnalyticsPlayerEventForProgress:self.totalProgress eventName:kEventNamePlayerProgress updateProgress:YES];
        }

        NSLog(@"totalProgress ===== %lld", self.totalProgress);
    }
}

- (void)endEventWhenVideoChanged
{
    NSTimeInterval progress = CMTimeGetSeconds([self.currentPlayer currentTime]);
    self.isSliderDragged = NO;
    double endOffest = self.totalProgress % 10;
    // Post End Event
    if (endOffest > 0)
    {
        [self updateAnalyticsPlayerEventForProgress:endOffest eventName:kEventNamePlayerEnd updateProgress:NO];
        self.isPlayStarted = NO;
    }
    else
    {
        if (progress >= 0)
        {
            [self updateAnalyticsPlayerEventForProgress:10 eventName:kEventNamePlayerEnd updateProgress:NO];
            self.isPlayStarted = NO;
        }
    }

    self.isSliderDraggEnd = NO;
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // NSTimeInterval progress = CMTimeGetSeconds([self.currentPlayer currentTime]);
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventReady])
    {
        NSLog(@"Ready");
        self.totalProgress = 0;
        //[self updateAnalyticsPlayerEventForProgress:progress  eventName:kEventNamePlayerPlay updateProgress:NO];

        [self pauseVideoAndAdsWhenOverlayPresent];
    }
    else if ([kBCOVPlaybackSessionLifecycleEventPlay isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"++++++kBCOVPlaybackSessionLifecycleEventPlay");
        self.playPauseButton.selected = YES;

        [self reestablishTimer];

        //Add listener for audio route change
        [self addAudioRouteChangeObserver];

        // if (!self.isEntredFullScreen && CGRectIsEmpty(self.cgRectControlsContainer))
        {
            // [self setframeForControls];
        }
    }
    else if ([kBCOVPlaybackSessionLifecycleEventPause isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"++++++kBCOVPlaybackSessionLifecycleEventPause");

        self.playPauseButton.selected = NO;
        [self invalidateTimerAndShowControls];

        if (self.mCurrentlyPlayingVideoProgress)
        {
            int aProgressTime = [self.mCurrentlyPlayingVideoProgress intValue];
            if (aProgressTime >= 2)
                [self postVideoProgressToServerForVideoId:self.mCurrentlyPlayingVideoId withProgressStatus:self.mCurrentlyPlayingVideoProgress];
        }
    }
    else if ([kBCOVPlaybackSessionLifecycleEventEnd isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"++++++kBCOVPlaybackSessionLifecycleEventEnd");
        if (self.mCurrentlyPlayingVideoProgress)
        {
            int aProgressTime = [self.mCurrentlyPlayingVideoProgress intValue];
            if (aProgressTime >= 2)
                [self postVideoProgressToServerForVideoId:self.mCurrentlyPlayingVideoId withProgressStatus:self.mCurrentlyPlayingVideoProgress];

            //Remove listener for audio route change
            [self performSelectorInBackground:@selector(removeAudioRouteChangeObserver) withObject:nil];
        }
        //        if ([self.mCurrentlyPlayingVideoProgress doubleValue]<[self.mCurrentlyPlayingVideoDuration doubleValue]) {
        NSLog(@"the final val=%lld", self.totalProgress);
        self.isPlayStarted = NO;
        double differenceOffset = self.totalProgress % 10;
        // Post End event with progress
        if (differenceOffset > 0)
        {
            [self updateAnalyticsPlayerEventForProgress:differenceOffset eventName:kEventNamePlayerEnd updateProgress:NO];
        }
        else
        {
            [self updateAnalyticsPlayerEventForProgress:10 eventName:kEventNamePlayerEnd updateProgress:NO];
        }

        //        }else{
        //            //Post End event if required with 0 offset
        //        }
    }
    else if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventTerminate])
    {
        NSLog(@"Terminate");
    }
}

#pragma mark IBActions

- (IBAction)handlePlayPauseButtonPressed:(UIButton *)sender
{
    if (sender.selected)
    {
        [self.currentPlayer pause];
        [BrightCovePlayerSingleton stopMoviePlayer];
        [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.currentPlayer play];
        [BrightCovePlayerSingleton playMoviePlayer];
        [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPause.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)handlePlayheadSliderValueChanged:(UISlider *)sender
{
    NSTimeInterval newCurrentTime = sender.value * CMTimeGetSeconds(self.currentPlayer.currentItem.duration);
    //    self.playheadLabel.text = [ControlsViewController formatTime:newCurrentTime];
    self.durationLabel.text = [ControlsViewController formatTime:newCurrentTime];
}

- (IBAction)handlePlayheadSliderValueChangedAd:(UISlider *)sender
{
}

- (IBAction)handlePlayheadSliderTouchBegin:(UISlider *)sender
{
    self.playingOnSeek = self.playPauseButton.selected;
    [self.currentPlayer pause];
    self.isSliderDragged = YES;
    self.isSliderDraggEnd = NO;
    self.isRewindTapped = YES;
}

- (IBAction)handlePlayheadSliderTouchEnd:(UISlider *)sender
{
    self.isSliderDraggEnd = YES;
    NSTimeInterval newCurrentTime = sender.value * CMTimeGetSeconds(self.currentPlayer.currentItem.duration);

    self.sliderQuePoint = newCurrentTime;
    if (fabs([self.mCurrentlyPlayingVideoDuration doubleValue] - newCurrentTime) < 1)
    {
        newCurrentTime = [self.mCurrentlyPlayingVideoDuration doubleValue] - 1;
    }
    CMTime seekToTime = CMTimeMakeWithSeconds(newCurrentTime, 600);
    typeof(self) __weak weakSelf = self;

    [self.currentPlayer seekToTime:seekToTime
                 completionHandler:^(BOOL finished) {

                   typeof(self) strongSelf = weakSelf;

                   if (finished && strongSelf.wasPlayingOnSeek)
                   {
                       strongSelf.playingOnSeek = NO;
                       [strongSelf.currentPlayer play];
                   }
                 }];
}

- (IBAction)handleFullScreenButtonPressed:(UIButton *)sender
{
    if (sender.isSelected)
    {
        sender.selected = NO;
        [self.delegate handleExitFullScreenButtonPressed];
    }
    else
    {
        sender.selected = YES;
        [self.delegate handleEnterFullScreenButtonPressed];
    }
}

#pragma mark Hide/Show Controls

- (void)fadeControlsIn
{
    if (![[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
    {
        [UIView animateWithDuration:kViewControllerFadeControlsInAnimationDuration
            animations:^{

              [self showControls];

            }
            completion:^(BOOL finished) {

              if (finished)
              {
                  [self reestablishTimer];
              }

            }];
    }
}

- (void)fadeControlsOut
{
    [UIView animateWithDuration:kViewControllerFadeControlsOutAnimationDuration
                     animations:^{

                       [self hideControls];

                     }];
}

- (void)hideControls
{
    self.controlsContainer.alpha = 0.f;
    self.topControlsView.alpha = 0.f;

    if ((self.controlsContainer.alpha == 0 || self.controlsContainer.hidden) && self.adOverlayBottom.hidden)
        self.airplayButtonContainer.hidden = YES;
}

- (void)showControls
{
    if (![[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
    {
        self.controlsContainer.alpha = 1.f;
        self.topControlsView.alpha = 1.f;

        if (!(self.adOverlayBottom.hidden) || !(self.adOverlay.hidden))
        {
            [self endAd];
        }
        if (self.airplayButtonContainer.hidden)
            self.airplayButtonContainer.hidden = !self.airplayButtonContainer.hidden;
    }
    else if (!_isFromShowPlayerControls)
    {
        self.adGradientView.hidden = !self.adGradientView.hidden;
        self.adGradientViewBottom.hidden = !self.adGradientViewBottom.hidden;
        self.adPlayPauseButton.hidden = !self.adPlayPauseButton.hidden;
        self.adPlayheadSlider.hidden = !self.adPlayheadSlider.hidden;
        //  self.adOverlay.hidden = !self.adOverlay.hidden;
        self.adOverlayBottom.hidden = !self.adOverlayBottom.hidden;
        _isFromShowPlayerControls = NO;
        //  self.airplayButtonContainer.hidden = !self.airplayButtonContainer.hidden;

        if (self.adOverlayBottom.hidden)
        {
            self.airplayButtonContainer.hidden = YES;
        }
        else
        {
            self.airplayButtonContainer.hidden = NO;
        }
    }

    // if ((!self.isEntredFullScreen) && !(CGRectIsEmpty(self.cgRectControlsContainer)))
    {
        //   [self setframeForControls];
    }

    /*
    if (!self.isEntredFullScreen)
    {
    if(CGRectIsEmpty(self.cgRectControlsContainer))
    {
        self.cgRectControlsContainer = self.controlsContainer.frame;
        self.cgRectTopControlView = self.topControlsView.frame;
    }
    
    if(!(CGRectEqualToRect([self.topControlsView frame],self.cgRectTopControlView)) || !(CGRectEqualToRect([self.controlsContainer frame],self.cgRectControlsContainer)))
    {
        self.controlsContainer.frame = self.cgRectControlsContainer;
        self.topControlsView.frame = self.cgRectTopControlView;

    }
    }*/
}

- (void)setframeForControls
{
    //  [self.controlsContainer updateConstraints];

    [self.controlsContainer layoutIfNeeded];

    // [self.topControlsView updateConstraints];

    [self.topControlsView layoutIfNeeded];

    /*
        if(CGRectIsEmpty(self.cgRectControlsContainer))
        {
            self.cgRectControlsContainer = self.controlsContainer.frame;
            self.cgRectTopControlView = self.topControlsView.frame;
        }
    
    CGRect topRect = [self.topControlsView frame];
    CGRect bottomRect = [self.controlsContainer frame];
        
      //  if(!(CGRectEqualToRect([self.topControlsView frame],self.cgRectTopControlView)) || !(CGRectEqualToRect([self.controlsContainer frame],self.cgRectControlsContainer)))
            
              if(!(CGRectEqualToRect(topRect,self.cgRectTopControlView)) || !(CGRectEqualToRect(bottomRect,self.cgRectControlsContainer)))
        {
           // self.controlsContainer.frame = self.cgRectControlsContainer;
            self.topControlsView.frame = self.cgRectTopControlView;
            
        }
     */
}

- (GradientView *)adGradientView
{
    if (!_adGradientView)
    {
        _adGradientView = [[GradientView alloc] initWithStartColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.9] endColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0]];
    }
    return _adGradientView;
}

- (GradientView *)adGradientViewBottom
{
    if (!_adGradientViewBottom)
    {
        _adGradientViewBottom = [[GradientView alloc] initWithStartColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0] endColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.9]];
    }
    return _adGradientViewBottom;
}

- (void)videoPause
{
    self.playPauseButton.selected = YES;

    if (self.controlTimer)
        [self.controlTimer invalidate];

    if (self.topControlsView.hidden)
    {
        self.topControlsView.hidden = NO;
        self.controlsContainer.hidden = NO;
    }
}
- (void)reestablishTimer
{
    [self.controlTimer invalidate];
    self.controlTimer = [NSTimer scheduledTimerWithTimeInterval:kViewControllerControlsVisibleDuration target:self selector:@selector(fadeControlsOut) userInfo:nil repeats:NO];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // This makes sure that we don't try and hide the controls if someone is pressing any of the buttons
    // or slider.
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UISlider class]])
    {
        return NO;
    }

    return YES;
}

- (void)tapDetected:(UIGestureRecognizer *)gestureRecognizer
{
    [_delegate tapedOnPlayer];
    if (self.playPauseButton.isSelected)
    {
        NSLog(@"self.controlsContainer.alpha : %f", self.controlsContainer.alpha);
        if (self.controlsContainer.alpha == 0.f)
        {
            [self fadeControlsIn];
        }
        else if (self.controlsContainer.alpha == 1.f)
        {
            [self fadeControlsOut];
        }
    }
    else
    {
        [self showControls];
    }
}

- (void)removeAllNotification
{
    @try
    {
        [self.airplayButton removeObserver:self forKeyPath:@"alpha"];
    }
    @catch (NSException *exception)
    {
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)dealloc
{
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];

    [self removeAllNotification];
}

- (IBAction)taponInfoButtonForShowingDetailsView:(id)sender
{
    [_delegate tapedOnInfoButton];
}

- (void)tooglePlayerControls
{
    if (self.playPauseButton.isSelected)
    {
        if (self.controlsContainer.alpha == 0.f)
        {
            [self fadeControlsIn];
        }
        else if (self.controlsContainer.alpha == 1.f)
        {
            [self fadeControlsOut];
        }
    }
    else
    {
        AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (aAppDelegate.isAppEnterBackground)
        {
            [self showPlayerControls];

            if (self.controlsContainer.hidden)
            {
                self.controlsContainer.hidden = NO;
                self.topControlsView.hidden = NO;
            }

            [self.view bringSubviewToFront:self.controlsContainer];
        }
    }
}

- (void)invalidateTimerAndShowControls
{
    [self.controlTimer invalidate];
    [self showControls];
}

#pragma mark Class Methods

+ (NSString *)formatTime:(NSTimeInterval)timeInterval
{
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t once;

    dispatch_once(&once, ^{

      numberFormatter = [[NSNumberFormatter alloc] init];
      numberFormatter.paddingCharacter = @"0";
      numberFormatter.minimumIntegerDigits = 2;

    });

    if (isnan(timeInterval) || !isfinite(timeInterval) || timeInterval == 0)
    {
        return @"00:00";
    }

    NSUInteger hours = floor(timeInterval / 60.0f / 60.0f);
    NSUInteger minutes = (NSUInteger)(timeInterval / 60.0f) % 60;
    NSUInteger seconds = (NSUInteger)timeInterval % 60;

    NSString *formattedMinutes = [numberFormatter stringFromNumber:@(minutes)];
    NSString *formattedSeconds = [numberFormatter stringFromNumber:@(seconds)];

    NSString *ret = nil;
    if (hours > 0)
    {
        ret = [NSString stringWithFormat:@"%@:%@:%@", @(hours), formattedMinutes, formattedSeconds];
    }
    else
    {
        ret = [NSString stringWithFormat:@"%@:%@", formattedMinutes, formattedSeconds];
    }

    return ret;
}

- (IBAction)fullScreenCliked:(id)sender
{
    if (!self.isEntredFullScreen)
    {
        [fullscreenButton setImage:[UIImage imageNamed:@"playerCollapse"] forState:UIControlStateNormal];
        if ([_delegate respondsToSelector:@selector(handleEnterFullScreenButtonPressed)])
        {
            [_delegate handleEnterFullScreenButtonPressed];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    }
    else
    {
        [fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];
        if ([_delegate respondsToSelector:@selector(handleExitFullScreenButtonPressed)])
        {
            [_delegate handleExitFullScreenButtonPressed];
            //            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];//abk
        }
    }
}

- (void)exitFullScrenWhenSignUpAndLogin
{
    [fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];
    if ([_delegate respondsToSelector:@selector(handleExitFullScreenButtonPressed)])
    {
        [_delegate handleExitFullScreenButtonPressed];
        //            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];//abk
    }
}

- (IBAction)shareClicked:(id)sender
{
    if ([_delegate respondsToSelector:@selector(sharePlayingVideo)])
    {
        [_delegate sharePlayingVideo];
    }
}

- (IBAction)addToPlayListClicked:(id)sender
{
    if ([_delegate respondsToSelector:@selector(updateSelectedIndexFollowStatus:)])
    {
        [_delegate updateSelectedIndexFollowStatus:!self.addPlayList.isSelected];
    }
}

- (IBAction)playPauseActions:(id)sender
{
}

- (IBAction)clickedOnrewind:(id)sender
{
    if (self.videoModal)
    {
        if ([_delegate respondsToSelector:@selector(rewindButtonPressedForCurrentVideoModel)])
        {
            [_delegate rewindButtonPressedForCurrentVideoModel];
        }
    }
    //NSTimeInterval newCurrentTime = (self.playheadSlider.value >0.15? self.playheadSlider.value-0.10:0) * CMTimeGetSeconds(self.currentPlayer.currentItem.duration);
    //[self.currentPlayer pause];
    self.isSliderDragged = YES;
    self.isSliderDraggEnd = NO;
    self.isRewindTapped = YES;
    CMTime seekToTime = CMTimeMakeWithSeconds(0, 600);

    [self performSelector:@selector(updateSliderQuePoint) withObject:nil afterDelay:0];

    if (CMTimeGetSeconds(self.currentPlayer.currentItem.currentTime) > 15)
    {
        NSTimeInterval newCurrentTime = CMTimeGetSeconds(self.currentPlayer.currentItem.currentTime) - 10.0;
        seekToTime = CMTimeMakeWithSeconds(newCurrentTime, 600);
    }

    typeof(self) __weak weakSelf = self;

    [self.currentPlayer seekToTime:seekToTime
                 completionHandler:^(BOOL finished) {

                   NSTimeInterval progress = CMTimeGetSeconds([self.currentPlayer currentTime]);
                   [self updateAnalyticsPlayerEventForProgress:progress eventName:kEventNamePlayerRewind updateProgress:NO];
                   typeof(self) strongSelf = weakSelf;
                   if (finished)
                   {
                       self.isRewindTapped = NO;
                   }
                   if (finished && strongSelf.wasPlayingOnSeek)
                   {
                       strongSelf.playingOnSeek = NO;
                       [strongSelf.currentPlayer play];
                   }
                 }];
}

- (void)updateSliderQuePoint
{
    NSTimeInterval newCurrentTimeForAnalytics = CMTimeGetSeconds(self.currentPlayer.currentItem.currentTime) - 10.0;

    if (newCurrentTimeForAnalytics <= 0)
    {
        self.sliderQuePoint = 0;
    }
    else
    {
        self.sliderQuePoint = newCurrentTimeForAnalytics;
    }
}

- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation != UIDeviceOrientationUnknown && orientation != UIDeviceOrientationFaceUp && orientation != UIDeviceOrientationFaceDown)
    {
        //            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];//abk

        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
        {
            self.addPlayList.hidden = NO;
            self.videoShareButton.hidden = NO;
            self.playerSkipBack.hidden = NO;
            self.PublisherImg.hidden = NO;
            self.placeholderText.hidden = NO;
            self.mPlayerSkipBackWidthConstraint.constant = 40.0;
            self.infoButtonForShowingDetailsView.hidden = YES;

            // if(![[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
            // [self showPlayerControls];

            CGFloat xAxis = self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width + 65;
            self.playheadSlider.frame = CGRectMake(xAxis, self.playheadSlider.frame.origin.y, self.durationLabel.frame.origin.x - xAxis, self.playheadSlider.frame.size.height);
        }
        else
        {
            CGFloat xAxis = self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width + 5;
            self.playheadSlider.frame = CGRectMake(xAxis, self.playheadSlider.frame.origin.y, self.durationLabel.frame.origin.x - xAxis, self.playheadSlider.frame.size.height);
            //                [self setPlayerFrameInPotraitMode];
            self.addPlayList.hidden = YES;
            //self.videoShareButton.hidden = YES;
            self.playerSkipBack.hidden = YES;
            self.PublisherImg.hidden = YES;
            self.placeholderText.hidden = YES;

            self.mPlayerSkipBackWidthConstraint.constant = 0.0;
        }
    }

    NSArray *aArray = ((AppDelegate *)kSharedApplicationDelegate).window.subviews;
    for (UIView *aView in aArray)
    {
        if ([aView isMemberOfClass:[SignUpLoginOverLayView class]])
        {
            return;
        }
    }

    UIViewController *presentedVc = self.presentedViewController;
    if ([presentedVc isMemberOfClass:[UINavigationController class]])
    {
        UINavigationController *navCntlr = (UINavigationController *)presentedVc;
        UIViewController *vc = [[navCntlr viewControllers] objectAtIndex:0];

        if ([vc isMemberOfClass:[LoginViewController class]])
        {
            return;
        }
    }
    else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
    {
        return;
    }
}
- (void)hidePlyerControls
{
    self.topControlsView.hidden = YES;
    self.controlsContainer.hidden = YES;

    if ((self.controlsContainer.alpha == 0 || self.controlsContainer.hidden) && self.adOverlayBottom.hidden)
        self.airplayButtonContainer.hidden = YES;
}
- (void)showPlayerControls
{
    if (![[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
    {
        self.topControlsView.hidden = NO;
        self.controlsContainer.hidden = NO;

        if (!(self.adOverlayBottom.hidden) || !(self.adOverlay.hidden))
        {
            [self endAd];
        }
        if (self.airplayButtonContainer.hidden)
            self.airplayButtonContainer.hidden = !self.airplayButtonContainer.hidden;
    }
    else
    {
        _isFromShowPlayerControls = YES;

        self.adGradientView.hidden = !self.adGradientView.hidden;
        self.adGradientViewBottom.hidden = !self.adGradientViewBottom.hidden;
        self.adPlayPauseButton.hidden = !self.adPlayPauseButton.hidden;
        self.adPlayheadSlider.hidden = !self.adPlayheadSlider.hidden;
        //  self.adOverlay.hidden = !self.adOverlay.hidden;
        self.adOverlayBottom.hidden = !self.adOverlayBottom.hidden;
        // self.airplayButtonContainer.hidden = !self.airplayButtonContainer.hidden;

        if (self.adOverlayBottom.hidden)
        {
            self.airplayButtonContainer.hidden = YES;
        }
        else
        {
            self.airplayButtonContainer.hidden = NO;
        }
    }
    //if ((!self.isEntredFullScreen) && !(CGRectIsEmpty(self.cgRectControlsContainer)))
    {
        //[self setframeForControls];
    }
}

- (void)startAdTimer
{
    [self hidePlyerControls];
}

- (void)endAd
{
    self.adPlayPauseButton.hidden = YES;
    self.adPlayheadSlider.hidden = YES;

    [self.adOverlay setHidden:YES];
    [self.adOverlayBottom setHidden:YES];
    [self.airplayButtonContainer setHidden:YES];
    if (self.adTimer)
        [self.adTimer invalidate];
}

- (void)updateAdsProgress
{
    if (self.adRemainingTime > 0)
    {
        [self pauseVideoAndAdsWhenOverlayPresent];
        //self.adTimeLabel.text = [NSString stringWithFormat:@"Ad: %lds",(long)self.adRemainingTime];
        //--self.adRemainingTime;
        //self.adProgress++;
        float aAdProgress = [self.currentSlot playheadTime];
        self.adRemainingTime = self.adDuration - aAdProgress;
        self.adTimeLabel.text = [NSString stringWithFormat:@"Ad: %lds", (long)self.adRemainingTime];

        float percent = [self.currentSlot playheadTime] / self.adDuration;

        self.adPlayheadSlider.value = isnan(percent) ? 0.0f : percent;

        if ([[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
        {
            self.adPlayheadSlider.value = isnan(percent) ? 0.0f : percent;
            NSLog(@"++++++playbackSession did move to progress; getIsAdPlaying %ld", (long)self.adProgress);
            if ([self.mBCOVAdsCallBack respondsToSelector:@selector(adsProgressTimeDuration:)])
            {
                [self.mBCOVAdsCallBack adsProgressTimeDuration:aAdProgress];
            }
        }
    }
    else
    {
        [self endAd];
    }
}

- (void)onRendererEvent:(NSNotification *)notification
{
    NSDictionary *userInfoFromSlot = notification.userInfo;
    NSTimeInterval slotDuration = [userInfoFromSlot[@"slotDuration"] doubleValue];
    self.currentSlot = userInfoFromSlot[@"CurrentSlot"];

    NSLog(@"Slot duration startAdTimer: %f", slotDuration);

    self.adRemainingTime = slotDuration;
    self.adDuration = slotDuration;
    self.adProgress = 0;
    if (self.adTimer)
    {
        [self.adTimer invalidate];
    }
    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateAdsProgress) userInfo:nil repeats:YES];
    [self.adOverlay setHidden:NO];

    if (self.adOverlayBottom.hidden)
    {
        self.airplayButtonContainer.hidden = true;
    }
    else
    {
        self.airplayButtonContainer.hidden = false;
    }

    [self hidePlyerControls];
}

- (void)adsPause
{
    if (self.adTimer)
    {
        [self.adTimer invalidate];
    }
    [self.adPlayPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay.png"] forState:UIControlStateNormal];
}

- (void)adsPlay
{
    if (self.adTimer)
    {
        [self.adTimer invalidate];
    }
    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateAdsProgress) userInfo:nil repeats:YES];

    [self.adPlayPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPause.png"] forState:UIControlStateNormal];
}

- (IBAction)adPlayPause:(id)sender
{
    if (![[BrightCovePlayerSingleton sharedInstance] getIsAdPaused])
    {
        if (self.adTimer)
        {
            [self.adTimer invalidate];
        }
        [self.adPlayPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay.png"] forState:UIControlStateNormal];

        [BrightCovePlayerSingleton pauseAd];
    }
    else
    {
        [self adsPlay];

        [[BrightCovePlayerSingleton sharedInstance] resumeAdIfNeeded];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session ad:(BCOVAd *)ad didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"++++++playbackSession BCOVAd getIsAdPlaying %f", progress);
}

#pragma mark GuestUser

- (void)pauseMoviePlayerWhenFlowWithSignUp
{
    [self.currentPlayer pause];
    [BrightCovePlayerSingleton stopMoviePlayer];
    [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay.png"] forState:UIControlStateNormal];
}

- (void)PauseAds
{
    if (![[BrightCovePlayerSingleton sharedInstance] getIsAdPaused])
    {
        if (self.adTimer)
        {
            [self.adTimer invalidate];
        }
        [self.adPlayPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay.png"] forState:UIControlStateNormal];

        [BrightCovePlayerSingleton pauseAd];
    }
}

- (void)pauseMoviePlayer
{
    BOOL isAddPlaying = [[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying];

    if (isAddPlaying)
    {
        [self PauseAds];
    }
    else
    {
        [self pauseMoviePlayerWhenFlowWithSignUp];
    }
}

- (void)pauseVideoAndAdsWhenOverlayPresent
{
    NSArray *aArray = ((AppDelegate *)kSharedApplicationDelegate).window.subviews;
    for (UIView *aView in aArray)
    {
        if ([aView isMemberOfClass:[SignUpLoginOverLayView class]])
        {
            [self pauseMoviePlayer];
        }
    }

    UIViewController *presentedVc = self.presentedViewController;
    if ([presentedVc isMemberOfClass:[UINavigationController class]])
    {
        UINavigationController *navCntlr = (UINavigationController *)presentedVc;
        UIViewController *vc = [[navCntlr viewControllers] objectAtIndex:0];

        if ([vc isMemberOfClass:[LoginViewController class]])
        {
            [self pauseMoviePlayer];
        }
    }
    else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
    {
        [self pauseMoviePlayer];
    }
}

@end
