//
//  PlayDetailViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 03/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PlayDetailViewController.h"

#import "AnalyticsEventsHandler.h"
#import "BrightCovePlayerSingleton.h"
#import "ChannelModel.h"
#import "ControlsViewController.h"
#import "CustomActivityItemProviderForSharing.h"
#import "DBHandler.h"
#import "GAUtilities.h"
#import "GenreModel.h"
#import "ImageURIBuilder.h"
#import "LoginViewController.h"
#import "MoviePlayerSingleton.h"
#import "PlayDetailCollectionViewCell.h"
#import "PlayDetailFirstCollectionViewCell.h"
#import "PlayGenreGenreFirstCollectionViewCell.h"
#import "PlaylistModel.h"
#import "ProviderDetailViewController.h"
#import "ProviderModel.h"
#import "ServerConnectionSingleton.h"
#import "ShowModel.h"
#import "SignUpViewController.h"
#import "SwrveUtility.h"
#import "TimeUtils.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"
#import "VideoModel.h"
#import "Watchable-Swift.h"
#import "WatchableConstants.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define kFullVideoScreenErrorViewTag 1000
#define kVideoPlayerYaxisDelta 0
#define kVideoPlayerHeightDelta 2

#define kAttentionImageViewTag 1111
#define kVideoFailedtoLoadLabelTag 1112
#define kVideoFailedtoLoadTryAgainBtnTag 1113

@interface PlayDetailViewController () <UIScrollViewDelegate, UICollectionViewDelegate, ControlsViewControllersDelegate, BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) NSMutableArray *mVideoListDataSource;

@property (weak, nonatomic) IBOutlet UICollectionView *mCollectionView;
@property (strong, nonatomic) NSIndexPath *mSelectedIndexPath;
@property (nonatomic, strong) NSMutableSet *mVisibleCells;
@property (nonatomic, assign) BOOL isVideoLocked;
@property (nonatomic, assign) BOOL isVideoLockedRef;
@property (nonatomic, assign) BOOL canSelectCell;
@property (nonatomic, assign) float videoLockedScrollViewContentOffSetYAxis;
//@property (nonatomic,strong) MoviePlayerSingleton *mMoviePlayer;
@property (nonatomic, strong) VideoDetailView *mDetailView;
@property (nonatomic, strong) UIButton *mVideoDetailHideButton;
@property (nonatomic, assign) BOOL isMoviePlayerInFullScreen;
@property (nonatomic, assign) BOOL canChangeToLandScape;
@property (nonatomic, strong) NSMutableArray *mFetchingVideoIndexPathArray;
@property (nonatomic, strong) UIButton *mAddFollowButton;
@property (nonatomic, strong) UIView *mVideoLoadingFailureView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) ControlsViewController *controlsViewController;
@property (nonatomic, strong) UIViewController *fullscreenViewController;
@property (nonatomic, assign) PlayDetailCollectionViewCell *currentCell;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BrightCovePlayerSingleton *mBrightPlayer;
@property (nonatomic, assign) BOOL isfullscreenViewControllerPresented;
@property (nonatomic, strong) __block NSString *mCurrentlyPlayingVideoId;
@property (nonatomic, strong) __block NSString *mCurrentlyPlayingVideoProgress;
@property (nonatomic, strong) __block NSString *mPreviouslyPostedVideoProgress;
@property (nonatomic, strong) NSTimer *mVideoProgressTimer;
@property (nonatomic, strong) UIActivityViewController *mActivityViewController;
@property (nonatomic) UIDeviceOrientation currentOrientation;
@property (nonatomic, assign) BOOL isSelectedCellDetailsDimmed;
@property (nonatomic, strong) NSMutableArray *mChannelIDForFetchingChannelLogoArray;

@property (nonatomic) CGRect cgRectVideoView;
@property (nonatomic) CGRect cgRectVideoViewFullScreen;

@property (nonatomic, strong) VideoModel *previouslyPlayedVideo;
@property (nonatomic, assign) float mCollectionViewContentOffsetHeight;
@property (nonatomic, assign) BOOL isCollectionViewContentOffsetHeightAdded;
//@property (nonatomic,assign) CGPoint mDraggedPoint;
@property (nonatomic, strong) VideoModel *mClickedVideoModelShowLogo; //used forGA

@property (nonatomic, strong) UIView *mDeepLinkErrorView;

@property (nonatomic, weak) UIButton *mViewBackButton;
@property (nonatomic, weak) UIButton *mNavBarBackButton;
@property (nonatomic, assign) NSInteger mPreviousVideoPlayIndex;
@property (nonatomic, assign) BOOL isViewDisappeared;

@property (nonatomic, assign) float mScrollHeightForBreakLock;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic) UIStatusBarAnimation stausBarAnimation;
@end

@implementation PlayDetailViewController

- (BOOL)isPlayListVideoListDataSourceAvaliable
{
    if (self.mVideoListDataSource.count)
    {
        return true;
    }

    return false;
}

- (BOOL)isChannelVideoListDataSourceAvaliable
{
    if (self.mVideoListDataSource.count)
    {
        return true;
    }

    return false;
}

- (NSUInteger)getDataSourceVideoIdIndex:(NSString *)aVideoId
{
    __weak PlayDetailViewController *weakSelf = self;
    __block NSUInteger aIndex = -1;
    [weakSelf.mVideoListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      VideoModel *aVideoModel = (VideoModel *)obj;
      if ([aVideoModel.uniqueId isEqualToString:aVideoId])
      {
          aIndex = idx;
          *stop = YES;
      }

    }];

    return aIndex;
}

- (PlayDetailCollectionViewCell *)currentCell
{
    PlayDetailCollectionViewCell *aPlayDetailCollectionViewCell = nil;
    if (self.mSelectedIndexPath)
    {
        aPlayDetailCollectionViewCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];
    }
    return aPlayDetailCollectionViewCell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    self.isViewDisappeared = NO;
    self.isFetchPlayBackURIWithMaxBitRate = YES;
    self.mPreviousVideoPlayIndex = -1;
    self.isCollectionViewContentOffsetHeightAdded = NO;
    self.currentOrientation = UIDeviceOrientationPortrait;
    [self setupBCOVPlayer];

    //_playbackController.delegate = self;
    if (self.isEpisodeClicked || self.isLogoClicked)
    {
        self.isFromGenre = YES;
        if (self.mChannelDataModel)
        {
            [self getDataFromServer];
        }
        else if (self.mVideoModel.channelInfo)
        {
            self.mChannelDataModel = self.mVideoModel.channelInfo;
            self.mChannelDataModel.nextVideoUnderchannel = self.mVideoModel;
            [self getDataFromServer];
        }
        else
        {
            [self getChannelInfoForSelectedVideo];
        }
    }
    else
    {
        [self getDataFromServer];
    }
    [self initialSetUp];
    [self addNotificationForMoviePlayerRotation];
    [self addNotificationForFollowChannel];

    if ((self.isFromSearch || (self.isFromGenre && !self.mChannelDataModel.isChannelFollowing)) && !((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [self getSubscriptionStatusForChannelId];
    }

    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onClickingHideDetailViewButton)];
    [swipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipeRecognizer];
    [Utilities setAppBackgroundcolorForView:self.mCollectionView];

    // Register For Notification to Update the channell Subscription Status

    [self addNotificationForFollowStatusWhenGusetUserLogin];
}

- (void)exitFullScreenModeForOverLayFlow
{
    [self.controlsViewController exitFullScrenWhenSignUpAndLogin];
}

- (void)createFullScreenViewController
{
    _fullscreenViewController = [[UIViewController alloc] init];
}

- (void)addErrorViewFullScreenViewControllerWithErrorType:(eErrorType)aErrorType
{
    if (_fullscreenViewController)
    {
        [UIViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeErrorViewFullScreenViewController) object:nil];

        [self removeErrorViewFullScreenViewController];

        if (aErrorType == InternetFailureWithTryAgainMessage || aErrorType == ServiceErrorWithTryAgainMessage)
        {
            [self performSelector:@selector(removeErrorViewFullScreenViewController) withObject:nil afterDelay:6];
        }

        ErrorView *aErrorView = [[ErrorView alloc] initWithFrame:_fullscreenViewController.view.frame withErrorType:aErrorType];
        aErrorView.tag = kFullVideoScreenErrorViewTag;
        [_fullscreenViewController.view addSubview:aErrorView];
        CGRect aViewFrame = aErrorView.frame;
        aViewFrame.origin.y = 0;
        aErrorView.frame = aViewFrame;

        if (aErrorView.containerView)
        {
            [UIView animateWithDuration:0.45
                                  delay:1.0
                 usingSpringWithDamping:0.65
                  initialSpringVelocity:1.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{

                               aErrorView.containerView.frame = CGRectMake(0, 0, aErrorView.containerView.frame.size.width, aErrorView.containerView.frame.size.height);
                             }
                             completion:^(BOOL finished){

                                 //aErrorView.frame = CGRectMake(0, 64, aErrorView.frame.size.width, 50);
                             }];
        }
    }
}

- (void)removeErrorViewFullScreenViewController
{
    if (_fullscreenViewController)
    {
        ErrorView *aErrorView = (ErrorView *)[_fullscreenViewController.view viewWithTag:kFullVideoScreenErrorViewTag];

        [aErrorView removeFromSuperview];
        aErrorView = nil;
    }
}
- (void)setupBCOVPlayer
{
    CGRect viewRect = [[UIScreen mainScreen] bounds];
    _videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewRect.size.width, (self.view.frame.size.width / 16) * 9.0)]; // viewRect.size.height/3+10)];
    _videoView.userInteractionEnabled = YES;

    [self stopPlayerandRemoveCallBacks];
    _controlsViewController = nil;
    _fullscreenViewController = [[UIViewController alloc] init];
    _controlsViewController = [[ControlsViewController alloc] initWithNibName:@"ControlsViewController" bundle:nil];
    _controlsViewController.delegate = self;

    _playbackController = [[BrightCovePlayerSingleton sharedInstance] moviePlayer];
    _playbackController.delegate = self;
    [_playbackController addSessionConsumer:_controlsViewController];
    _controlsViewController.mBCOVAdsCallBack = [BrightCovePlayerSingleton sharedInstance];

    _fullscreenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    [self.controlsViewController.playPauseButton setImage:[UIImage imageNamed:@"playerPause"] forState:UIControlStateNormal];

    if (CGRectIsEmpty(self.cgRectVideoView))
    {
        self.cgRectVideoView = CGRectMake(0, self.isDetailViewOverLayVisible ? 0 + kVideoPlayerYaxisDelta : 0 + kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta);
    }

    //self.cgRectVideoView =self.videoView.bounds;
    self.playbackController.view.frame = self.cgRectVideoView;

    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoView addSubview:self.playbackController.view];

    [self addChildViewController:self.controlsViewController];
    self.controlsViewController.view.frame = self.videoView.bounds;
    //self.controlsViewController.view.backgroundColor = [UIColor redColor];
    [self.videoView addSubview:self.controlsViewController.view];

    _controlsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[playbackController]|" options:0 metrics:nil views:@{ @"playbackController" : _controlsViewController.view }]];
    [self.videoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playbackController]|" options:0 metrics:nil views:@{ @"playbackController" : _controlsViewController.view }]];

    /* [self.videoView addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_controlsViewController.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
     
     [self.videoView addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_controlsViewController.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
     
     [self.videoView addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_controlsViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
     
     [self.videoView addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_controlsViewController.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];*/

    [self.videoView updateConstraints];
    [self.controlsViewController didMoveToParentViewController:self];

    //  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[videoView]|" options:0 metrics:nil views:@{@"videoView" : self.videoView}]];

    //[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[videoView]|" options:0 metrics:nil views:@{@"videoView" : self.videoView}]];

    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.controlsViewController.playerSkipBack.hidden = YES;
    [self.controlsViewController addObserverForAirPlayConnect];
}
- (void)resetVideoViewFrame
{
    //CGRect viewRect = [[UIScreen mainScreen] bounds];
    //  _videoView.frame =  CGRectMake(0, kVideoPlayerYaxisDelta, viewRect.size.width,((self.view.frame.size.width/16)*9.0)+kVideoPlayerHeightDelta);

    /* if(!(CGRectEqualToRect(_videoView.frame,self.cgRectVideoView)))
     {
     _videoView.frame = self.cgRectVideoView;
     
     }*/

    if (!self.isMoviePlayerInFullScreen && !(CGRectEqualToRect(_videoView.frame, self.cgRectVideoView)))
    {
        _videoView.frame = self.cgRectVideoView;
        self.playbackController.view.frame = self.cgRectVideoView;
    }
    else if (self.isMoviePlayerInFullScreen && !(CGRectEqualToRect(_videoView.frame, self.cgRectVideoViewFullScreen)))
    {
        _videoView.frame = self.cgRectVideoViewFullScreen;
        self.playbackController.view.frame = self.cgRectVideoViewFullScreen;
    }
}
- (UIView *)getPlayerView
{
    return _videoView;
}

- (void)getSubscriptionStatusForChannelId
{
    __weak PlayDetailViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendrequestToGetSubscriptionStatusForChannel:self.mVideoModel ? self.mVideoModel.channelId : self.mChannelDataModel.uniqueId
                                                                           withResponseBlock:^(BOOL success) {

                                                                             [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                                                                               self.mChannelDataModel.isChannelFollowing = success;
                                                                               if (weakSelf.isFromSearch || self.isFromGenre)
                                                                               {
                                                                                   [weakSelf setFollowButtonSelectedMode:success];

                                                                                   if (self.isFromGenre)
                                                                                   {
                                                                                       [self updateChannelSubscriptionStatusForVideoModelsInGenre];
                                                                                   }
                                                                                   //weakSelf.mAddFollowButton.selected = success;
                                                                               }
                                                                             }];

                                                                           }
                                                                                  errorBlock:^(NSError *error){
                                                                                  }];
}
- (void)addNotificationForFollowChannel
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationStatusForFollow:) name:@"NotificationForFollowChannel" object:nil];
}

- (void)notificationStatusForFollow:(NSNotification *)aNotification
{
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *aChannelId = [userInfo objectForKey:@"channelId"];

    BOOL followStatus = [((NSNumber *)[userInfo objectForKey:@"followStatus"])boolValue];
    [self updateDataSourceWithFollowStatus:followStatus withChannelId:aChannelId];

    if (self.isFromGenre)
    {
        //self.mAddFollowButton.selected = followStatus;
        [self setFollowButtonSelectedMode:followStatus];
    }

    if (self.isFromShowBottomPlayDetailScreen)
    {
        if ([self.mChannelDataModel.uniqueId isEqualToString:aChannelId])
        {
            if (!self.isVideoLocked)
                [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)postNotificationForFollowChannelId:(NSString *)aChannelId withFollowStatus:(BOOL)aFollowStatus
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:aChannelId, @"channelId", [NSNumber numberWithBool:aFollowStatus], @"followStatus", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationForFollowChannel" object:nil userInfo:userInfo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isViewDisappeared = NO;
    if (self.isFromPlayList)
    {
        [GAUtilities setWatchbaleScreenName:@"PlaylistDetailsScreen"];
    }
    else
    {
        [GAUtilities setWatchbaleScreenName:@"ChannelDetailsScreen"];
    }

    if (self.mDetailView)
    {
        [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

        //        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

        NSLog(@"%ld,%ld", self.mSelectedIndexPath.row, self.mVideoListDataSource.count + 2);

        if (self.isDetailViewOverLayVisible && (self.mSelectedIndexPath.row == self.mVideoListDataSource.count))
        {
            [self performSelector:@selector(moveCellToTop) withObject:nil afterDelay:0.01];
        }
    }
    else
    {
        [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

        //        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)setMPreviousVideoPlayIndex:(NSInteger)mPreviousVideoPlayIndex
{
    _mPreviousVideoPlayIndex = mPreviousVideoPlayIndex;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.shouldNotCallViewDidAppear)
    {
        [self performSelector:@selector(playPreviousVideoWhenWhenAppears) withObject:nil afterDelay:0.0];
    }
    self.shouldNotCallViewDidAppear = NO;
}

- (void)playPreviousVideoWhenWhenAppears
{
    if (self.mPreviousVideoPlayIndex != -1 && !self.isVideoLocked && self.mSelectedIndexPath == nil)
    {
        [self preventCellDidSelectionForDuration:0.3];
        [self performSelector:@selector(playCenterCellVideoWithIndex:) withObject:[NSIndexPath indexPathForItem:self.mPreviousVideoPlayIndex inSection:0] afterDelay:0.2];
        //use the index
        self.mPreviousVideoPlayIndex = -1;
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [UIViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(playFirstVideo) object:nil];
    /*if(!self.isMoviePlayerInFullScreen)
     {
     [self onMoviePlayerStop];
     }*/
}

- (void)pauseMoviePlayer
{
    BOOL isAddPlaying = [[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying];

    if (isAddPlaying)
    {
        [self.controlsViewController PauseAds];
    }
    else
    {
        if (self.controlsViewController.totalProgress > 0)
        {
            [self.controlsViewController pauseMoviePlayerWhenFlowWithSignUp];
        }
    }
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.isViewDisappeared = YES;
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

    if (!self.isMoviePlayerInFullScreen && ![presentedVc isMemberOfClass:[MFMailComposeViewController class]])
    {
        [self onMoviePlayerStop];
    }
}

- (void)handlePauseOfPlayerWhenOverlayPresented
{
    NSArray *aArray = ((AppDelegate *)kSharedApplicationDelegate).window.subviews;
    for (UIView *aView in aArray)
    {
        if ([aView isMemberOfClass:[SignUpLoginOverLayView class]])
        {
            [self pauseMoviePlayer];
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
            [self pauseMoviePlayer];
            return;
        }
    }
    else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
    {
        [self pauseMoviePlayer];
        return;
    }
}

- (void)removeBackButtonForController
{
    [self.mViewBackButton removeFromSuperview];
    self.mViewBackButton = nil;

    [self.mNavBarBackButton removeFromSuperview];
    self.mNavBarBackButton = nil;
}

- (void)initialSetUp
{
    if (!self.deeplinkShowId)
    {
        [self setBackButtonOnView];
        self.mViewBackButton = [self getBackButtonRef];
    }

    //    [self setShareButtonOnView];
    [self createNavBarWithHidden:YES]; // Modified AB: YES to NO
    [self setNavigationBarTitle:self.isFromGenre ? self.mChannelDataModel.title : self.mDataModel.title withFont:nil withTextColor:nil];

    if (self.isFromGenre)
    {
        [self setShareAddButtonOnView]; // Modified AB : This line is commneted in BCMerge
        self.mAddFollowButton = [self mFollowButton];
        [self setFollowButtonSelectedMode:self.mChannelDataModel.isChannelFollowing];
        // self.mAddFollowButton.selected = self.mChannelDataModel.isChannelFollowing;

        if (self.isEpisodeClicked || self.isLogoClicked)
        {
            [self setFollowButtonSelectedMode:self.mVideoModel.isVideoFollowing];
            //self.mAddFollowButton.selected=self.mVideoModel.isVideoFollowing;
        }
        [self.controlsViewController endAd];
    }
    else
    {
        [self setShareButtonOnView]; // Modified AB : Commented the line out in BCMERGE
    }

    self.mCollectionView.scrollEnabled = NO;
    self.mCollectionView.decelerationRate = UIScrollViewDecelerationRateNormal;

    self.mVideoListDataSource = [[NSMutableArray alloc] init];
    self.mFetchingVideoIndexPathArray = [[NSMutableArray alloc] init];
    [self registerCollectionCell];

    self.isVideoLocked = NO;
    ((AppDelegate *)kSharedApplicationDelegate).isVideoPlay = NO;
    self.canSelectCell = YES;
    self.isDetailViewOverLayVisible = NO;
    self.mVideoDetailHideButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.mVideoDetailHideButton.frame = CGRectMake(5, 5, 40, 40);
    [self.mVideoDetailHideButton setImage:[UIImage imageNamed:@"collapse"] forState:UIControlStateNormal];
    //    [self.mVideoDetailHideButton setBackgroundColor:[UIColor colorWithWhite:.5 alpha:.5]]; //Modified AB : Remove Button border
    [self.mVideoDetailHideButton addTarget:self action:@selector(onClickingHideDetailViewButton) forControlEvents:UIControlEventTouchUpInside];
    // [self.view addSubview:self.mVideoDetailHideButton];
    self.mVideoDetailHideButton.hidden = YES;

    self.mCollectionView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.isHidden ? -20 : -64, 0, 0, 0);

    self.mChannelIDForFetchingChannelLogoArray = [[NSMutableArray alloc] init];
}

- (void)getDataFromServer
{
    if (self.isFromGenre)
    {
        [self getDataForVideoFromServer];
    }
    else
    {
        [self getVideoListForCuratedPlaylist];
    }
}

- (void)getDataForVideoFromServer
{
    [self getGenereForChannelFromServer];
    [self getVideoListForChannel];
    [self updatePublisherInfoInUI];
}

- (void)updatePublisherInfoInUI
{
    if (self.isFromProvider && self.mProviderModal)
    {
        [self updateProviderDeatils:self.mProviderModal];
    }
    else
    {
        [self getPublisher];
    }
}

- (void)getGenereForChannelFromServer
{
    if (!self.mGenreDataModel)
    {
        [self getGenreForChannel];
    }

    if (!self.mChannelDataModel)
    {
        //get Channel Info from server

        //AFTER GET CHANNEL INFO CALL THE BELOW METHODS IN RESPONSE
        //updatePublisherInfoInUI
        //getGenreForChannel

        NSString *aChannelId = self.mChannelDataModel.uniqueId;

        if (!(aChannelId != nil && aChannelId.length > 0))
        {
            if (self.deeplinkShowId)
            {
                aChannelId = self.deeplinkShowId;
            }
        }
        if (aChannelId)
        {
            [[ServerConnectionSingleton sharedInstance] sendRequestToGetChannelInfo:aChannelId
                responseBlock:^(ChannelModel *channelModal) {
                  self.mChannelDataModel = channelModal;
                  [self getGenreForChannel];
                  [self getVideoListForChannel];
                  [self updatePublisherInfoInUI];

                  [self performSelectorOnMainThread:@selector(reloadFirstCellCollectionView) withObject:nil waitUntilDone:NO];
                }
                errorBlock:^(NSError *error) {

                  [self performSelectorOnMainThread:@selector(displayErrorOngettingChannelInfo:) withObject:error waitUntilDone:NO];

                }];
        }
    }
}

- (void)reloadFirstCellCollectionView
{
    if (self.mVideoListDataSource.count)
    {
        [self.mCollectionView reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
    }
    else
    {
        [self.mCollectionView reloadData];
    }
}
- (void)displayErrorOngettingChannelInfo:(NSError *)aError
{
    __weak PlayDetailViewController *weakSelf = self;
    if (aError.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getGenereForChannelFromServer) withInputParameters:nil];
    }
    else if (aError.code == 404)
    {
        [self createErrorScreenForDeepLinkDataUnavailble:kDeepLinkingShowUnAvailable];
    }
    else /*if(error.code==kServerErrorCode)*/
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getGenereForChannelFromServer) withInputParameters:nil];
    }
}

- (void)addNotificationForMoviePlayerRotation
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClickingMoviePlayerDoneButton) name:MPMoviePlayerWillExitFullscreenNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClickingFullScreenMoviePlayerButton) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
}

- (void)onClickingFullScreenMoviePlayerButton
{
    self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;

    self.isMoviePlayerInFullScreen = YES;
    if (!self.isMoviePlayerInFullScreen)
    {
        self.canChangeToLandScape = YES;
    }
    else
    {
        self.canChangeToLandScape = NO;
    }
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)onClickingMoviePlayerDoneButton
{
    //self.isMoviePlayerInFullScreen=NO;
    self.canChangeToLandScape = NO;
    [self removeLandScapeMovieController];
    // [UIViewController attemptRotationToDeviceOrientation]; // commented in BCmerge
}

- (void)didRotate:(NSNotification *)notification
{
    AppDelegate *aSharedDel = (AppDelegate *)kSharedApplicationDelegate;
    if (!aSharedDel.isSignUpOverLayClicked)
    {
        if (((AppDelegate *)kSharedApplicationDelegate).mSignUpLoginOverLayView)
        {
            return;
        }
        if ([self setOrientationBasedOnOverlay])
        {
            return;
        }
    }

    if ([self setOrientationBasedOnOverlay])
    {
        return;
    }

    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    NSLog(@"self.currentOrientation=%ld", self.currentOrientation);
    NSLog(@"orientation=%ld", orientation);

    if (orientation != self.currentOrientation && orientation != UIDeviceOrientationFaceUp && orientation != UIDeviceOrientationFaceDown && orientation != UIDeviceOrientationUnknown)
    {
        if (self.mActivityViewController)
        {
            [self.mActivityViewController dismissViewControllerAnimated:YES
                                                             completion:^{
                                                               [self performActionOnDeviceRotation];
                                                               self.mActivityViewController = nil;
                                                             }];
        }
        else
        {
            [self performActionOnDeviceRotation];
        }
    }
}

- (BOOL)setOrientationBasedOnOverlay
{
    BOOL shouldNotRotate = NO;
    UIViewController *presentedVc = self.presentedViewController;
    if ([presentedVc isMemberOfClass:[UINavigationController class]])
    {
        UINavigationController *navCntlr = (UINavigationController *)presentedVc;
        UIViewController *vc = [[navCntlr viewControllers] objectAtIndex:0];

        if ([vc isMemberOfClass:[LoginViewController class]])
        {
            shouldNotRotate = YES;
        }
    }
    else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
    {
        shouldNotRotate = YES;
    }
    return shouldNotRotate;
}

- (void)performActionOnDeviceRotation
{
    if (self.isMoviePlaying || (self.isMoviePlayerInFullScreen))
    {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

        if (orientation != UIDeviceOrientationUnknown && orientation != UIDeviceOrientationFaceUp && orientation != UIDeviceOrientationFaceDown)
        {
            self.currentOrientation = orientation;
            ((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation = self.currentOrientation;
            if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
            {
                @try
                {
                    [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

                    //                    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

                    self.isMoviePlayerInFullScreen = YES;
                    self.controlsViewController.isEntredFullScreen = YES;
                    self.canChangeToLandScape = NO;
                    self.controlsViewController.playerSkipBack.hidden = NO;
                    self.controlsViewController.PublisherImg.hidden = NO;
                    self.controlsViewController.placeholderText.hidden = NO;
                    self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;

                    if (!self.isfullscreenViewControllerPresented)
                    {
                        if (self.fullscreenViewController)
                        {
                            if (self.presentedViewController)
                            {
                                [self.fullscreenViewController dismissViewControllerAnimated:NO completion:nil];
                            }
                            self.fullscreenViewController = nil;
                        }
                        self.fullscreenViewController = [[UIViewController alloc] init];

                        _fullscreenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

                        [self.fullscreenViewController addChildViewController:self.controlsViewController];

                        [self.fullscreenViewController.view addSubview:self.videoView];
                        [self.fullscreenViewController.view bringSubviewToFront:self.videoView];
                        [self.controlsViewController didMoveToParentViewController:self.fullscreenViewController];
                        self.controlsViewController.modalPresentationStyle = UIModalPresentationCustom;

                        self.isfullscreenViewControllerPresented = YES;

                        [self presentViewController:self.fullscreenViewController
                                           animated:NO
                                         completion:^{
                                           if (CGRectIsEmpty(self.cgRectVideoViewFullScreen))
                                           {
                                               self.cgRectVideoViewFullScreen = self.fullscreenViewController.view.bounds;
                                           }
                                           self.videoView.frame = self.cgRectVideoViewFullScreen;
                                           [self.controlsViewController hidePlyerControls];

                                           [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

                                           //                                           [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
                                           if (self.isEpisodeClicked || self.isLogoClicked || self.isFromGenre)
                                           {
                                               [self.controlsViewController setProviderImageForUrl:self.mChannelDataModel.imageUri];
                                           }
                                           else
                                           {
                                               [self.controlsViewController.PublisherImg setImage:self.currentCell.mBrandLogoImageView.image];
                                           }

                                           [self.controlsViewController.fullscreenButton setImage:[UIImage imageNamed:@"playerCollapse"] forState:UIControlStateNormal];
                                           [self setFrameForVideoLoadingFailureView];
                                         }];
                    }
                }
                @catch (NSException *exception)
                {
                    NSLog(@"Exception = %@", exception);
                }
            }
            else
            {
                @try
                {
                    if (self.mDetailView)
                    {
                        [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

                        //                        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
                        [self setNavBarVisiblityWithAlpha:0.0];
                        self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;
                    }
                    else
                    {
                        [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

                        //                        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
                        [self setNavBarVisiblityWithAlpha:kNavBarMaxAlphaValue];
                        self.controlsViewController.infoButtonForShowingDetailsView.hidden = NO;
                    }
                    self.isMoviePlayerInFullScreen = NO;
                    self.canChangeToLandScape = NO;
                    self.controlsViewController.isEntredFullScreen = NO;
                    self.controlsViewController.playerSkipBack.hidden = YES;
                    self.controlsViewController.PublisherImg.hidden = YES;
                    self.controlsViewController.placeholderText.hidden = YES;

                    [self.controlsViewController.fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];
                    if (!self.isDetailViewOverLayVisible)
                    {
                        [self moveCollectionCellToCenterForIndexPath:self.mSelectedIndexPath withAnimation:NO];
                    }

                    [self.fullscreenViewController dismissViewControllerAnimated:NO
                                                                      completion:^{

                                                                        [self.controlsViewController hidePlyerControls];
                                                                        [self addChildViewController:self.controlsViewController];
                                                                        [self.currentCell.mVideoImageView addSubview:self.videoView];
                                                                        [self.currentCell.mVideoImageView bringSubviewToFront:self.videoView];
                                                                        [self.controlsViewController didMoveToParentViewController:self];
                                                                        if (CGRectIsEmpty(self.cgRectVideoView))
                                                                        {
                                                                            self.cgRectVideoView = CGRectMake(0, self.isDetailViewOverLayVisible ? kVideoPlayerYaxisDelta : kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta);
                                                                        }

                                                                        self.videoView.frame = self.cgRectVideoView;
                                                                      }];
                    [self setFrameForVideoLoadingFailureView];
                    if ([self.currentCell isKindOfClass:[PlayDetailCollectionViewCell class]])
                    {
                        float aCellImageXAxis = 0.0;
                        self.currentCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                        self.currentCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
                    }
                    [self performSelector:@selector(addBlurEffectOnVisibleCells) withObject:nil afterDelay:0.1];
                    self.fullscreenViewController = nil;
                    self.isfullscreenViewControllerPresented = NO;
                    // [self showNavBarWithAnimation];
                    //Force collection view cell to top position without animation
                    //Force movement is required for last cell of collection view as effect of contentSize wont allows last cell to sroll to top using scrollToItemAtIndexPath method
                    if (self.isDetailViewOverLayVisible)
                    {
                        [self performSelector:@selector(moveCellToTop) withObject:nil afterDelay:0.01];
                    }
                    if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0 && self.mSelectedIndexPath && self.mSelectedIndexPath.row <= self.mVideoListDataSource.count)
                    {
                        [self resetSetupForVideoDetailView];
                    }
                    if (self.isSelectedCellDetailsDimmed)
                        [self dimSelectedCellDetailView];
                }
                @catch (NSException *exception)
                {
                    NSLog(@"Exception = %@", exception);
                }
            }
        }
    }
}

- (void)moveCellToTop
{
    NSIndexPath *indexPath = [self.mCollectionView indexPathForCell:self.currentCell];
    [self forceToTopCollectionViewCellAtIndexPath:indexPath animated:NO];
}

- (void)onMoviePlayerStop
{
    if (self.isDetailViewOverLayVisible)
    {
        self.mCollectionView.scrollEnabled = YES;

        if (self.mSelectedIndexPath)
        {
            [self scrollImageViewToCenterForIndexPath:self.mSelectedIndexPath withAnimation:YES];
        }
        [self removeVideoDetailView];
    }

    [self stopAndRemoveMoviePlayer];
    [self breakVideoLockSetUp];
    [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.0 withResizingCell:YES];
}

- (void)resetSetupForVideoDetailView
{
    PlayDetailCollectionViewCell *aCell = nil;

    if (self.mSelectedIndexPath.row <= self.mVideoListDataSource.count)
        aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];

    if (aCell)
    {
        if (self.isDetailViewOverLayVisible)
        {
            aCell.mBrandLogoImageView.hidden = YES;
            aCell.mFollowButton.hidden = YES;
            aCell.mVideoTitleLabel.hidden = YES;
            aCell.mVideoDescLabel.hidden = YES;

            if (!self.isFromPlayList)
            {
                aCell.mFollowButton.hidden = YES;
            }
        }
        else
        {
            aCell.mBrandLogoImageView.hidden = NO;
            aCell.mFollowButton.hidden = NO;
            aCell.mVideoTitleLabel.hidden = YES;
            aCell.mVideoDescLabel.hidden = NO;

            if (!self.isFromPlayList)
            {
                aCell.mFollowButton.hidden = YES;
            }
        }
    }
}

- (void)removeLandScapeMovieController
{
    if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
    {
        PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];
        if (aCell)
        {
            for (UIView *aSubView in [aCell.mVideoImageView subviews])
            {
                if (aSubView != aCell.mVideoDurationLabel)
                {
                    [aSubView removeFromSuperview];
                }
            }
            aCell.mVideoImageView.userInteractionEnabled = YES;
            self.controlsViewController.infoButtonForShowingDetailsView.hidden = NO;

            if (CGRectIsEmpty(self.cgRectVideoView))
            {
                self.cgRectVideoView = CGRectMake(0, self.isDetailViewOverLayVisible ? kVideoPlayerYaxisDelta : kVideoPlayerYaxisDelta, aCell.mVideoImageView.frame.size.width, aCell.mVideoImageView.frame.size.height + kVideoPlayerHeightDelta);
            }

            self.videoView.frame = self.cgRectVideoView;

            [aCell.mVideoImageView addSubview:self.videoView];
            [aCell.mVideoImageView bringSubviewToFront:self.videoView];

            if (NSClassFromString(@"UIVisualEffect"))
            {
                self.mDetailView.backgroundColor = [UIColor colorWithRed:27 / 255.0 green:29 / 255.0 blue:30 / 255.0 alpha:.1];
            }
            else
            {
                self.mDetailView.backgroundColor = [UIColor colorWithRed:27 / 255.0 green:29 / 255.0 blue:30 / 255.0 alpha:.9];
            }
        }
    }
}

- (void)registerCollectionCell
{
    if (self.isFromGenre)
    {
        UINib *genrefirstCellNib = [UINib nibWithNibName:@"PlayGenreGenreFirstCollectionViewCell" bundle:nil];
        [self.mCollectionView registerNib:genrefirstCellNib forCellWithReuseIdentifier:@"PlayGenreGenreFirstCollectionViewCell"];
    }
    else
    {
        UINib *firstCellNib = [UINib nibWithNibName:@"PlayDetailFirstCollectionViewCell" bundle:nil];
        [self.mCollectionView registerNib:firstCellNib forCellWithReuseIdentifier:@"PlayDetailFirstCollectionViewCell"];
    }

    UINib *cellNib = [UINib nibWithNibName:@"PlayDetailCollectionViewCell" bundle:nil];
    [self.mCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"PlayDetailCollectionViewCell"];
}

- (void)preventCellDidSelectionForDuration:(float)aDuration
{
    self.canSelectCell = NO;
    self.view.userInteractionEnabled = NO;
    [self performSelector:@selector(enableCellSelection) withObject:nil afterDelay:aDuration];
}

- (void)enableCellSelection
{
    self.canSelectCell = YES;
    self.view.userInteractionEnabled = YES;
}

- (void)breakVideoLockSetUp
{
    ((AppDelegate *)kSharedApplicationDelegate).isVideoPlay = NO;
    self.isVideoLocked = NO;
    self.isVideoLockedRef = NO;
    self.mSelectedIndexPath = nil;
    self.currentOrientation = UIDeviceOrientationPortrait;
    ((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation = self.currentOrientation;
}

#pragma mark
#pragma mark Server Call Method

- (void)getChannelInfoForSelectedVideo
{
    __weak PlayDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    ///fmds/api/watchable/iptv/channels/10184
    NSString *aString = [self.mVideoModel.relatedLinks objectForKey:@"channel"];

    if (aString.length)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetChannelInfoWithURL:aString
            responseBlock:^(NSArray *responseArray) {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                if (responseArray.count)
                {
                    ChannelModel *aChannelModel = [responseArray objectAtIndex:0];
                    weakSelf.mChannelDataModel = aChannelModel;
                    weakSelf.mChannelDataModel.nextVideoUnderchannel = weakSelf.mVideoModel;
                    if (self.isEpisodeClicked || self.isLogoClicked || self.isFromGenre)
                    {
                        if (self.mDetailView)
                        {
                            [weakSelf.mDetailView setProviderImageWithUrl:aChannelModel.imageUri];

                            [weakSelf.controlsViewController setProviderImageForUrl:self.mChannelDataModel.imageUri];
                        }
                    }
                }
                [weakSelf getDataFromServer];

              }];

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(errorInGetChannelInfoForSelectedVideo:) withObject:error waitUntilDone:NO];
            }];
    }
}
- (void)errorInGetChannelInfoForSelectedVideo:(NSError *)error
{
    __weak PlayDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getChannelInfoForSelectedVideo) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getChannelInfoForSelectedVideo) withInputParameters:nil];
    }
}
- (void)getVideoListForCuratedPlaylist //We are not making any changes in this method compared to BCMerge : Modified AB
{
    __weak PlayDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    NSString *aVideoListURL = weakSelf.mDataModel.videoListUrl;
    NSString *aDataModelUniqueId = weakSelf.mDataModel.uniqueId;

    if (aVideoListURL == nil)
    {
        if (self.deeplinkPlayListId)
        {
            aVideoListURL = kPlayListVideoFetcingForDeeplinkingURL(self.deeplinkPlayListId);
            aDataModelUniqueId = self.deeplinkPlayListId;
        }
    }

    if (aVideoListURL)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetVideoForPlaylist:aVideoListURL
            withPlayListUniqueId:aDataModelUniqueId
            responseBlock:^(NSArray *responseArray) {

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                BOOL isValid = self.isPlayLatestVideo;
                [weakSelf updateDataSource:responseArray];
                if (self.isPlayVideoForDeeplink)
                {
                    self.isPlayVideoForDeeplink = NO;
                    if (responseArray.count)
                    {
                        [self scrollToDeeplinkingVideoId];
                    }
                }
                else if (!isValid)
                {
                    self.mPreviousVideoPlayIndex = 1;
                    if (!self.isViewDisappeared)
                    {
                        [self performSelector:@selector(playFirstVideo) withObject:nil afterDelay:0.5];
                    }
                }
              }];

              if (responseArray.count)
              {
                  VideoModel *model = [responseArray objectAtIndex:0];

                  weakSelf.mDataModel.shareLink = model.playListSharingUrl;
                  NSLog(@"playLists Sharing URL = %@", weakSelf.mDataModel.shareLink);

                  [self fetchUniqueChannelsSubscriptionStatus:responseArray];
              }
            }
            withPlayListModelResponseBlock:^(PlaylistModel *playlistModal) {

              if (self.mDataModel == nil)
              {
                  if (playlistModal.uniqueId != nil)
                  {
                      self.mDataModel = playlistModal;
                  }
                  else
                  {
                      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self createErrorScreenForDeepLinkDataUnavailble:kDeepLinkingPlayListUnAvailable];

                      }];
                  }
              }

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(errorInGetVideoListForCuratedPlaylist:) withObject:error waitUntilDone:NO];
            }];
    }
}

- (void)updateSubscribtionStatusForSameChannelId:(NSString *)aChannelId withStatus:(BOOL)aFollowStatus //We are not making any changes in this method compared to BCMerge : Modified AB
{
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"channelId == %@", aChannelId];

    NSArray *aVideoModelArray = [self.mVideoListDataSource filteredArrayUsingPredicate:aPredicate];

    [aVideoModelArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      __block VideoModel *aVideoModel = (VideoModel *)obj;
      aVideoModel.isVideoFollowing = aFollowStatus;

    }];

    [self performSelectorOnMainThread:@selector(updateVisibleCellsForFollowStatus) withObject:nil waitUntilDone:NO];
}

- (void)updateVisibleCellsForFollowStatus
{ //We are not making any changes in this method compared to BCMerge : Modified AB

    NSArray *arr = [self.mCollectionView indexPathsForVisibleItems];
    for (NSIndexPath *aIndexPath in arr)
    {
        if (aIndexPath.row != 0 && aIndexPath.row != self.mVideoListDataSource.count + 1)
        {
            PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:aIndexPath];
            VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
            aCell.mFollowButton.selected = aVideoModel.isVideoFollowing;

            if (aCell.mFollowButton.selected)
            {
                aCell.mFollowButtonWidthConstraint.constant = 91.0;
            }
            else
            {
                aCell.mFollowButtonWidthConstraint.constant = 70.0;
            }

            if (self.mDetailView && self.mDetailView.indexPath.row == aIndexPath.row)
            {
                self.mDetailView.followButton.selected = aVideoModel.isVideoFollowing;

                if (aVideoModel.isVideoFollowing)
                {
                    CGRect aFrame = self.mDetailView.followButton.frame;
                    aFrame.origin.x = self.mDetailView.frame.size.width - 91 - 12;
                    aFrame.size.width = 91.0;
                    self.mDetailView.followButton.frame = aFrame;
                    self.mDetailView.followButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
                    self.mDetailView.followButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
                }
                else
                {
                    CGRect aFrame = self.mDetailView.followButton.frame;
                    aFrame.origin.x = self.mDetailView.frame.size.width - 70 - 12;
                    aFrame.size.width = 70.0;
                    self.mDetailView.followButton.frame = aFrame;
                    self.mDetailView.followButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
                    self.mDetailView.followButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
                }

                if (self.mSelectedIndexPath && self.mSelectedIndexPath.row == aIndexPath.row)
                {
                    [self updateFollowStatusForSelectedVideoInControlsController:aVideoModel.isVideoFollowing];
                }

                [self.mDetailView setFollowButtonHighlightPropertyWithSelected:aVideoModel.isVideoFollowing];
            }
        }
    }
}

- (void)errorInGetVideoListForCuratedPlaylist:(NSError *)error
{
    __weak PlayDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getVideoListForCuratedPlaylist) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getVideoListForCuratedPlaylist) withInputParameters:nil];
    }
}

- (void)getVideoList
{
    __weak PlayDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
    NSString *aChannelId = weakSelf.mChannelDataModel.uniqueId;

    if (aChannelId)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetVideoForChannelId:aChannelId
            responseBlock:^(NSArray *responseArray) {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                BOOL isValid = self.isPlayLatestVideo;

                [weakSelf updateDataSource:responseArray];

                if (self.isPlayVideoForDeeplink)
                {
                    self.isPlayVideoForDeeplink = NO;
                    if (responseArray.count)
                    {
                        [self scrollToDeeplinkingVideoId];
                    }
                }
                else if (!isValid)
                {
                    self.mPreviousVideoPlayIndex = 1;
                    if (!self.isViewDisappeared)
                    {
                        [self performSelector:@selector(playFirstVideo) withObject:nil afterDelay:0.7];
                    }
                }

              }];

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(errorInGetVideoList:) withObject:error waitUntilDone:NO];
            }];
    }
}

- (void)errorInGetVideoList:(NSError *)error
{
    __weak PlayDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getDataForVideoFromServer) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataForVideoFromServer) withInputParameters:nil];
    }
}
- (void)getNextVideoandListOfVideoForChannel //No changes : Modified AB
{
    __weak PlayDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
    if (self.mChannelDataModel.uniqueId)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetNextVideoForChannelId:self.mChannelDataModel.uniqueId
            responseBlock:^(VideoModel *videoModal) {

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (videoModal)
                {
                    weakSelf.mChannelDataModel.nextVideoUnderchannel = videoModal;
                }
                [weakSelf getVideoList];
              }];

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(errorInGetNextVideoandListOfVideoForChannel:) withObject:error waitUntilDone:NO];
              NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);

            }];
    }
}

- (void)errorInGetNextVideoandListOfVideoForChannel:(NSError *)error
{
    __weak PlayDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getDataForVideoFromServer) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataForVideoFromServer) withInputParameters:nil];
    }
}
- (void)getVideoListForChannel
{
    if (self.isPlayLatestVideo)
    {
        //get nextvideo from server
        if (self.mChannelDataModel.nextVideoUnderchannel.uniqueId.length)
        {
            [self getVideoList];
        }
        else
        {
            [self getNextVideoandListOfVideoForChannel];
        }
    }
    else
    {
        [self getVideoList];
    }
}

- (void)getPublisher
{ // No changes : Modified AB

    __weak PlayDetailViewController *weakSelf = self;
    if (self.mChannelDataModel.relatedLinks[@"publisher"])
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetPublisherresponseBlock:^(NSArray *responseArray) {
          if (responseArray.count)
          {
              ProviderModel *model = [responseArray objectAtIndex:0];

              weakSelf.mProviderModal = model;

              [weakSelf performSelectorOnMainThread:@selector(updateProviderDeatils:) withObject:weakSelf.mProviderModal waitUntilDone:NO];
          }

        }
            errorBlock:^(NSError *error) {

            }
            forAPiFormat:self.mChannelDataModel.relatedLinks[@"publisher"]];
    }
}

- (void)getGenreForChannel
{
    __weak PlayDetailViewController *weakSelf = self;
    if (self.mChannelDataModel.relatedLinks[@"genre"])
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestTogetGenreForChannel:self.mChannelDataModel.relatedLinks[@"genre"]
                                                                  WithResponseBlock:^(NSArray *responseArray) {

                                                                    if (responseArray.count)
                                                                    {
                                                                        GenreModel *model = [responseArray objectAtIndex:0];

                                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                                                                          weakSelf.mGenreDataModel = model;

                                                                          NSIndexPath *indexPAth = [NSIndexPath indexPathForRow:0 inSection:0];

                                                                          PlayGenreGenreFirstCollectionViewCell *aCell = (PlayGenreGenreFirstCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:indexPAth];
                                                                          if (aCell)
                                                                          {
                                                                              [weakSelf.mCollectionView reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]];
                                                                          }
                                                                        }];
                                                                    }

                                                                  }
                                                                         errorBlock:^(NSError *error){

                                                                         }];
    }
}

- (void)getPlayBackURIFromServerForSelectedVideoforIndexPath:(NSIndexPath *)aIndexPath
{
    if (self.controlsViewController)
    {
        self.controlsViewController.totalProgress = 0;
    }

    self.isSelectedCellDetailsDimmed = NO;

    VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];

    [self updateFollowStatusForSelectedVideoInControlsController:aVideoModel.isVideoFollowing];

    if (aVideoModel.playbackURI)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          self.isFetchPlayBackURIWithMaxBitRate = NO;
          [self playVideoForURI:aVideoModel.playbackURI forIndexPath:aIndexPath];
          self.controlsViewController.placeholderText.text = aVideoModel.title; // We are adding this from BC Merge
          self.controlsViewController.videoModal = aVideoModel;
          [self addChannelLogoForControlsControllerInLandScapeMode];
        }];
    }
    else
    {
        if ([self.mFetchingVideoIndexPathArray containsObject:aIndexPath])
        {
            NSLog(@"Request is already in progress to get playbackUri For VideoId:%@", aVideoModel.uniqueId);
            return;
        }
        else
        {
            [self.mFetchingVideoIndexPathArray addObject:aIndexPath];
        }
        NSLog(@"Send request to get playbackUri For VideoId:%@", aVideoModel.uniqueId);

        __weak PlayDetailViewController *weakSelf = self;
        NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aVideoModel.uniqueId, @"videoId", [NSNumber numberWithBool:self.isFetchPlayBackURIWithMaxBitRate], @"isMaxBitRate", nil];
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetPlaybackURIForVideoId:aDict
            responseBlock:^(NSDictionary *responseDict) {
              weakSelf.isFetchPlayBackURIWithMaxBitRate = NO;
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if ([weakSelf.mFetchingVideoIndexPathArray containsObject:aIndexPath])
                {
                    [weakSelf.mFetchingVideoIndexPathArray removeObject:aIndexPath];
                }
                NSString *aPlaybackURI = [responseDict objectForKey:@"uri"];
                NSDictionary *aLogDataDict = [responseDict objectForKey:@"logData"];
                if (aLogDataDict)
                {
                    aVideoModel.logData = aLogDataDict;
                }
                if (aPlaybackURI)
                {
                    aVideoModel.playbackURI = aPlaybackURI;
                    [weakSelf playVideoForURI:aPlaybackURI forIndexPath:aIndexPath];
                    self.controlsViewController.placeholderText.text = aVideoModel.title; // We are adding this from BC Merge
                    self.controlsViewController.videoModal = aVideoModel;
                    [self addChannelLogoForControlsControllerInLandScapeMode];
                }
                else
                {
                    NSLog(@"Error in getting playback URI");
                }
              }];

            }
            errorBlock:^(NSError *error) {
              NSLog(@"Error-%@", error.localizedDescription);

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if ([weakSelf.mFetchingVideoIndexPathArray containsObject:aIndexPath])
                {
                    [weakSelf.mFetchingVideoIndexPathArray removeObject:aIndexPath];
                }
                NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aIndexPath, @"indexPath", [NSNumber numberWithBool:YES], @"isPlayblackURIFail", nil];
                [weakSelf performSelector:@selector(createVideoLoadingFailureErrorView:) withObject:aDict afterDelay:.5];
              }];
            }];
    }
}

- (void)postVideoProgressToServerForVideoId:(NSString *)aVideoId withProgressStatus:(NSString *)aProgressStatus
{
    NSLog(@"postVideoProgressToServerForVideoId WITHID=%@", aVideoId);
    __weak PlayDetailViewController *weakSelf = self;

    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aVideoId, @"videoId", aProgressStatus, @"progressTime", nil];
    [[ServerConnectionSingleton sharedInstance] sendRequestToUpdateVideoProgressTime:aDict
                                                                       responseBlock:^(NSDictionary *responseDict) {
                                                                         [weakSelf performSelectorOnMainThread:@selector(updateUserHistoryForVideoModel:) withObject:responseDict waitUntilDone:NO];
                                                                       }
                                                                          errorBlock:^(NSError *error){

                                                                          }];
}

- (void)onSuccessfullVideoProgressPostForVideoModel:(NSDictionary *)aDict
{
    [self updateUserHistoryForVideoModel:aDict];
}

- (void)updateUserHistoryForVideoModel:(NSDictionary *)aDict
{
    NSString *aVideoId = [aDict objectForKey:@"videoId"];
    NSString *aProgressTime = [aDict objectForKey:@"progressTime"];
    NSNumber *aUpdatedTimeStamp = [aDict objectForKey:@"lastUpdatedTime"];
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", aVideoId];
    NSArray *aArray = [self.mVideoListDataSource filteredArrayUsingPredicate:aPredicate];

    if (aArray.count)
    {
        VideoModel *aVideoModel = [aArray objectAtIndex:0];
        [[DBHandler sharedInstance] updateOrInsertHistoryAsset:aVideoModel withVideoProgressTime:aProgressTime withUpdatedTimeStamp:aUpdatedTimeStamp];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdatedHistoryAssetInCoreDataNotification object:nil userInfo:nil];
    }
}
- (void)updateProviderDeatils:(ProviderModel *)aModel
{
    NSIndexPath *indexPAth = [NSIndexPath indexPathForRow:0 inSection:0];

    PlayGenreGenreFirstCollectionViewCell *aCell = (PlayGenreGenreFirstCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:indexPAth];
    if (aCell)
    {
        [self upDateMoreFromPublisherLabel:aModel forCell:aCell];
    }
}

- (void)upDateMoreFromPublisherLabel:(ProviderModel *)aModel forCell:(PlayGenreGenreFirstCollectionViewCell *)aCell
{
    UIFont *font1 = [UIFont fontWithName:@"Lato-Regular" size:15.0];
    UIFont *font2 = [UIFont fontWithName:@"Lato-Bold" size:15.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *fontAttributes1 = [[NSDictionary alloc] initWithObjectsAndKeys:font1, NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    NSDictionary *fontAttributes2 = [[NSDictionary alloc] initWithObjectsAndKeys:font2, NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];

    NSAttributedString *aMoreAttributeStr = [[NSAttributedString alloc] initWithString:@"More from " attributes:fontAttributes1];

    NSAttributedString *aPublisherStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", aModel.title] attributes:fontAttributes2];

    NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] init];

    [buttonTitle appendAttributedString:aMoreAttributeStr];
    [buttonTitle appendAttributedString:aPublisherStr];

    NSDictionary *disableFontAttributes1 = [[NSDictionary alloc] initWithObjectsAndKeys:font1, NSFontAttributeName, [UIColor grayColor], NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    NSDictionary *disableFontAttributes2 = [[NSDictionary alloc] initWithObjectsAndKeys:font2, NSFontAttributeName, [UIColor grayColor], NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];

    NSAttributedString *aDisableMoreAttributeStr = [[NSAttributedString alloc] initWithString:@"More from " attributes:disableFontAttributes1];

    NSAttributedString *aDisablePublisherStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", aModel.title] attributes:disableFontAttributes2];

    NSMutableAttributedString *disableButtonTitle = [[NSMutableAttributedString alloc] init];

    [disableButtonTitle appendAttributedString:aDisableMoreAttributeStr];
    [disableButtonTitle appendAttributedString:aDisablePublisherStr];

    [aCell.providerButton setAttributedTitle:buttonTitle forState:UIControlStateNormal];
    [aCell.providerButton setAttributedTitle:disableButtonTitle forState:UIControlStateDisabled];

    if (aModel.title == nil)
    {
        aCell.providerButton.hidden = YES;
    }
    else
    {
        aCell.providerButton.hidden = NO;
    }
}

- (void)updateDataSource:(NSArray *)aArray
{
    [self.mVideoListDataSource removeAllObjects];
    [self.mVideoListDataSource addObjectsFromArray:aArray];

    if (isCoreSpotLightEnable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setItemsForSpotlightBeforeReload:aArray];
        });
    }

    [self updateChannelSubscriptionStatusForVideoModelsInGenre];

    if (self.mVideoListDataSource.count)
        self.mCollectionView.scrollEnabled = YES;

    [self.mCollectionView reloadData];

    //find the latest video cell index
    if (self.isPlayLatestVideo)
    {
        self.isPlayLatestVideo = NO;
        self.canSelectCell = NO;
        [self performSelector:@selector(scrollToLatestVideoCell) withObject:nil afterDelay:.5];
    }

    self.mScrollHeightForBreakLock = self.mCollectionView.collectionViewLayout.collectionViewContentSize.height - 130 - (self.view.frame.size.width / 2) - 100;
}

// Enumerate items and add for indexing

- (void)setItemsForSpotlightBeforeReload:(NSArray *)arrayModal
{
    for (VideoModel *vModal in arrayModal)
    {
        [self setSearchableItem:vModal image:nil];
    }
}

// Set Each items to index using Corespotlight

- (void)setSearchableItem:(VideoModel *)videoModel image:(UIImage *)img
{
    VideoModel *vModel = videoModel;

    //  Set Attribute set for adding image for elements
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeImage];
    if (img != nil)
    {
        NSData *dataImg = UIImagePNGRepresentation(img);
        attributeSet.thumbnailData = dataImg;
    }
    attributeSet.title = vModel.title;
    attributeSet.contentDescription = vModel.shortDescription;
    attributeSet.keywords = @[ vModel.title ];

    NSString *strUniqueId = self.isFromPlayList ? [NSString stringWithFormat:@"%@,%@,%@,%@", kDeepLinkVideoIdKey, vModel.uniqueId, kDeepLinkPlayListIdKey, self.mDataModel.uniqueId] : [NSString stringWithFormat:@"%@,%@,%@,%@", kDeepLinkVideoIdKey, vModel.uniqueId, kDeepLinkShowIdKey, self.mChannelDataModel.uniqueId];

    CSSearchableItem *item = [[CSSearchableItem alloc]
        initWithUniqueIdentifier:strUniqueId
                domainIdentifier:@"com.wtchable"
                    attributeSet:attributeSet];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ]
                                                   completionHandler:^(NSError *__nullable error){
                                                       //if (!error)
                                                       //NSLog(@"Video item indexed");
                                                   }];
}

- (void)scrollToLatestVideoCell
{
    self.canSelectCell = YES;
    if (self.mVideoListDataSource.count > 0)
    {
        NSString *aNextVideoUniqueId = self.mChannelDataModel.nextVideoUnderchannel.uniqueId;
        __block NSIndexPath *aIndexPath = nil;
        if (aNextVideoUniqueId.length)
        {
            [self.mVideoListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

              VideoModel *aVideoModel = (VideoModel *)obj;

              if ([aVideoModel.uniqueId isEqualToString:self.mChannelDataModel.nextVideoUnderchannel.uniqueId])
              {
                  aIndexPath = [NSIndexPath indexPathForItem:idx + 1 inSection:0];
                  return;
              }
            }];
        }

        if (aIndexPath)
        {
            [self hideBackButton:NO];
            [self hideNarBarWithShareAddButton:NO];
            [self stopAndRemoveMoviePlayer];
            [self moveCollectionCellToCenterForIndexPath:aIndexPath withAnimation:NO];
            [self performSelector:@selector(highLightCollectionCellForIndexPath:) withObject:aIndexPath afterDelay:.1];
        }
    }
}

- (void)modifyDataSourceWithFollowStatus:(BOOL)status videoModel:(VideoModel *)model
{
    [self postNotificationForFollowChannelId:model.channelId withFollowStatus:status];
}
- (void)updateDataSourceWithFollowStatus:(BOOL)aFollowStatus withChannelId:(NSString *)aChannelId
{
    __weak PlayDetailViewController *weakSelf = self;

    [self.mVideoListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      VideoModel *aVideoModel = (VideoModel *)obj;

      if ([aVideoModel.channelId isEqualToString:aChannelId])
      {
          aVideoModel.isVideoFollowing = aFollowStatus;
          if (weakSelf.isVideoLocked && weakSelf.mSelectedIndexPath.row > 0)
          {
              VideoModel *aSelectedVideoModel = [weakSelf.mVideoListDataSource objectAtIndex:self.mSelectedIndexPath.row - 1];
              if ([aSelectedVideoModel.channelId isEqualToString:aChannelId])
              {
                  [self updateFollowStatusForSelectedVideoInControlsController:aVideoModel.isVideoFollowing];
              }
          }
      }
    }];

    NSArray *aVisibleCells = [self.mCollectionView visibleCells];
    for (PlayDetailCollectionViewCell *aCell in aVisibleCells)
    {
        NSIndexPath *aIndexPath = [self.mCollectionView indexPathForCell:aCell];
        if (aIndexPath.row != 0 && aIndexPath.row != self.mVideoListDataSource.count + 1)
        {
            PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[weakSelf.mCollectionView cellForItemAtIndexPath:aIndexPath];
            if (aCell)
            {
                VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
                aCell.mFollowButton.selected = aVideoModel.isVideoFollowing;
                if (aCell.mFollowButton.selected)
                {
                    aCell.mFollowButtonWidthConstraint.constant = 91.0;
                }
                else
                {
                    aCell.mFollowButtonWidthConstraint.constant = 70.0;
                }

                if (self.mDetailView && self.mDetailView.indexPath.row == aIndexPath.row)
                {
                    self.mDetailView.followButton.selected = aVideoModel.isVideoFollowing;

                    if (aVideoModel.isVideoFollowing)
                    {
                        CGRect aFrame = self.mDetailView.followButton.frame;
                        aFrame.origin.x = self.mDetailView.frame.size.width - 91 - 12;
                        aFrame.size.width = 91.0;
                        self.mDetailView.followButton.frame = aFrame;
                        self.mDetailView.followButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
                        self.mDetailView.followButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
                    }
                    else
                    {
                        CGRect aFrame = self.mDetailView.followButton.frame;
                        aFrame.origin.x = self.mDetailView.frame.size.width - 70 - 12;
                        aFrame.size.width = 70.0;
                        self.mDetailView.followButton.frame = aFrame;
                        self.mDetailView.followButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
                        self.mDetailView.followButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
                    }
                    [self.mDetailView setFollowButtonHighlightPropertyWithSelected:aVideoModel.isVideoFollowing];
                }
            }
        }
    }
}

- (void)updateFollowStatusForSelectedVideoInControlsController:(BOOL)isFollow
{
    if (self.controlsViewController)
    {
        [self.controlsViewController setChannelFollowStatus:isFollow];
    }
}

- (void)getChannelInfoForVideo:(VideoModel *)aVideoModel
{
    NSString *aChannelUrl = [aVideoModel.relatedLinks objectForKey:@"channel"];
    if (aChannelUrl.length)
    {
        [self.mChannelIDForFetchingChannelLogoArray addObject:aVideoModel.channelId];
        __weak PlayDetailViewController *weakSelf = self;
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetChannelInfoWithURL:aChannelUrl
            responseBlock:^(NSArray *responseArray) {

              if (weakSelf)
              {
                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    if (responseArray.count)
                    {
                        ChannelModel *aChannelModel = [responseArray objectAtIndex:0];

                        if ([weakSelf.mChannelIDForFetchingChannelLogoArray containsObject:aVideoModel.channelId])
                        {
                            [weakSelf.mChannelIDForFetchingChannelLogoArray removeObject:aVideoModel.channelId];
                        }

                        NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"channelId == %@", aVideoModel.channelId];

                        NSArray *aVideoModelArray = [weakSelf.mVideoListDataSource filteredArrayUsingPredicate:aPredicate];

                        [aVideoModelArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

                          __block VideoModel *aVideoModel = (VideoModel *)obj;
                          aVideoModel.channelInfo = aChannelModel;

                        }];

                        if (self.mSelectedIndexPath != nil && self.mSelectedIndexPath.row != 0 && self.mSelectedIndexPath.row != self.mVideoListDataSource.count + 1)
                        {
                            VideoModel *aVideoModel = [weakSelf.mVideoListDataSource objectAtIndex:self.mSelectedIndexPath.row - 1];
                            if ([aVideoModel.channelId isEqualToString:aVideoModel.channelId])
                            {
                                if (self.isMoviePlayerInFullScreen)
                                {
                                    [self addChannelLogoForControlsControllerInLandScapeMode];
                                }
                            }
                        }

                        [weakSelf getVisibleCellsAndUpdateChannelImageURLForChannelId:aChannelModel.uniqueId];
                    }

                  }];
              }

            }
            errorBlock:^(NSError *error) {

              if ([weakSelf.mChannelIDForFetchingChannelLogoArray containsObject:aVideoModel.channelId])
              {
                  [weakSelf.mChannelIDForFetchingChannelLogoArray removeObject:aVideoModel.channelId];
              }

            }];
    }
}

- (void)getVisibleCellsAndUpdateChannelImageURLForChannelId:(NSString *)aChannelId
{
    __weak PlayDetailViewController *weakSelf = self;
    NSArray *aVisibleCollectionViewIndexs = [weakSelf.mCollectionView indexPathsForVisibleItems];
    [aVisibleCollectionViewIndexs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      NSIndexPath *aIndexPath = (NSIndexPath *)obj;

      if (aIndexPath.item != 0 && aIndexPath.item <= weakSelf.mVideoListDataSource.count)
      {
          VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.item - 1];
          if ([aVideoModel.channelId isEqualToString:aChannelId])
          {
              __block PlayDetailCollectionViewCell *aPlayDetailCollectionViewCell = (PlayDetailCollectionViewCell *)[weakSelf.mCollectionView cellForItemAtIndexPath:aIndexPath];

              NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:aVideoModel.channelInfo.imageUri ForImageType:Horizontal_lc_logo withSize:CGSizeMake(aPlayDetailCollectionViewCell.mBrandLogoImageView.frame.size.width, aPlayDetailCollectionViewCell.mBrandLogoImageView.frame.size.height)];

              aPlayDetailCollectionViewCell.mBrandLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
              [aPlayDetailCollectionViewCell.mBrandLogoImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                                                   placeholderImage:nil
                                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                                          }];

              if (self.mDetailView && self.mDetailView.indexPath.row == aIndexPath.row)
              {
                  weakSelf.mDetailView.publisherImageView.contentMode = UIViewContentModeScaleAspectFit;
                  [weakSelf.mDetailView.publisherImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                                             placeholderImage:nil
                                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                                    }];
              }
          }
      }

    }];
}
#pragma mark
#pragma mark UICollectionView DataSource Method

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.isFromGenre)
    {
        if (self.mVideoListDataSource.count)
        {
            return self.mVideoListDataSource.count + 2;
        }
        else if (self.mChannelDataModel)

        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else if (self.mDataModel)
    {
        return self.mVideoListDataSource.count + 2;
    }
    return 0;
}

- (void)addChannelLogoForControlsControllerInLandScapeMode
{
    if (self.mSelectedIndexPath != nil && self.mSelectedIndexPath.row != 0 && self.mSelectedIndexPath.row != self.mVideoListDataSource.count + 1)
    {
        VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:self.mSelectedIndexPath.row - 1];

        if (self.isFromPlayList)
        {
            if (aModel.channelInfo)
            {
                NSString *brandLogoURLString = aModel.channelInfo.imageUri;
                if (brandLogoURLString)
                {
                    if (self.controlsViewController)
                    {
                        [self.controlsViewController setProviderImageForUrl:brandLogoURLString];
                    }
                }
                else
                {
                    self.controlsViewController.PublisherImg.image = nil;
                }
            }
            else
            {
                if (![self.mChannelIDForFetchingChannelLogoArray containsObject:aModel.channelId])
                {
                    [self getChannelInfoForVideo:aModel];
                }
                self.controlsViewController.PublisherImg.image = nil;
            }
        }
        else if (self.isEpisodeClicked || self.isLogoClicked || self.isFromGenre)
        {
            [self.controlsViewController setProviderImageForUrl:self.mChannelDataModel.imageUri];
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        if (self.isFromGenre)
        {
            PlayGenreGenreFirstCollectionViewCell *aCell = (PlayGenreGenreFirstCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PlayGenreGenreFirstCollectionViewCell" forIndexPath:indexPath];
            [aCell.mPlayButton addTarget:self action:@selector(onClickingBGViewPlayButton:) forControlEvents:UIControlEventTouchUpInside];

            aCell.providerButton.userInteractionEnabled = NO;

            if (self.mChannelDataModel && !self.isFromProvider)
            {
                aCell.providerButton.userInteractionEnabled = YES;
                [aCell.providerButton addTarget:self action:@selector(onproviderAction:) forControlEvents:UIControlEventTouchUpInside];
            }
            else
            {
                aCell.providerButton.userInteractionEnabled = YES;
                [aCell.providerButton addTarget:self action:@selector(popController) forControlEvents:UIControlEventTouchUpInside];
            }

            if (self.mProviderModal)
            {
                [self upDateMoreFromPublisherLabel:self.mProviderModal forCell:aCell];
            }
            else
            {
                aCell.providerButton.hidden = YES;
            }

            float aHeightStr = self.view.frame.size.height;
            NSString *imageUrlString = nil;
            if (aHeightStr > 480)
            {
                imageUrlString = [ImageURIBuilder buildImageUrlWithString:self.mChannelDataModel.relatedLinks[@"default-image"] ForImageType:Cover_art withSize:CGSizeMake(aCell.frame.size.width, aCell.mVideoImageView.frame.size.height)];
            }
            else
            {
                imageUrlString = [ImageURIBuilder buildImageUrlWithString:self.mChannelDataModel.relatedLinks[@"default-image"] ForImageType:Cover_art withSize:CGSizeMake(aCell.frame.size.width, 400)];
            }

            aCell.mVideoImageView.contentMode = UIViewContentModeScaleAspectFill;

            CGRect aFrame = aCell.mVideoImageView.frame;
            aFrame.size.width = aCell.frame.size.width;
            aCell.mVideoImageView.frame = aFrame;

            if (imageUrlString)
            {
                [aCell.mVideoImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                         placeholderImage:nil
                                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                }];
            }
            else
            {
                aCell.mVideoImageView.image = nil;
            }

            NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:self.mChannelDataModel.relatedLinks[@"default-image"] ForImageType:Horizontal_logo withSize:CGSizeMake(aCell.mProviderImageView.frame.size.width, aCell.mProviderImageView.frame.size.height)];

            float aWidth = 0.0;
            float aHeight = 0.0;

            aWidth = (self.view.frame.size.width - 24.0);
            if (aWidth > 351.0)
            {
                aWidth = 351.0;
            }

            aHeight = (aWidth * 22.0) / 190.0;
            aCell.mChannelLogoImageViewWidthConstraint.constant = aWidth;
            aCell.mChannelLogoImageViewHeightConstraint.constant = aHeight;
            aCell.mProviderImageView.backgroundColor = [UIColor clearColor];
            if (providerImageUrlString)
            {
                aCell.mProviderImageView.contentMode = UIViewContentModeScaleAspectFit;
                [aCell.mProviderImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                            placeholderImage:nil
                                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                   }];
            }
            else
            {
                aCell.mProviderImageView.image = nil;
            }

            NSString *categoryLabelText = nil;
            if (self.mGenreDataModel.genreTitle && (![self.mGenreDataModel.genreTitle isEqualToString:@""]))
            {
                categoryLabelText = [[NSString stringWithFormat:@"  %@  ", self.mGenreDataModel.genreTitle] uppercaseString];
            }
            else
            {
                categoryLabelText = [@"  genre  " uppercaseString];
            }

            NSMutableAttributedString *attributedStringForCategory = [[NSMutableAttributedString alloc] initWithString:categoryLabelText];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            [attributedStringForCategory addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [categoryLabelText length])];
            aCell.mVideoCategoryLabel.attributedText = attributedStringForCategory;

            aCell.mVideoDescLabel.text = self.mChannelDataModel.showDescription;
            [Utilities addGradientToPlayDetailFirstCellImageView:aCell.mVideoImageView];
            return aCell;
        }
        else
        {
            if (self.mDataModel)
            {
                PlayDetailFirstCollectionViewCell *aCell = (PlayDetailFirstCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PlayDetailFirstCollectionViewCell" forIndexPath:indexPath];
                [aCell.mPlayButton addTarget:self action:@selector(onClickingBGViewPlayButton:) forControlEvents:UIControlEventTouchUpInside];

                CGRect aFrame = aCell.mVideoImageView.frame;
                aFrame.size.width = aCell.frame.size.width;
                aCell.mVideoImageView.frame = aFrame;
                aCell.mVideoImageView.contentMode = UIViewContentModeScaleAspectFill;

                float aHeightStr = self.view.frame.size.height;
                NSString *imageUrlString = nil;
                if (aHeightStr > 480)
                {
                    imageUrlString = [ImageURIBuilder buildURLWithString:self.mDataModel.imageUri withSize:CGSizeMake(aCell.frame.size.width, aCell.mVideoImageView.frame.size.height)];
                }
                else
                {
                    imageUrlString = [ImageURIBuilder buildURLWithString:self.mDataModel.imageUri withSize:CGSizeMake(aCell.frame.size.width, 400)];
                }
                if (imageUrlString)
                {
                    [aCell.mVideoImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                             placeholderImage:nil
                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                    }];
                }
                else
                {
                    aCell.mVideoImageView.image = nil;
                }

                UIFont *afont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:42.0];
                NSDictionary *attr = @{NSFontAttributeName : afont, NSForegroundColorAttributeName : [UIColor whiteColor]};
                NSString *aStr = [self.mDataModel.title uppercaseString];
                NSMutableAttributedString *aAttributedString = [[NSMutableAttributedString alloc] initWithString:aStr attributes:attr];

                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.lineHeightMultiple = 0.8;
                paragraphStyle.alignment = NSTextAlignmentCenter;
                [aAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [aStr length])];
                paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
                aCell.mVideoTitleLabel.attributedText = aAttributedString;

                NSString *categoryLabelText = nil;
                if (self.mDataModel.genreTitle && (![self.mDataModel.genreTitle isEqualToString:@""]))
                {
                    categoryLabelText = [[NSString stringWithFormat:@"  %@  ", self.mDataModel.genreTitle] uppercaseString];
                }
                else
                {
                    categoryLabelText = [@"  genre  " uppercaseString];
                }

                NSMutableAttributedString *attributedStringForCategory = [[NSMutableAttributedString alloc] initWithString:categoryLabelText];
                NSMutableParagraphStyle *aparagraphStyle = [[NSMutableParagraphStyle alloc] init];
                [attributedStringForCategory addAttribute:NSParagraphStyleAttributeName value:aparagraphStyle range:NSMakeRange(0, [categoryLabelText length])];

                aCell.mVideoCategoryLabel.attributedText = attributedStringForCategory;

                aCell.mVideoDescLabel.text = self.mDataModel.shortDescription;
                aCell.mNoOfVideosLabel.text = [NSString stringWithFormat:@"%@ videos / %@", self.mDataModel.totalVideos, [TimeUtils durationStringForDuration:[self.mDataModel.totalVideoDuration doubleValue]]];

                [Utilities addGradientToPlayDetailFirstCellImageView:aCell.mVideoImageView];

                return aCell;
            }
        }
    }

    PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PlayDetailCollectionViewCell" forIndexPath:indexPath];

    aCell.mVideoImageView.layer.cornerRadius = 1.0;
    aCell.mVideoImageView.layer.masksToBounds = YES;

    UITapGestureRecognizer *aTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapForImageView:)];
    aCell.mBrandLogoImageView.tag = indexPath.row;
    aCell.mBrandLogoImageView.userInteractionEnabled = YES;
    [aCell.mBrandLogoImageView addGestureRecognizer:aTapGestureRecognizer];
    aCell.mBrandLogoImageView.backgroundColor = [UIColor clearColor];
    if (indexPath.row == self.mVideoListDataSource.count + 1)
    {
        aCell.alpha = 0.0;
        aCell.mVideoImageView.image = nil;
        aCell.mVideoImageView.backgroundColor = [UIColor clearColor];
        aCell.mBrandLogoImageView.image = nil;
        aCell.mVideoDescLabel.text = nil;
        aCell.mFollowButton.hidden = YES;
        aCell.mVideoDurationLabel.text = @"";
        return aCell;
    }
    aCell.alpha = 1.0;
    VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:indexPath.row - 1];

    aCell.mVideoDurationLabel.text = @"";
    [aCell bringSubviewToFront:aCell.mVideoDurationLabel];
    if (aModel.duration.length)
    {
        NSString *aFormatedDurationString = [TimeUtils durationStringForDuration:aModel.duration.doubleValue];
        aCell.mVideoDurationLabel.text = aFormatedDurationString;
    }
    aCell.mFollowButton.selected = aModel.isVideoFollowing;

    aCell.mFollowButton.hidden = NO;
    aCell.mFollowButton.mIndexPath = indexPath;
    [aCell.mFollowButton addTarget:self action:@selector(onClickingFollowButton:) forControlEvents:UIControlEventTouchUpInside];

    if (aCell.mFollowButton.selected)
    {
        aCell.mFollowButtonWidthConstraint.constant = 91.0;
    }
    else
    {
        aCell.mFollowButtonWidthConstraint.constant = 70.0;
    }

    float aWidth = self.view.frame.size.width;
    float aHeight = (aWidth / 16) * 9;
    NSString *imageUrlString = [ImageURIBuilder build2XImageUrlWithString:aModel.imageUri ForImageType:Two2One_logo withSize:CGSizeMake(aWidth, aHeight)];

    aCell.mVideoImageView.image = nil;

    //logoEmptyState
    if (imageUrlString)
    {
        [aCell.mVideoImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                 placeholderImage:[UIImage imageNamed:@"logoEmptyState.png"]
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {

                                          if (isCoreSpotLightEnable)
                                          {
                                              [self deleteOldItemAddAgainSearchableItem:aModel image:image];
                                          }

                                        }];
    }
    else
    {
        aCell.mVideoImageView.image = [UIImage imageNamed:@"logoEmptyState.png"];
    }

    if (self.isFromPlayList)
    {
        if (aModel.channelInfo)
        {
            NSString *brandLogoURLString = aModel.channelInfo.imageUri;
            if (brandLogoURLString)
            {
                NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:brandLogoURLString ForImageType:Horizontal_lc_logo withSize:CGSizeMake(aCell.mBrandLogoImageView.frame.size.width, aCell.mBrandLogoImageView.frame.size.height)];

                aCell.mBrandLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
                [aCell.mBrandLogoImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                             placeholderImage:nil
                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                    }];
            }
            else
            {
                aCell.mBrandLogoImageView.image = nil;
            }
        }
        else
        {
            if (![self.mChannelIDForFetchingChannelLogoArray containsObject:aModel.channelId])
            {
                [self getChannelInfoForVideo:aModel];
            }
            aCell.mBrandLogoImageView.image = nil;
        }
    }
    else
    {
        aCell.mBrandLogoImageView.image = nil;
    }
    aCell.mBrandLogoImageView.hidden = NO;
    aCell.mFollowButton.hidden = NO;
    aCell.mVideoDescLabel.text = aModel.title;
    aCell.mVideoTitleLabel.hidden = YES;

    if (!self.isFromPlayList)
    {
        aCell.mFollowButton.hidden = YES;
        aCell.mBrandLogoImageView.hidden = YES;
        aCell.mBrandLogoImageViewHeightConstraint.constant = 0.0;
        aCell.mSpaceBetweenBrandLogoImageViewAndDescLabelConstraint.constant = 0.0;
    }

    float aCellImageXAxis = 12;
    aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
    aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
    return aCell;
}

// Delete previously added searchable item and add new item with image
- (void)deleteOldItemAddAgainSearchableItem:(VideoModel *)aModel image:(UIImage *)img
{
    NSString *strUniqueId = self.isFromPlayList ? [NSString stringWithFormat:@"%@,%@,%@,%@", kDeepLinkVideoIdKey, aModel.uniqueId, kDeepLinkPlayListIdKey, self.mDataModel.uniqueId] : [NSString stringWithFormat:@"%@,%@,%@,%@", kDeepLinkVideoIdKey, aModel.uniqueId, kDeepLinkShowIdKey, self.mChannelDataModel.uniqueId];

    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[ strUniqueId ]
                                                                   completionHandler:^(NSError *_Nullable error) {

                                                                     [self setSearchableItem:aModel image:img];
                                                                   }];
}

- (void)addContentOffSetHeight:(float)aHeight
{
    if (!self.isCollectionViewContentOffsetHeightAdded)
    {
        self.mCollectionViewContentOffsetHeight = self.mCollectionViewContentOffsetHeight + aHeight;
    }
}

#pragma mark
#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float CellImageDiff = 24.0;

    if (indexPath.row == 0 || indexPath.row == self.mVideoListDataSource.count + 1)
    {
        if (indexPath.row == 0)
        {
            float aHeight = self.view.frame.size.height <= 480 ? 400 : 500;
            [self addContentOffSetHeight:aHeight];
            return CGSizeMake(self.view.frame.size.width, aHeight);
        }

        if (self.mVideoListDataSource.count)
        {
            self.isCollectionViewContentOffsetHeightAdded = YES;
        }

        return CGSizeMake(self.view.frame.size.width, 130);
    }

    VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:indexPath.row - 1];
    CGRect labelRect = [aModel.title
        boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, 40)
                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                  attributes:@{
                      NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:14.0]
                  }
                     context:nil];

    float height = (((self.view.frame.size.width - CellImageDiff) / 16) * 9) + 20 + 22 + 10 + (labelRect.size.height > 20 ? 39 : 20) + 46 + 10;
    if (!self.isFromPlayList)
    {
        height = height - 32;
    }
    if (!(self.mVideoListDataSource.count && self.mVideoListDataSource.count == indexPath.row))
    {
        [self addContentOffSetHeight:height];
    }

    return CGSizeMake(self.view.frame.size.width, height);
}

#pragma mark
#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.canSelectCell)
    {
        if (indexPath.row > 0)
        {
            VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:indexPath.row - 1];
            [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                                 action:@"Taps on Video to play"
                                                  label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                               andValue:nil];

            if (self.mSelectedIndexPath && self.mSelectedIndexPath.row == indexPath.row)
            {
                if (!self.isDetailViewOverLayVisible)
                {
                    [self.controlsViewController tooglePlayerControls];
                }
                else
                {
                    [self.controlsViewController tooglePlayerControls];
                }
            }
            else
            {
                self.mSelectedIndexPath = nil;
                NSLog(@"didSelectItemAtIndexPath");
                [self hideBackButton:NO];
                [self hideNarBarWithShareAddButton:NO];

                [self stopAndRemoveMoviePlayer];
                [self removeBlurEffectOnVisibleCellsWithAnimationDuration:.1 withResizingCell:NO];
                [self moveToCenterAndHighLightCollectionCellForIndexPath:indexPath highlightWithDelay:.3];
                self.controlsViewController.placeholderText.text = aModel.title;
                [self addChannelLogoForControlsControllerInLandScapeMode];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == self.mSelectedIndexPath && indexPath.row != 0 && indexPath.row != self.mVideoListDataSource.count + 1)
    {
        NSLog(@"end display cell index=%ld", indexPath.row);
        [self stopAndRemoveMoviePlayer];
        PlayDetailCollectionViewCell *acell = (PlayDetailCollectionViewCell *)cell;
        acell.alpha = 1.0;

        acell.mBrandLogoImageView.hidden = NO;
        acell.mFollowButton.hidden = NO;
        acell.mVideoTitleLabel.hidden = YES;
        acell.mVideoDescLabel.hidden = NO;

        if (!self.isFromPlayList)
        {
            acell.mFollowButton.hidden = YES;
        }

        float aCellImageXAxis = 12;
        acell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
        acell.mImageViewTrailingConstraint.constant = aCellImageXAxis;

        acell.mBrandLogoAndDescBGView.alpha = 1.0;
        acell.mFollowButton.userInteractionEnabled = YES;
        acell.mBrandLogoImageView.userInteractionEnabled = YES;
        self.mSelectedIndexPath = nil;
    }
}

- (void)handleTapForImageView:(UITapGestureRecognizer *)aGesture
{
    UIImageView *aBrandLogoImageView = (UIImageView *)aGesture.view;
    NSInteger arrayindex = aBrandLogoImageView.tag - 1;
    VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:arrayindex];
    NSLog(@"channel id=%@", aModel.channelId);
    self.mClickedVideoModelShowLogo = aModel;
    [self onSelectingLogoImageWithVideoModel:aModel];
}

- (void)onSelectingLogoImageWithVideoModel:(VideoModel *)aVideoModel
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Show Logo"
                                          label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                       andValue:nil];
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mVideoModel = aVideoModel;
    aPlayListDetailViewController.isLogoClicked = YES;
    if (self.isVideoLocked)
    {
        self.mPreviousVideoPlayIndex = self.mSelectedIndexPath.item;
    }
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}
#pragma mark
#pragma mark UIScrollView Delegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (self.isDetailViewOverLayVisible)
    {
        return NO;
    }
    [self stopAndRemoveMoviePlayer];
    [self breakVideoLockSetUp];
    [self performSelector:@selector(removeBlurEffectAfterdelay) withObject:nil afterDelay:0.3];

    return YES;
}

- (void)removeBlurEffectAfterdelay
{
    [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isVideoLockedRef = self.isVideoLocked;
    [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self onScrollingFinish];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self onScrollingFinish];
}
- (void)onScrollingFinish
{
    //enter code here

    if (self.isVideoLocked)
    {
        NSIndexPath *aIndexPath = [self findCenterCollectionCellIndexPath];
        [self playCenterCellVideoWithIndex:aIndexPath];
    }
}

- (void)playCenterCellVideoWithIndex:(NSIndexPath *)aSelectIndexPath
{
    NSIndexPath *aIndexPath = aSelectIndexPath;
    if (self.mSelectedIndexPath == aIndexPath && aIndexPath != nil)
    {
        [self moveCollectionCellToCenterForIndexPath:aIndexPath withAnimation:YES];
        [self applyBlurEffectOnVisibleCellsWithSelectedIndexPath:aIndexPath];
        [self dimSelectedCellDetailViewAfterDelay];
        return;
    }
    self.mSelectedIndexPath = nil;
    [self stopAndRemoveMoviePlayer];
    if (aIndexPath)
    {
        if (aIndexPath.row == 0 || aIndexPath.row > self.mVideoListDataSource.count)
        {
            [self breakVideoLockSetUp];
            [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];
            if (aIndexPath.row > self.mVideoListDataSource.count)
                [self.mCollectionView scrollToItemAtIndexPath:aIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            self.mSelectedIndexPath = nil;
        }
        else
        {
            [self moveToCenterAndHighLightCollectionCellForIndexPath:aIndexPath highlightWithDelay:0.3];
            [self preventCellDidSelectionForDuration:0.5];
            NSLog(@" playCenterCellVideo=%ld", aIndexPath.row);
        }
    }
    else
    {
        self.mSelectedIndexPath = nil;
        [self breakVideoLockSetUp];
        [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];
    }
}

- (NSIndexPath *)findCenterCollectionCellIndexPath
{
    NSIndexPath *aIndexPath = nil;
    //loop it for - first time if not able to find the cell (can happen if seperated distance is in the specified position)
    for (int x = 0; x < 2; x++)
    {
        CGPoint aPoint = CGPointMake(self.mCollectionView.center.x + self.mCollectionView.contentOffset.x, self.mCollectionView.center.y + self.mCollectionView.contentOffset.y + (x * 10));
        NSLog(@"height=%f", self.view.frame.size.height);
        aIndexPath = [self.mCollectionView indexPathForItemAtPoint:aPoint];
        if (aIndexPath != nil)
        {
            break;
        }
    }

    if (aIndexPath.row == 0)
    {
        aIndexPath = nil;
    }
    NSLog(@"findCenterCollectionCellIndexPath -%@", aIndexPath);
    return aIndexPath;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    self.isVideoLockedRef = self.isVideoLocked;
    [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    __weak PlayDetailViewController *weakSelf = self;
    float aHeight = self.view.frame.size.height <= 480 ? 400 : 500;
    CGRect aCellFrame = CGRectMake(0, 0, self.view.frame.size.width, aHeight);
    if (scrollView.contentOffset.y < 100)
    {
        if (self.isFromGenre)
        {
            PlayGenreGenreFirstCollectionViewCell *aCell = (PlayGenreGenreFirstCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (scrollView.contentOffset.y < 0)
            {
                aCellFrame.origin.y = scrollView.contentOffset.y;
                aCellFrame.size.height = aCellFrame.size.height - scrollView.contentOffset.y;
            }
            aCell.frame = aCellFrame;
            [Utilities addGradientToPlayDetailFirstCellImageView:aCell.mVideoImageView];
        }
        else
        {
            PlayDetailFirstCollectionViewCell *aCell = (PlayDetailFirstCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (scrollView.contentOffset.y < 0)
            {
                aCellFrame.origin.y = scrollView.contentOffset.y;
                aCellFrame.size.height = aCellFrame.size.height - scrollView.contentOffset.y;
            }
            aCell.frame = aCellFrame;
            [Utilities addGradientToPlayDetailFirstCellImageView:aCell.mVideoImageView];
        }
    }
    [self setNavBarVisiblity:scrollView];

    if (scrollView.contentOffset.y > self.mScrollHeightForBreakLock)
    {
        if (self.isVideoLocked && !weakSelf.mDetailView && !self.isMoviePlayerInFullScreen)
        {
            [self stopAndRemoveMoviePlayer];
            [self breakVideoLockSetUp];
            [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];
            [self performSelector:@selector(setLastCellInCenterAfterUnlock) withObject:nil afterDelay:.2];
        }
    }
}

- (void)setLastCellInCenterAfterUnlock
{
    NSIndexPath *aIndexPath = [NSIndexPath indexPathForItem:self.mVideoListDataSource.count inSection:0];

    if ([self.mCollectionView cellForItemAtIndexPath:aIndexPath])
    {
        [self.mCollectionView scrollToItemAtIndexPath:aIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
}

- (void)setNavBarVisiblity:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;

    [self setNavigationBarTitle:self.isFromGenre ? self.mChannelDataModel.title : self.mDataModel.title withFont:nil withTextColor:nil];

    float NavBarAlpha = 0.0;

    NavBarAlpha = (aPoint.y / 348.0) * kNavBarMaxAlphaValue;

    if (NavBarAlpha > kNavBarMaxAlphaValue)
    {
        NavBarAlpha = kNavBarMaxAlphaValue;
    }
    else if (NavBarAlpha < 0.0)
    {
        NavBarAlpha = 0.0;
    }

    [self setNavBarVisiblityWithAlpha:NavBarAlpha];
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}
#pragma mark
#pragma mark Move and HighLight Cell Methods

- (void)moveCollectionCellToTopForIndexPath:(NSIndexPath *)indexPath
{
    [self ShowShareButton:NO]; //Modified AB : We are adding this line from BCMerge
    [self.mCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    [self applyBlurEffectOnVisibleCellsWithDimDetailViewForSelectedIndexPath:indexPath];

    if (CGRectIsEmpty(self.cgRectVideoView))
    {
        self.cgRectVideoView = CGRectMake(self.mCollectionView.frame.origin.x, self.isMoviePlayerInFullScreen ? -10 + kVideoPlayerYaxisDelta : 0 + kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta); //Modified AB : We are adding this line from BCMerge
    }

    self.videoView.frame = self.cgRectVideoView;

    if (indexPath.row != 0)
    {
        PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:indexPath];
        aCell.mBrandLogoImageView.hidden = YES;
        aCell.mFollowButton.hidden = YES;
        aCell.mVideoTitleLabel.hidden = YES;
        aCell.mVideoDescLabel.hidden = YES;
    }
    [MoviePlayerSingleton setDefaultControls];
}
- (void)forceToTopCollectionViewCellAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    UICollectionViewCell *cell = [self.mCollectionView cellForItemAtIndexPath:indexPath];
    CGPoint offset = CGPointMake(0, cell.frame.origin.y);
    [self.mCollectionView setContentOffset:offset animated:animated];
}
- (void)moveToCenterAndHighLightCollectionCellForIndexPath:(NSIndexPath *)aIndexPath highlightWithDelay:(float)aDelay
{
    [self moveCollectionCellToCenterForIndexPath:aIndexPath withAnimation:YES];
    [self performSelector:@selector(highLightCollectionCellForIndexPath:) withObject:aIndexPath afterDelay:0.5];
}

- (void)moveCollectionCellToCenterForIndexPath:(NSIndexPath *)indexPath withAnimation:(BOOL)animated
{
    if (self.mVideoListDataSource.count && indexPath.row <= self.mVideoListDataSource.count && indexPath)
    {
        self.isVideoLocked = YES;
        [self scrollImageViewToCenterForIndexPath:indexPath withAnimation:animated];

        ((AppDelegate *)kSharedApplicationDelegate).isVideoPlay = YES;
    }
    if ((indexPath.row == 0 || indexPath.row > self.mVideoListDataSource.count) && indexPath)
    {
        self.mPreviousVideoPlayIndex = -1;
        [self breakVideoLockSetUp];
        [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];

        if (indexPath.row > self.mVideoListDataSource.count)
        {
            if (self.isFromPlayList)
            {
                [self performSelector:@selector(popController) withObject:nil afterDelay:0.5];
            }
            else
            {
                [self performSelector:@selector(scrollToFirstCell) withObject:nil afterDelay:0.0];
            }
        }
    }
}

- (void)scrollToFirstCell
{
    self.mSelectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self stopAndRemoveMoviePlayer];
    NSIndexPath *aIndexPath = self.mSelectedIndexPath;

    if (aIndexPath)
    {
        NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row + 1 inSection:aIndexPath.section];
        [self moveCollectionCellToCenterForIndexPath:aNextIndexPath withAnimation:NO];
        [self performSelector:@selector(highLightCollectionCellForIndexPath:) withObject:aNextIndexPath afterDelay:0.5];
        [self preventCellDidSelectionForDuration:0.5];
    }

    self.mCollectionView.scrollEnabled = YES;
}

- (void)scrollImageViewToCenterForIndexPath:(NSIndexPath *)aIndexPath withAnimation:(BOOL)animated
{
    if (!animated)
    {
        [self.mCollectionView scrollToItemAtIndexPath:aIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
    }
    if (!self.deeplinkShowId)
    {
        [self setBackButtonOnNavBar];
        self.mNavBarBackButton = [self getBackButtonRef];
    }
    [self hideBackButton:NO];
    [self hideNarBarWithShareAddButton:NO];

    [self.controlsViewController fadeControlsOut];

    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aIndexPath, @"indexPath", [NSNumber numberWithBool:animated], @"isAnimated", nil];
    [self performSelector:@selector(moveCellToCenter:) withObject:aDict afterDelay:animated ? 0 : 0.03];
}
- (void)moveCellToCenter:(NSDictionary *)aDict
{
    NSIndexPath *aIndexPath = [aDict objectForKey:@"indexPath"];
    BOOL animated = [((NSNumber *)[aDict objectForKey:@"isAnimated"])boolValue];
    UICollectionViewCell *cell = [self.mCollectionView cellForItemAtIndexPath:aIndexPath];
    self.mPreviousVideoPlayIndex = aIndexPath.item;
    if (cell)
    {
        CGRect aRect = [[UIScreen mainScreen] bounds];
        float aImageViewHeight = ((aRect.size.width / 16) * 9);

        float aYaxis = cell.frame.origin.y - ((aRect.size.height - aImageViewHeight) / 2);
        if (aYaxis <= 0)
            aYaxis = 0;

        CGPoint offset = CGPointMake(0, aYaxis);
        [self.mCollectionView setContentOffset:offset animated:animated];

        self.videoLockedScrollViewContentOffSetYAxis = offset.y;
    }
    else
    {
        [self.mCollectionView scrollToItemAtIndexPath:aIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];

        [self performSelector:@selector(moveCellToCenter:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:aIndexPath, @"indexPath", [NSNumber numberWithBool:NO], @"isAnimated", nil] afterDelay:0.02];
    }
}

- (void)highLightCollectionCellForIndexPath:(NSIndexPath *)indexPath
{
    [self setCurrentPlayingVideoId:nil withTimeProgress:nil];
    [_controlsViewController setCurrentPlayingVideoId:nil withTimeProgress:nil]; // Adding thi sline from BCMerge : Modified AB
    [_controlsViewController setCurrentPlayingVideoDuration:nil];

    if (self.mVideoListDataSource.count && indexPath.row <= self.mVideoListDataSource.count)
    {
        self.mSelectedIndexPath = indexPath;

        self.mVisibleCells = [[NSMutableSet alloc] initWithArray:[self.mCollectionView visibleCells]];

        [self applyBlurEffectOnVisibleCellsWithSelectedIndexPath:indexPath];

        if (indexPath.row != 0)
            [self playMovieForHighLightedCellWithIndexPath:indexPath];
    }

    if (indexPath.row == 0)
    {
        [self breakVideoLockSetUp];
    }
}

- (void)applyBlurEffectOnVisibleCellsWithDimDetailViewForSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    if (self.mVisibleCells)
    {
        NSArray *aArray = [self.mCollectionView visibleCells];
        [self.mVisibleCells addObjectsFromArray:aArray];
    }

    for (PlayDetailCollectionViewCell *aCell in self.mVisibleCells)
    {
        NSIndexPath *aIndexPath = [self.mCollectionView indexPathForCell:aCell];
        if (aIndexPath.row == self.mVideoListDataSource.count + 1)
        {
            aCell.alpha = 0.0;
        }
        else
        {
            [UIView animateWithDuration:.3
                             animations:^{

                               if (selectedIndexPath.row == 0)
                               {
                                   aCell.alpha = 1.0;

                                   if (aIndexPath.row != 0)
                                   {
                                       float aCellImageXAxis = 12;
                                       aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                                       aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;

                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;
                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                   }
                                   return;
                               }
                               if (aIndexPath.row == 0)
                               {
                                   if (aIndexPath.row == selectedIndexPath.row)
                                   {
                                       aCell.alpha = 1.0;
                                   }
                                   else
                                   {
                                       aCell.alpha = 0.15;
                                   }
                               }

                               else
                               {
                                   float aCellImageXAxis = 0;
                                   if (aIndexPath.row != selectedIndexPath.row)
                                   {
                                       aCell.alpha = 0.15;
                                       aCellImageXAxis = 12;
                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;

                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                   }
                                   else
                                   {
                                       aCell.alpha = 1.0;

                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;

                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                   }

                                   aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                                   aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
                               }

                             }
                             completion:^(BOOL finished){

                             }];
        }
    }
}

- (void)addBlurEffectOnVisibleCells
{
    if (self.mVisibleCells)
    {
        NSArray *aArray = [self.mCollectionView visibleCells];
        [self.mVisibleCells addObjectsFromArray:aArray];
    }

    for (PlayDetailCollectionViewCell *aCell in self.mVisibleCells)
    {
        NSIndexPath *aIndexPath = [self.mCollectionView indexPathForCell:aCell];
        if (aIndexPath.row == [self.mCollectionView indexPathForCell:self.currentCell].row)
        {
            aCell.alpha = 1.0;
            [self.videoView bringSubviewToFront:aCell];
        }
        else
        {
            aCell.alpha = 0.15;
        }
    }
}

- (void)applyBlurEffectOnVisibleCellsWithSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    [self removeDimSelectedCellDetailViewSelector];
    if (self.mVisibleCells)
    {
        NSArray *aArray = [self.mCollectionView visibleCells];
        [self.mVisibleCells addObjectsFromArray:aArray];
    }

    for (PlayDetailCollectionViewCell *aCell in self.mVisibleCells)
    {
        NSIndexPath *aIndexPath = [self.mCollectionView indexPathForCell:aCell];
        if (aIndexPath.row == self.mVideoListDataSource.count + 1)
        {
            aCell.alpha = 0.0;
        }
        else
        {
            [UIView animateWithDuration:.3
                             animations:^{

                               if (selectedIndexPath.row == 0)
                               {
                                   aCell.alpha = 1.0;

                                   if (aIndexPath.row != 0)
                                   {
                                       float aCellImageXAxis = 12;
                                       aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                                       aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;

                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;
                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                       aCell.mBrandLogoAndDescBGView.alpha = 1.0;
                                       aCell.mFollowButton.userInteractionEnabled = YES;
                                       aCell.mBrandLogoImageView.userInteractionEnabled = YES;
                                   }
                                   return;
                               }
                               if (aIndexPath.row == 0)
                               {
                                   if (aIndexPath.row == selectedIndexPath.row)
                                   {
                                       aCell.alpha = 1.0;
                                   }
                                   else
                                   {
                                       aCell.alpha = 0.15;
                                   }
                               }

                               else
                               {
                                   float aCellImageXAxis = 0;
                                   if (aIndexPath.row != selectedIndexPath.row)
                                   {
                                       aCell.alpha = 0.15;
                                       aCellImageXAxis = 12;
                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;

                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                   }
                                   else
                                   {
                                       aCell.alpha = 1.0;

                                       aCell.mBrandLogoImageView.hidden = NO;
                                       aCell.mFollowButton.hidden = NO;
                                       aCell.mVideoTitleLabel.hidden = YES;
                                       aCell.mVideoDescLabel.hidden = NO;

                                       if (!self.isFromPlayList)
                                       {
                                           aCell.mFollowButton.hidden = YES;
                                       }
                                   }

                                   aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                                   aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
                                   aCell.mBrandLogoAndDescBGView.alpha = 1.0;
                                   aCell.mFollowButton.userInteractionEnabled = YES;
                                   aCell.mBrandLogoImageView.userInteractionEnabled = YES;
                               }

                             }
                             completion:^(BOOL finished){

                             }];
        }
    }
}

- (void)removeBlurEffectOnVisibleCellsWithAnimationDuration:(float)aDuration withResizingCell:(BOOL)shouldResize
{
    [self removeDimSelectedCellDetailViewSelector];

    if (self.mVisibleCells)
    {
        NSArray *aArray = [self.mCollectionView visibleCells];
        [self.mVisibleCells addObjectsFromArray:aArray];
    }

    for (PlayDetailCollectionViewCell *cell in self.mVisibleCells)
    {
        NSIndexPath *indexPath = [self.mCollectionView indexPathForCell:cell];
        if (indexPath.row == self.mVideoListDataSource.count + 1)
        {
            cell.alpha = 0.0;
        }
        else
        {
            [UIView animateWithDuration:aDuration
                             animations:^{
                               cell.alpha = 1.0;
                               if (indexPath.row != 0)
                               {
                                   cell.mBrandLogoImageView.hidden = NO;
                                   cell.mFollowButton.hidden = NO;
                                   cell.mVideoTitleLabel.hidden = YES;
                                   cell.mVideoDescLabel.hidden = NO;

                                   if (!self.isFromPlayList)
                                   {
                                       cell.mFollowButton.hidden = YES;
                                   }
                                   if (shouldResize)
                                   {
                                       float aCellImageXAxis = 12;
                                       cell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
                                       cell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
                                   }
                                   cell.mBrandLogoAndDescBGView.alpha = 1.0;
                                   cell.mFollowButton.userInteractionEnabled = YES;
                                   cell.mBrandLogoImageView.userInteractionEnabled = YES;
                               }
                             }
                             completion:^(BOOL finished){

                             }];
        }
    }
}

- (void)scrollToNextCell
{
    [self stopAndRemoveMoviePlayer];
    NSIndexPath *aIndexPath = self.mSelectedIndexPath;

    if (aIndexPath)
    {
        NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row + 1 inSection:aIndexPath.section];
        [self moveToCenterAndHighLightCollectionCellForIndexPath:aNextIndexPath highlightWithDelay:0.3];
        [self preventCellDidSelectionForDuration:0.5];
    }

    self.mCollectionView.scrollEnabled = YES;
}

- (void)scrollToPreviousCell
{
    [self stopAndRemoveMoviePlayer];

    NSIndexPath *aIndexPath = self.mSelectedIndexPath;
    if (aIndexPath)
    {
        NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row - 1 inSection:aIndexPath.section];
        [self moveToCenterAndHighLightCollectionCellForIndexPath:aNextIndexPath highlightWithDelay:0.3];
        [self preventCellDidSelectionForDuration:0.5];
    }

    self.mCollectionView.scrollEnabled = YES;
}

#pragma mark ControlsViewControllersDelegate

- (void)handleEnterFullScreenButtonPressed
{
    [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    //    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    VideoModel *aVideoModel = _controlsViewController.videoModal;
    if (aVideoModel)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Player Enter full screen"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                           andValue:nil];
    }
}

- (void)handleExitFullScreenButtonPressed
{
    VideoModel *aVideoModel = _controlsViewController.videoModal;
    if (aVideoModel)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Player Exit full screen"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                           andValue:nil];
    }

    [self onClickingMoviePlayerDoneButton];
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [self didRotate:nil];
}
- (void)tapedOnPlayer
{
    [self.controlsViewController showPlayerControls];
}

- (void)tapedOnInfoButton
{
    if (!self.isDetailViewOverLayVisible)
    {
        [self ShowShareButton:NO];
        [self hideBackButton:YES];
        [self hideNarBarWithShareAddButton:YES];

        if (!self.isMoviePlayerInFullScreen)
        {
            NSIndexPath *indexPath = [self.mCollectionView indexPathForCell:self.currentCell];
            [self moveCollectionCellToTopForIndexPath:indexPath];
            VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:indexPath.row - 1];
            [self showVideoDetails:aModel forIndexPath:indexPath];

            self.videoView.frame = self.cgRectVideoView;
            [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                                 action:@"Taps on info button on Player"
                                                  label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                               andValue:nil];
        }
        else
            [self.controlsViewController showPlayerControls];
    }
}
- (void)sharePlayingVideo
{
    //sharing in FB, Twitter, Mail
    BOOL canShowAlertForInternetFailure = NO;
    if (self.mErrorView && (self.mErrorType == InternetFailureInLandingScreenTryAgainButton || self.mErrorType == InternetFailureWithTryAgainButton || self.mErrorType == ServiceErrorWithTryAgainButton))
    {
        canShowAlertForInternetFailure = YES;
    }

    BOOL isNetworkAvaliable = [Utilities isNetworkConnectionAvaliable];

    if (!isNetworkAvaliable)
    {
        if (canShowAlertForInternetFailure)
        {
            NSString *message = NSLocalizedString(@"You're not connected to the internet", @"One of the 'generic Watchable' alert's messages");
            UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            __weak PlayDetailViewController *weakSelf = self;
            [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
        }
        return;
    }

    //check the message as per the screen

    NSString *sharingString = nil;

    if (!self.mSelectedIndexPath.row)
        return;

    VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:self.mSelectedIndexPath.row - 1];
    if (aVideoModel)
        sharingString = [aVideoModel.relatedLinks objectForKey:@"sharelink"];
    ;

    if (sharingString == nil)
    {
        NSString *message = NSLocalizedString(@"Can't share this Video at the moment.", @"One of the 'generic Watchable' alert's messages");
        UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }
    //sharing in FB, Twitter, Mail

    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Video sharing"
                                          label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                       andValue:nil];

    __weak PlayDetailViewController *weakSelf = self;

    NSString *aStr = nil;
    if (self.isFromPlayList)
    {
        aStr = @"PlayList_VideoId";
    }
    else
    {
        aStr = @"Shows_VideoId";
    }

    NSString *aBitlyKey = [NSString stringWithFormat:@"%@_%@", aStr, aVideoModel.uniqueId];

    NSString *aBitlyURL = [[DBHandler sharedInstance] getShortShareUrlForKey:aBitlyKey withLongUrl:sharingString];

    if (aBitlyURL)
    {
        [self shareVideoModel:aVideoModel withShareUrl:aBitlyURL];
    }
    else
    {
        NSString *akeyStr = nil;
        NSString *aValueStr = nil;

        if (self.isFromPlayList)
        {
            akeyStr = @"playlists";
            aValueStr = self.mDataModel.uniqueId;
        }
        else
        {
            akeyStr = @"shows";
            aValueStr = self.mChannelDataModel.uniqueId;
        }

        if (aValueStr == nil)
        {
            NSString *message = NSLocalizedString(@"Can't share this Video at the moment.", @"One of the 'generic Watchable' alert's messages");
            UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
            [self presentViewController:alert animated:YES completion:nil];

            return;
        }

        NSString *aSharedData = [NSString stringWithFormat:@"%@/%@/%@/%@", akeyStr, aValueStr, @"videos", aVideoModel.uniqueId];
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetBitlyShareUrl:sharingString
            withShareData:aSharedData
            withResponseBlock:^(NSDictionary *responseDict) {

              NSString *aShortUrl = [responseDict objectForKey:@"shortUrl"];

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[DBHandler sharedInstance] setShortShareUrlForKey:aBitlyKey withLongUrl:sharingString withValue:aShortUrl];
                [weakSelf shareVideoModel:aVideoModel withShareUrl:aShortUrl];
              }];

            }
            errorBlock:^(NSError *error) {

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (weakSelf)
                {
                    if (error.code == kErrorCodeNotReachable)
                    {
                        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                    }
                    else
                    {
                        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessageForBitlyShortURL withTryAgainSelector:nil withInputParameters:nil];
                    }
                }
              }];
            }];
    }
}

- (void)shareVideoModel:(VideoModel *)aVideoModel withShareUrl:(NSString *)sharingString
{
    NSURL *url = [NSURL URLWithString:sharingString];
    NSURL *Watchableurl = [NSURL URLWithString:kWatchableURLForShare];

    NSString *aShareText = [NSString stringWithFormat:@"Hi,\n\nI found this great video on Watchable and thought you would enjoy it:\n%@\n\n%@\n\n%@", url, @"Whether you’re looking for hit web series, ground-breaking comedy, style and food gurus, jaw-dropping extreme sports, or the latest movie trailers...Watchable has it all.", Watchableurl];
    NSString *text = aShareText;

    NSMutableArray *activityItems = [NSMutableArray array];

    CustomActivityItemProviderForSharing *activityItemProviderForTextAndURL =
        [[CustomActivityItemProviderForSharing alloc] initWithText:text
                                                           urlText:url
                                                     withShareType:eVideo
                                                             title:aVideoModel.title];

    [activityItems addObject:activityItemProviderForTextAndURL];

    CustomActivityItemProviderForSharing *activityItemProviderImageUrl =
        [[CustomActivityItemProviderForSharing alloc] initWithImageURL:url
                                                         withShareType:eVideo];

    [activityItems addObject:activityItemProviderImageUrl];

    NSString *aSubject = [NSString stringWithFormat:@"Your friend has shared a video from Watchable.com!"];

    UIActivityViewController *shareController =
        [[UIActivityViewController alloc]
            initWithActivityItems:activityItems
            applicationActivities:nil];
    [shareController setValue:aSubject forKey:@"subject"];
    shareController.excludedActivityTypes = @[
        UIActivityTypePostToWeibo,
        //UIActivityTypeMessage,
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeSaveToCameraRoll,
        UIActivityTypeAddToReadingList,
        UIActivityTypePostToFlickr,
        UIActivityTypePostToVimeo,
        UIActivityTypePostToTencentWeibo,
        UIActivityTypeAirDrop
        //UIActivityTypePostToFacebook,
        //UIActivityTypePostToTwitter
    ];
    self.mActivityViewController = shareController;

    if ([shareController respondsToSelector:@selector(completionWithItemsHandler)])
    {
        shareController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
          self.mActivityViewController = nil;
          if (!completed)
          {
              //user cancel the activity
              return;
          }
          if (activityError)
          {
              NSString *message = NSLocalizedString(@"Not able to post. Please try later", @"One of the 'generic Watchable' alert's messages");
              UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
              [self presentViewController:alert animated:YES completion:nil];

              return;
          }
          NSString *eventType = kEventTypeUserAction;
          NSString *eventName = nil;
          NSString *action = @"";

          if ([activityType rangeOfString:@"facebook" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Facebook sharing";
              eventName = kEventNameFaceBookSharingVideo;
          }
          else if ([activityType rangeOfString:@"twitter" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Twitter sharing";
              eventName = kEventNameTwitterSharingVideo;
          }
          else if ([activityType rangeOfString:@"mail" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Mail sharing";
              eventName = kEventNameEmailSharingVideo;
          }
          else if ([activityType rangeOfString:@"CopyToPasteboard" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video CopyToPasteboard sharing";
              eventName = kEventNameCopyUrlShareVideo;
          }

          if (eventName && eventType)
          {
              [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:eventType
                                                                    eventName:eventName
                                                                   playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                              channelId:aVideoModel.channelId
                                                                   andAssetId:aVideoModel.uniqueId
                                                          andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];
          }
          [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                               action:action
                                                label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                             andValue:nil];

          [self postFeedSwerveEvent:kSwrvevideoShare channel:(self.mChannelDataModel) ? self.mChannelDataModel : nil andVideo:aVideoModel];

        };
    }
    else
    {
        shareController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {

          self.mActivityViewController = nil;
          if (!completed)
          { //user cancel the activity
              return;
          }

          NSString *eventType = kEventTypeUserAction;
          NSString *eventName = nil;
          NSString *action = @"";

          if ([activityType rangeOfString:@"facebook" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Facebook sharing";
              eventName = kEventNameFaceBookSharingVideo;
          }
          else if ([activityType rangeOfString:@"twitter" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Twitter sharing";
              eventName = kEventNameTwitterSharingVideo;
          }
          else if ([activityType rangeOfString:@"mail" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video Mail sharing";
              eventName = kEventNameEmailSharingVideo;
          }
          else if ([activityType rangeOfString:@"CopyToPasteboard" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Video CopyToPasteboard sharing";
              eventName = kEventNameCopyUrlShareVideo;
          }

          if (eventName && eventType)
          {
              [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:eventType
                                                                    eventName:eventName
                                                                   playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                              channelId:aVideoModel.channelId
                                                                   andAssetId:aVideoModel.uniqueId
                                                          andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];
          }

          [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                               action:action
                                                label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                             andValue:nil];

          [self postFeedSwerveEvent:kSwrvevideoShare channel:(self.mChannelDataModel) ? self.mChannelDataModel : nil andVideo:aVideoModel];

        };
    }
    [self.controlsViewController presentViewController:shareController animated:YES completion:nil];
}

- (void)rewindButtonPressedForCurrentVideoModel
{
    VideoModel *aVideoModel = _controlsViewController.videoModal;
    if (aVideoModel)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Player Rewind"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                           andValue:nil];
    }
}

#pragma mark
#pragma mark Button Action

- (void)popController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickingTryAgainButton:(CustomIndexButton *)aButton
{
    NSIndexPath *aIndexPath = aButton.mIndexPath;
    VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
    if (aButton.isFetchingPlayBackURIFail)
    {
        [self getPlayBackURIFromServerForSelectedVideoforIndexPath:aIndexPath];
    }
    else
    {
        if ([Utilities isNetworkConnectionAvaliable])
        {
            [self playVideoForURI:aVideoModel.playbackURI forIndexPath:aIndexPath];
        }
        else
        {
            return;
        }
    }
    PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:aIndexPath];

    if (aCell && aIndexPath && aIndexPath.row != 0)
    {
        aCell.mBrandLogoAndDescBGView.alpha = 1.0;
        aCell.mFollowButton.userInteractionEnabled = YES;
        aCell.mBrandLogoImageView.userInteractionEnabled = YES;
    }
}

- (void)createVideoLoadingFailureErrorView:(NSDictionary *)aDict
{
    [self removeVideoLoadingFailureView];
    NSIndexPath *aIndexPath = [aDict objectForKey:@"indexPath"];
    BOOL isFetchPlayBackURIFail = [[aDict objectForKey:@"isPlayblackURIFail"] boolValue];

    PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];

    if (self.videoView || aCell)
    {
        aCell.mVideoImageView.userInteractionEnabled = YES;

        CGRect aVideoFailureViewFrame;
        if (self.videoView)
        {
            if ([self.videoView isDescendantOfView:aCell] || self.isMoviePlayerInFullScreen)
            {
                aVideoFailureViewFrame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
            }
            else
            {
                aVideoFailureViewFrame = CGRectMake(0, 0, aCell.mVideoImageView.frame.size.width, aCell.mVideoImageView.frame.size.height);
            }
        }
        else
        {
            aVideoFailureViewFrame = CGRectMake(0, 0, aCell.mVideoImageView.frame.size.width, aCell.mVideoImageView.frame.size.height);
        }

        self.mVideoLoadingFailureView = [[UIView alloc] initWithFrame:aVideoFailureViewFrame];
        self.mVideoLoadingFailureView.backgroundColor = [UIColor blackColor];

        UIImage *aAttentionImage = [UIImage imageNamed:@"attentionMedium.png"];
        UIImageView *aAttentionImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.mVideoLoadingFailureView.frame.size.width - aAttentionImage.size.width) / 2, (self.mVideoLoadingFailureView.frame.size.height / 2) - aAttentionImage.size.width - 20, aAttentionImage.size.width, aAttentionImage.size.height)];
        aAttentionImageView.image = aAttentionImage;
        aAttentionImageView.tag = kAttentionImageViewTag;
        [self.mVideoLoadingFailureView addSubview:aAttentionImageView];

        UILabel *aErrorMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, aAttentionImageView.frame.size.height + aAttentionImageView.frame.origin.y + 20, self.mVideoLoadingFailureView.frame.size.width - 10, 19)];
        aErrorMsgLabel.text = @"Video failed to load";
        aErrorMsgLabel.textAlignment = NSTextAlignmentCenter;
        aErrorMsgLabel.textColor = [UIColor colorWithRed:189.0 / 255 green:195.0 / 255 blue:199.0 / 255 alpha:1.0];
        aErrorMsgLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
        aErrorMsgLabel.tag = kVideoFailedtoLoadLabelTag;
        [self.mVideoLoadingFailureView addSubview:aErrorMsgLabel];

        CustomIndexButton *aTryAgainButton = [CustomIndexButton buttonWithType:UIButtonTypeCustom];
        aTryAgainButton.tag = kVideoFailedtoLoadTryAgainBtnTag;
        aTryAgainButton.frame = CGRectMake((self.mVideoLoadingFailureView.frame.size.width - 90) / 2, aErrorMsgLabel.frame.origin.y + aErrorMsgLabel.frame.size.height + 20, 90, 30);
        [aTryAgainButton setTitleColor:[UIColor colorWithRed:189.0 / 255 green:195.0 / 255 blue:199.0 / 255 alpha:1.0] forState:UIControlStateNormal];
        [aTryAgainButton setTitle:@"Try again" forState:UIControlStateNormal];
        aTryAgainButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
        aTryAgainButton.mIndexPath = aIndexPath;
        aTryAgainButton.isFetchingPlayBackURIFail = isFetchPlayBackURIFail;
        aTryAgainButton.layer.borderWidth = 1.0;
        aTryAgainButton.layer.cornerRadius = 1.0;
        aTryAgainButton.layer.borderColor = [UIColor colorWithRed:189.0 / 255 green:195.0 / 255 blue:199.0 / 255 alpha:1.0].CGColor;
        [aTryAgainButton addTarget:self action:@selector(onClickingTryAgainButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.mVideoLoadingFailureView addSubview:aTryAgainButton];

        if (self.videoView)
        {
            if ([self.videoView isDescendantOfView:aCell] || self.isMoviePlayerInFullScreen)
            {
                self.videoView.hidden = NO;
                [self.videoView addSubview:self.mVideoLoadingFailureView];
            }
            else
            {
                [aCell.mVideoImageView addSubview:self.mVideoLoadingFailureView];
            }
        }
        else
        {
            [aCell.mVideoImageView addSubview:self.mVideoLoadingFailureView];
        }
        [self setFrameForVideoLoadingFailureView];
    }
    [self dimSelectedCellDetailView];
}

- (void)setFrameForVideoLoadingFailureView
{
    PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];

    if (self.videoView || aCell)
    {
        aCell.mVideoImageView.userInteractionEnabled = YES;

        CGRect aVideoFailureViewFrame;
        if (self.videoView)
        {
            if ([self.videoView isDescendantOfView:aCell] || self.isMoviePlayerInFullScreen)
            {
                self.videoView.hidden = NO;
                aVideoFailureViewFrame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
            }
            else
            {
                aVideoFailureViewFrame = CGRectMake(0, 0, aCell.mVideoImageView.frame.size.width, aCell.mVideoImageView.frame.size.height);
            }
        }
        else
        {
            aVideoFailureViewFrame = CGRectMake(0, 0, aCell.mVideoImageView.frame.size.width, aCell.mVideoImageView.frame.size.height);
        }

        if (self.mVideoLoadingFailureView)
        {
            self.mVideoLoadingFailureView.frame = aVideoFailureViewFrame;

            UIImageView *aAttentionImageView = (UIImageView *)[self.mVideoLoadingFailureView viewWithTag:kAttentionImageViewTag];

            aAttentionImageView.frame = CGRectMake((self.mVideoLoadingFailureView.frame.size.width - aAttentionImageView.image.size.width) / 2, (self.mVideoLoadingFailureView.frame.size.height / 2) - aAttentionImageView.image.size.width - 20, aAttentionImageView.image.size.width, aAttentionImageView.image.size.height);

            UILabel *aErrorMsgLabel = (UILabel *)[self.mVideoLoadingFailureView viewWithTag:kVideoFailedtoLoadLabelTag];

            aErrorMsgLabel.frame = CGRectMake(5, aAttentionImageView.frame.size.height + aAttentionImageView.frame.origin.y + 20, self.mVideoLoadingFailureView.frame.size.width - 10, 19);

            CustomIndexButton *aTryAgainButton = (CustomIndexButton *)[self.mVideoLoadingFailureView viewWithTag:kVideoFailedtoLoadTryAgainBtnTag];
            aTryAgainButton.frame = CGRectMake((self.mVideoLoadingFailureView.frame.size.width - 90) / 2, aErrorMsgLabel.frame.origin.y + aErrorMsgLabel.frame.size.height + 20, 90, 30);
        }
    }
}
- (void)removeVideoLoadingFailureView
{
    if (self.mVideoLoadingFailureView)
    {
        [self.mVideoLoadingFailureView removeFromSuperview];
        self.mVideoLoadingFailureView = nil;
    }
}
- (IBAction)onClickingFollowButton:(CustomIndexButton *)sender
{
    [self updateFollowStatusInServerForIndexPathRow:sender.mIndexPath.row - 1 withFollowStatus:!sender.selected];
}

- (void)updateSelectedIndexFollowStatus:(BOOL)followStatus
{
    [self removeErrorViewFullScreenViewController];
    if (self.mSelectedIndexPath && self.mSelectedIndexPath.row >= 1)
        [self updateFollowStatusInServerForIndexPathRow:self.mSelectedIndexPath.row - 1 withFollowStatus:followStatus];
}

- (void)postFeedSwerveEvent:(NSString *)eventName channel:(ChannelModel *)channelModel andVideo:(VideoModel *)videoModel
{
    NSDictionary *payload = nil;
    if (self.isFromPlayList)
    {
        payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:videoModel.title
                                                              assetId:videoModel.uniqueId
                                                         channleTitle:videoModel.channelTitle
                                                            channleId:videoModel.channelId
                                                           genreTitle:(self.mDataModel) ? self.mDataModel.genreTitle : nil
                                                              genreId:(self.mGenreDataModel) ? self.mGenreDataModel.genreId : nil
                                                       publisherTitle:(self.mProviderModal) ? self.mProviderModal.title : nil
                                                          publisherId:(self.mProviderModal) ? self.mProviderModal.uniqueId : nil
                                                        playlistTitle:(self.mDataModel) ? self.mDataModel.title : nil
                                                           playlistId:(self.mDataModel) ? self.mDataModel.uniqueId : nil];
    }
    else
    {
        payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:(videoModel) ? videoModel.title : nil
                                                              assetId:(videoModel) ? videoModel.uniqueId : nil
                                                         channleTitle:(channelModel) ? channelModel.title : videoModel.channelTitle
                                                            channleId:(channelModel) ? channelModel.uniqueId : videoModel.channelId
                                                           genreTitle:(self.mGenreDataModel) ? self.mGenreDataModel.genreTitle : nil
                                                              genreId:(self.mGenreDataModel) ? self.mGenreDataModel.genreId : nil
                                                       publisherTitle:(self.mProviderModal) ? self.mProviderModal.title : nil
                                                          publisherId:(self.mProviderModal) ? self.mProviderModal.uniqueId : nil
                                                        playlistTitle:nil
                                                           playlistId:nil];
    }
    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}

- (void)updateFollowStatusInServerForIndexPathRow:(NSInteger)aIndexPathRow withFollowStatus:(BOOL)followStatus
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvefeedCannotFollowNotLoggedIn];
        [kSharedApplicationDelegate showLoginSignInScreenForGuestUserOnClickingFollow];
        return;
    }

    __weak PlayDetailViewController *weakSelf = self;

    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:aIndexPathRow];
    if (followStatus && !aModel.isVideoFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Follow"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                           andValue:nil];

        [[ServerConnectionSingleton sharedInstance] sendrequestToSubscribeChannel:aModel.channelId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedSwerveEvent:kSwrvefeedFollow channel:nil andVideo:aModel];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    aModel.isVideoFollowing = YES;
                    [weakSelf modifyDataSourceWithFollowStatus:aModel.isVideoFollowing videoModel:aModel];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction
                                                                          eventName:kEventNameFollow
                                                                         playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                                    channelId:aModel.channelId
                                                                         andAssetId:aModel.uniqueId
                                                                andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];

                  }];
              }
            }
            errorBlock:^(NSError *error) {

              [weakSelf performSelectorOnMainThread:@selector(onFollowUnFollowStatusFailure:) withObject:error waitUntilDone:NO];

            }];
    }
    else if (!followStatus && aModel.isVideoFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"UnFollow"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                           andValue:nil];
        [[ServerConnectionSingleton sharedInstance] sendrequestToUnSubscribeChannel:aModel.channelId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedSwerveEvent:kSwrvefeedUnfollow channel:nil andVideo:aModel];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    aModel.isVideoFollowing = NO;
                    [weakSelf modifyDataSourceWithFollowStatus:aModel.isVideoFollowing videoModel:aModel];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction
                                                                          eventName:kEventNameUnFollow
                                                                         playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                                    channelId:aModel.channelId
                                                                         andAssetId:aModel.uniqueId
                                                                andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];

                  }];
              }

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(onFollowUnFollowStatusFailure:) withObject:error waitUntilDone:NO];

            }];
    }
}

- (void)onFollowUnFollowStatusFailure:(NSError *)error
{
    if (self.fullscreenViewController && self.isfullscreenViewControllerPresented)
    {
        if (error.code == kErrorCodeNotReachable)
        {
            [self addErrorViewFullScreenViewControllerWithErrorType:InternetFailureWithTryAgainMessage];
        }
        else /*if(error.code==kServerErrorCode)*/
        {    //
            [self addErrorViewFullScreenViewControllerWithErrorType:ServiceErrorWithTryAgainMessage];
        }
        return;
    }

    __weak PlayDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
}

- (IBAction)onClickingBGViewPlayButton:(id)sender
{
    if (self.mVideoListDataSource.count)
    {
        [self stopAndRemoveMoviePlayer];
        NSIndexPath *aIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        [self moveToCenterAndHighLightCollectionCellForIndexPath:aIndexPath highlightWithDelay:.3];
        VideoModel *aModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Taps on Play Button in first cell"
                                              label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                           andValue:nil];
    }
}

- (void)playFirstVideo
{
    if (self.mVideoListDataSource.count)
    {
        [self preventCellDidSelectionForDuration:0.5];
        [self stopAndRemoveMoviePlayer];
        NSIndexPath *aIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        [self moveToCenterAndHighLightCollectionCellForIndexPath:aIndexPath highlightWithDelay:.3];
    }
}

- (IBAction)onproviderAction:(id)sender
{
    if (self.mChannelDataModel && !self.isFromProvider)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Taps on more from Provider Button"
                                              label:[NSString stringWithFormat:@"%@/ProviderId-%@/ProviderTitle-%@", [self getTrackpath], self.mProviderModal.uniqueId, self.mProviderModal.title]
                                           andValue:nil];

        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

        ProviderDetailViewController *aProviderDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"ProviderDetailViewController"];

        aProviderDetailViewController.publisherApiFormat = self.mChannelDataModel.relatedLinks[@"publisher"];
        aProviderDetailViewController.mProviderModel = self.mProviderModal;
        aProviderDetailViewController.mProviderImageUrl = self.mProviderModal.linksDict[@"imageUri"];
        [self.navigationController pushViewController:aProviderDetailViewController animated:YES];
        if (_isVideoLocked)
        {
            self.mPreviousVideoPlayIndex = self.mSelectedIndexPath.item;
        }
    }
}
- (void)onClickingHideDetailViewButton
{
    [self ShowShareButton:YES];
    self.mCollectionView.scrollEnabled = YES;
    [self scrollImageViewToCenterForIndexPath:self.mSelectedIndexPath withAnimation:YES];
    [self removeVideoDetailView];

    [self performSelector:@selector(applyBlurEffectOnVisibleCellsWithDimDetailViewForSelectedIndexPath:) withObject:self.mSelectedIndexPath afterDelay:.15];
}

- (void)onClickingAddButton
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvefeedCannotFollowNotLoggedIn];
        [kSharedApplicationDelegate showLoginSignInScreenForGuestUserOnClickingFollow];
        return;
    }

    __weak PlayDetailViewController *weakSelf = self;

    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    if (!self.mAddFollowButton.selected && !self.mChannelDataModel.isChannelFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent action:@"Follow" label:[self getTrackpath] andValue:nil];

        [[ServerConnectionSingleton sharedInstance] sendrequestToSubscribeChannel:self.mChannelDataModel.uniqueId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedSwerveEvent:kSwrvefeedFollow channel:self.mChannelDataModel andVideo:nil];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    weakSelf.mChannelDataModel.isChannelFollowing = YES;
                    [weakSelf setFollowButtonSelectedMode:YES];
                    //weakSelf.mAddFollowButton.selected = YES;
                    [weakSelf postNotificationForFollowChannelId:weakSelf.mChannelDataModel.uniqueId withFollowStatus:YES];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction
                                                                          eventName:kEventNameFollow
                                                                         playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                                    channelId:self.mChannelDataModel.uniqueId
                                                                         andAssetId:nil
                                                                andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];

                  }];
              }

            }
            errorBlock:^(NSError *error) {

              [weakSelf performSelectorOnMainThread:@selector(onFollowUnFollowStatusFailure:) withObject:error waitUntilDone:NO];
            }];
    }
    else if (self.mAddFollowButton.selected && self.mChannelDataModel.isChannelFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent action:@"UnFollow" label:[self getTrackpath] andValue:nil];

        [[ServerConnectionSingleton sharedInstance] sendrequestToUnSubscribeChannel:self.mChannelDataModel.uniqueId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedSwerveEvent:kSwrvefeedUnfollow channel:self.mChannelDataModel andVideo:nil];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    weakSelf.mChannelDataModel.isChannelFollowing = NO;
                    [weakSelf setFollowButtonSelectedMode:NO];
                    [weakSelf postNotificationForFollowChannelId:weakSelf.mChannelDataModel.uniqueId withFollowStatus:NO];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction
                                                                          eventName:kEventNameUnFollow
                                                                         playListId:((self.isFromPlayList) ? self.mDataModel.uniqueId : nil)
                                                                                    channelId:self.mChannelDataModel.uniqueId
                                                                         andAssetId:nil
                                                                andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];
                  }];
              }

            }
            errorBlock:^(NSError *error) {
              [weakSelf performSelectorOnMainThread:@selector(onFollowUnFollowStatusFailure:) withObject:error waitUntilDone:NO];

            }];
    }
}

- (void)onClickingShareButton
{
    BOOL canShowAlertForInternetFailure = NO;
    if (self.mErrorView && (self.mErrorType == InternetFailureInLandingScreenTryAgainButton || self.mErrorType == InternetFailureWithTryAgainButton || self.mErrorType == ServiceErrorWithTryAgainButton))
    {
        canShowAlertForInternetFailure = YES;
    }

    BOOL isNetworkAvaliable = [Utilities isNetworkConnectionAvaliable];

    if (!isNetworkAvaliable)
    {
        if (canShowAlertForInternetFailure)
        {
            NSString *message = NSLocalizedString(@"You're not connected to the internet", @"One of the 'generic Watchable' alert's messages");
            UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            __weak PlayDetailViewController *weakSelf = self;
            [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
        }
        return;
    }

    //check the message as per the screen

    if (self.mDataModel.shareLink == nil)
    {
        NSString *message = NSLocalizedString(@"Can't share this Playlist at the moment.", @"One of the 'generic Watchable' alert's messages");
        UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }

    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent action:@"Taps on Playlist sharing " label:[self getTrackpath] andValue:nil];

    __weak PlayDetailViewController *weakSelf = self;
    NSString *aBitlyKey = [NSString stringWithFormat:@"PlaylistId_%@", self.mDataModel.uniqueId];

    NSString *aBitlyURL = [[DBHandler sharedInstance] getShortShareUrlForKey:aBitlyKey withLongUrl:self.mDataModel.shareLink];

    if (aBitlyURL)
    {
        [self sharePlaylist:aBitlyURL];
    }
    else
    {
        NSString *aSharedData = [NSString stringWithFormat:@"playlists/%@", self.mDataModel.uniqueId];
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetBitlyShareUrl:self.mDataModel.shareLink
            withShareData:aSharedData
            withResponseBlock:^(NSDictionary *responseDict) {

              NSString *aShortUrl = [responseDict objectForKey:@"shortUrl"];

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[DBHandler sharedInstance] setShortShareUrlForKey:aBitlyKey withLongUrl:weakSelf.mDataModel.shareLink withValue:aShortUrl];
                [weakSelf sharePlaylist:aShortUrl];
              }];

            }
            errorBlock:^(NSError *error) {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (weakSelf)
                {
                    if (error.code == kErrorCodeNotReachable)
                    {
                        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                    }
                    else
                    {
                        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessageForBitlyShortURL withTryAgainSelector:nil withInputParameters:nil];
                    }
                }
              }];
            }];
    }
}

- (void)sharePlaylist:(NSString *)aShareUrl
{
    NSString *sharingString = nil;

    sharingString = aShareUrl;

    //sharing in FB, Twitter, Mail
    NSURL *url = [NSURL URLWithString:sharingString];
    NSURL *Watchableurl = [NSURL URLWithString:kWatchableURLForShare];

    NSString *aShareText = [NSString stringWithFormat:@"Hi,\n\nI found this great playlist on Watchable and thought you would enjoy it:\n%@\n\n%@\n\n%@", url, @"Whether you’re looking for hit web series, ground-breaking comedy, style and food gurus, jaw-dropping extreme sports, or the latest movie trailers...Watchable has it all.", Watchableurl];
    NSString *text = aShareText; //@"View this link on Watchable";

    NSMutableArray *activityItems = [NSMutableArray array];

    CustomActivityItemProviderForSharing *activityItemProviderForTextAndURL =
        [[CustomActivityItemProviderForSharing alloc] initWithText:text
                                                           urlText:url
                                                     withShareType:ePlayList
                                                             title:self.mDataModel.title];

    [activityItems addObject:activityItemProviderForTextAndURL];

    // NSURL *Imageurl = [NSURL URLWithString:@"http://docs.demo.xidio.com/Viper/nasatv1.html"];
    CustomActivityItemProviderForSharing *activityItemProviderImageUrl =
        [[CustomActivityItemProviderForSharing alloc] initWithImageURL:url
                                                         withShareType:ePlayList];

    [activityItems addObject:activityItemProviderImageUrl];

    NSString *aSubject = [NSString stringWithFormat:@"Your friend has shared a playlist from Watchable.com!"];

    UIActivityViewController *shareController =
        [[UIActivityViewController alloc]
            initWithActivityItems:activityItems
            applicationActivities:nil];
    [shareController setValue:aSubject forKey:@"subject"];
    shareController.excludedActivityTypes = @[
        UIActivityTypePostToWeibo,
        //UIActivityTypeMessage,
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeSaveToCameraRoll,
        UIActivityTypeAddToReadingList,
        UIActivityTypePostToFlickr,
        UIActivityTypePostToVimeo,
        UIActivityTypePostToTencentWeibo,
        UIActivityTypeAirDrop
        //UIActivityTypePostToFacebook,
        //UIActivityTypePostToTwitter
    ];
    self.mActivityViewController = shareController;

    if ([shareController respondsToSelector:@selector(completionWithItemsHandler)])
    {
        shareController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {

          self.mActivityViewController = nil;
          if (!completed)
          {
              //user cancel the activity
              return;
          }
          if (activityError)
          {
              NSString *message = NSLocalizedString(@"Not able to post. Please try later", @"One of the 'generic Watchable' alert's messages");
              UIAlertController *alert = [AlertFactory genericWatchableWithDefaultTitleAndMessage:message];
              [self presentViewController:alert animated:YES completion:nil];

              return;
          }

          NSString *eventType = kEventTypeUserAction;
          NSString *eventName = nil;
          NSString *action = @"";
          if ([activityType rangeOfString:@"facebook" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              eventName = kEventNameFaceBookSharingPlaylist;
              action = @"Playlist Facebook sharing";
          }
          else if ([activityType rangeOfString:@"twitter" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              eventName = kEventNameTwitterSharingPlaylist;
              action = @"Playlist Twitter sharing";
          }
          else if ([activityType rangeOfString:@"mail" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              eventName = kEventNameEmailSharingPlaylist;
              action = @"Playlist Mail sharing";
          }
          else if ([activityType rangeOfString:@"CopyToPasteboard" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              eventName = kEventNameCopyUrlSharePlaylist;
              action = @"Playlist CopyToPasteboard sharing";
          }

          if (eventName && eventType)
          {
              [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:eventType eventName:eventName playListId:self.mDataModel.uniqueId channelId:nil andAssetId:nil andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];
          }
          [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent action:action label:[self getTrackpath] andValue:nil];

        };
    }
    else
    {
        shareController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
          self.mActivityViewController = nil;
          if (!completed)
          { //user cancel the activity
              return;
          }

          NSString *eventType = kEventTypeUserAction;
          NSString *eventName = nil;
          NSString *action = @"";
          if ([activityType rangeOfString:@"facebook" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Playlist Facebook sharing";
              eventName = kEventNameFaceBookSharingPlaylist;
          }
          else if ([activityType rangeOfString:@"twitter" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Playlist Twitter sharing";
              eventName = kEventNameTwitterSharingPlaylist;
          }
          else if ([activityType rangeOfString:@"mail" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Playlist Mail sharing";
              eventName = kEventNameEmailSharingPlaylist;
          }
          else if ([activityType rangeOfString:@"CopyToPasteboard" options:NSCaseInsensitiveSearch].location != NSNotFound)
          {
              action = @"Playlist CopyToPasteboard sharing";
              eventName = kEventNameCopyUrlSharePlaylist;
          }

          if (eventName && eventType)
          {
              [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:eventType eventName:eventName playListId:self.mDataModel.uniqueId channelId:nil andAssetId:nil andFromPlaylistPage:((self.isFromPlayList) ? YES : NO)];
          }
          [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent action:action label:[self getTrackpath] andValue:nil];

        };
    }

    [self presentViewController:shareController animated:YES completion:nil];
}

#pragma mark
#pragma mark Add/Remove Movie Player
- (void)playMovieForHighLightedCellWithIndexPath:(NSIndexPath *)aIndexPath
{
    if (!self.mBrightPlayer)
    {
        self.mBrightPlayer = [BrightCovePlayerSingleton sharedInstance];
    }
    [self performSelector:@selector(setVideoFrameWhilePlay) withObject:nil afterDelay:0.2];

    VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
    if (!aVideoModel.playbackURI)
    {
        [self getPlayBackURIFromServerForSelectedVideoforIndexPath:aIndexPath];
    }
    else
    {
        [self playVideoForURI:aVideoModel.playbackURI forIndexPath:aIndexPath];
    }
    self.controlsViewController.placeholderText.text = aVideoModel.title; // Adding it from BC: Modified AB
    [self addChannelLogoForControlsControllerInLandScapeMode];
}

- (void)setVideoFrameWhilePlay
{
    CGRect aRect = CGRectMake(self.mCollectionView.frame.origin.x, 0, self.view.frame.size.width, (self.view.frame.size.width / 16) * 9.0);
    NSLog(@"The frame for video=%@", NSStringFromCGRect(aRect));

    [BrightCovePlayerSingleton setMoviePlayerFrame:aRect];
}

- (void)playVideoForURI:(NSString *)aURI forIndexPath:(NSIndexPath *)aIndexPath
{
    if (self.isViewDisappeared)
    {
        UIViewController *presentedVc = self.presentedViewController;

        if (!self.isMoviePlayerInFullScreen && ![presentedVc isMemberOfClass:[MFMailComposeViewController class]])
        {
            return;
        }
    }
    if (self.controlsViewController)
    {
        self.controlsViewController.totalProgress = 0;
    }
    self.isSelectedCellDetailsDimmed = NO;
    [self removeVideoLoadingFailureView];
    self.isVideoLocked = YES;
    if (self.mSelectedIndexPath == aIndexPath /*|| self.isMoviePlayerInFullScreen*/)
    {
        if (self.isVideoLocked)
        {
            [BrightCovePlayerSingleton playMoviePlayerWithContentURLStr:aURI];
            VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.row - 1];

            if (self.isFromPlayList)
            {
                _controlsViewController.previousVideoId = (_previouslyPlayedVideo) ? _previouslyPlayedVideo.uniqueId : nil;
                _controlsViewController.currentlyPlayingVideoPlaylistId = (self.mDataModel) ? self.mDataModel.uniqueId : nil;

                [_mBrightPlayer setAdPlayerEventsPlayListID:self.mDataModel.uniqueId PreviousVideoID:(_previouslyPlayedVideo) ? _previouslyPlayedVideo.uniqueId : nil ChannelID:aVideoModel.channelId AssetID:aVideoModel.uniqueId ProgressMarket:@"0" PerceivedBandwidth:@"0"];

                [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypePlayer
                                                                            eventName:kEventNamePlayerStart
                                                                           playListId:self.mDataModel.uniqueId
                                                                      previousVideoId:(_previouslyPlayedVideo) ? _previouslyPlayedVideo.uniqueId : nil
                                                                            channelId:aVideoModel.channelId
                                                                              assetId:aVideoModel.uniqueId
                                                                       progressMarker:@"0"
                                                                andPerceivedBandwidth:@"0"
                                                                    withResponseBlock:^(BOOL status){

                                                                    }];

                NSString *playlistsWithID = [NSString stringWithFormat:@"%@:%@", kDeepLinkPlayListIdKey, self.mDataModel.uniqueId];
                NSString *videoWithID = [NSString stringWithFormat:@"%@:%@", kDeepLinkVideoIdKey, aVideoModel.uniqueId];

                [self trackPlaylistsShowsEventforContentView:playlistsWithID trackVideoEvent:videoWithID];

                [self postFeedSwerveEvent:kSwrvevideoWatch channel:nil andVideo:aVideoModel];
                [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveplaylistVideoView withPayload:@{ @"slot_number" : @(aIndexPath.row) }];
            }
            else
            {
                _controlsViewController.previousVideoId = nil;
                _controlsViewController.currentlyPlayingVideoPlaylistId = nil;
                [[AnalyticsEventsHandler sharedInstance] postAnalyticsPlayerEventType:kEventTypePlayer
                                                                            eventName:kEventNamePlayerStart
                                                                           playListId:nil
                                                                      previousVideoId:nil
                                                                            channelId:aVideoModel.channelId
                                                                              assetId:aVideoModel.uniqueId
                                                                       progressMarker:@"0"
                                                                andPerceivedBandwidth:@"0"
                                                                    withResponseBlock:^(BOOL status){

                                                                    }];

                NSString *showsWithID = [NSString stringWithFormat:@"%@:%@", kDeepLinkShowIdKey, aVideoModel.channelId];
                NSString *videoWithID = [NSString stringWithFormat:@"%@:%@", kDeepLinkVideoIdKey, aVideoModel.uniqueId];

                [self trackPlaylistsShowsEventforContentView:showsWithID trackVideoEvent:videoWithID];

                [_mBrightPlayer setAdPlayerEventsPlayListID:nil PreviousVideoID:nil ChannelID:aVideoModel.channelId AssetID:aVideoModel.uniqueId ProgressMarket:@"0" PerceivedBandwidth:@"0"];

                [self postFeedSwerveEvent:kSwrvevideoWatch channel:self.mChannelDataModel andVideo:aVideoModel];
            }

            [self updateFollowStatusForSelectedVideoInControlsController:aVideoModel.isVideoFollowing];

            [self setCurrentPlayingVideoId:aVideoModel.uniqueId withTimeProgress:@"0"];
            [_controlsViewController setCurrentPlayingVideoId:aVideoModel.uniqueId withTimeProgress:@"0"];
            _controlsViewController.videoModal = aVideoModel;
            [_controlsViewController setCurrentPlayingVideoDuration:aVideoModel.duration];
            if (aVideoModel.uniqueId)
            {
                [[BrightCovePlayerSingleton sharedInstance] setPlayingAssetId:aVideoModel.uniqueId];
            }
            [self fetchPlaybackURIForNextVideoModelIndex:[NSIndexPath indexPathForItem:self.mSelectedIndexPath.row inSection:0]];
        }
        else
        {
            [self breakVideoLockSetUp];
            [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.1 withResizingCell:YES];
        }
    }

    _previouslyPlayedVideo = [_mVideoListDataSource objectAtIndex:aIndexPath.row - 1];
}
- (void)setCurrentPlayingVideoId:(NSString *)aVideoId withTimeProgress:(NSString *)aTimeProgress
{
    self.mCurrentlyPlayingVideoId = aVideoId;
    self.mCurrentlyPlayingVideoProgress = aTimeProgress;
    self.mPreviouslyPostedVideoProgress = @"0";
}
- (void)stopAndRemoveMoviePlayer // whole method is from BC: Modified AB
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"endEventWhenVideoChanged" object:nil];
    [self removeVideoLoadingFailureView];
    [self setCurrentPlayingVideoId:nil withTimeProgress:nil];
    [_controlsViewController setCurrentPlayingVideoId:nil withTimeProgress:nil];
    [_controlsViewController setCurrentPlayingVideoDuration:nil];
    [BrightCovePlayerSingleton stopMoviePlayer];
    [[BrightCovePlayerSingleton sharedInstance] stopAdPlay];
    [self stopPlayerandRemoveCallBacks];
    if (self.controlsViewController)
        [self.controlsViewController removeFromParentViewController];

    if (self.videoView)
        [self.videoView removeFromSuperview];

    self.videoView = nil;
    self.controlsViewController.delegate = nil;
    self.controlsViewController = nil;
    [self setupBCOVPlayer];
    self.isMoviePlaying = NO;
    [self removeDimSelectedCellDetailViewSelector];
    [self.mVideoProgressTimer invalidate];
    self.mVideoProgressTimer = nil;
    [BrightCovePlayerSingleton stopMoviePlayer];
}

- (void)stopPlayerandRemoveCallBacks
{
    if (_playbackController)
    {
        if (_controlsViewController)
        {
            [_playbackController removeSessionConsumer:_controlsViewController];
            [_controlsViewController removeAllNotification];
        }
        _playbackController.delegate = nil;
        _playbackController = nil;
    }
}

- (void)stopMoviePlayerFromDelloc
{
    [self removeVideoLoadingFailureView];
    [self setCurrentPlayingVideoId:nil withTimeProgress:nil];

    [BrightCovePlayerSingleton stopMoviePlayer];

    //    [self stopPlayerandRemoveCallBacks];
    if (self.controlsViewController)
        [self.controlsViewController removeFromParentViewController];

    if (self.videoView)
        [self.videoView removeFromSuperview];

    self.videoView = nil;
    self.controlsViewController.delegate = nil;
    self.controlsViewController = nil;
    self.isMoviePlaying = NO;
    [self removeDimSelectedCellDetailViewSelector];
    [self.mVideoProgressTimer invalidate];
    self.mVideoProgressTimer = nil;
}

#pragma mark
#pragma mark Movie Player Notification
- (void)addNotificationForMoviePlayerState
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlaybackStateChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)removeNotificationForMoviePlayerState
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void)moviePlaybackDidFinish:(NSNotification *)notification
{
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded)
    {
        [self postVideoProgressToServerForVideoId:self.mCurrentlyPlayingVideoId withProgressStatus:self.mCurrentlyPlayingVideoProgress];
        self.isMoviePlaying = NO;
        if (self.isDetailViewOverLayVisible)
        {
            [self removeVideoDetailView];
        }
        UIView *aView = [MoviePlayerSingleton getMoviePlayerView];
        [aView removeFromSuperview];

        [self performSelector:@selector(scrollToNextCell) withObject:nil afterDelay:.5];
    }
    else if (reason == MPMovieFinishReasonPlaybackError)
    {
        NSDictionary *notificationUserInfo = [notification userInfo];

        NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
        if (mediaPlayerError)
        {
            NSLog(@"playback failed with error description: %@", [mediaPlayerError localizedDescription]);
        }
        else
        {
            NSLog(@"playback failed without any given reason");
        }
        if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
        {
            NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:self.mSelectedIndexPath, @"indexPath", [NSNumber numberWithBool:NO], @"isPlayblackURIFail", nil];
            [self performSelector:@selector(createVideoLoadingFailureErrorView:) withObject:aDict afterDelay:.5];
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    }
}

- (void)moviePlaybackStateChange:(NSNotification *)notification
{
    [self removeVideoLoadingFailureView];
    __weak PlayDetailViewController *weakSelf = self;
    int ChangeState = [MoviePlayerSingleton moviePlayer].playbackState;
    if (ChangeState == MPMoviePlaybackStatePlaying)
    {
        UIView *aView = [MoviePlayerSingleton getMoviePlayerView];
        if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
        {
            if (self.mBrightPlayer)
            {
                PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];
                aCell.mVideoImageView.userInteractionEnabled = YES;
                [aCell.mVideoImageView addSubview:aView];
                [aCell.mVideoImageView bringSubviewToFront:aView];
                self.isMoviePlaying = YES;
            }
        }

        [self performSelectorOnMainThread:@selector(createTimerToTrackMovieProgress) withObject:nil waitUntilDone:NO];

        [self dimSelectedCellDetailViewAfterDelay];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        NSLog(@"MPMoviePlaybackStatePlaying");
    }
    else if (ChangeState == MPMoviePlaybackStateStopped)
    {
        NSLog(@"MPMoviePlaybackStateStopped");
        [weakSelf postVideoProgressToServerForVideoId:weakSelf.mCurrentlyPlayingVideoId withProgressStatus:weakSelf.mCurrentlyPlayingVideoProgress];
        //user hit the done button
    }
    else if (ChangeState == MPMoviePlaybackStatePaused)
    {
        NSLog(@"MPMoviePlaybackStatePaused");
        [weakSelf postVideoProgressToServerForVideoId:weakSelf.mCurrentlyPlayingVideoId withProgressStatus:weakSelf.mCurrentlyPlayingVideoProgress];
        //user hit the done button
    }
}
- (void)createTimerToTrackMovieProgress
{
    if (self.mVideoProgressTimer)
    {
        [self.mVideoProgressTimer invalidate];
        self.mVideoProgressTimer = nil;
    }
    self.mVideoProgressTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(monitorMoviePlayerProgress) userInfo:nil repeats:YES];
    [self.mVideoProgressTimer fire];
}

- (void)monitorMoviePlayerProgress
{
    MPMoviePlayerController *aMoviePlayerController = [MoviePlayerSingleton moviePlayer];
    if (aMoviePlayerController)
    {
        __weak PlayDetailViewController *aWeakSelf = self;

        long long aCurrentProgressTime = (long long)aMoviePlayerController.currentPlaybackTime;

        aWeakSelf.mCurrentlyPlayingVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];

        long long aPreviousPosterProgress = [aWeakSelf.mPreviouslyPostedVideoProgress longLongValue];

        if (aCurrentProgressTime >= aPreviousPosterProgress + 10)
        {
            aWeakSelf.mPreviouslyPostedVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];
            [aWeakSelf postVideoProgressToServerForVideoId:aWeakSelf.mCurrentlyPlayingVideoId withProgressStatus:aWeakSelf.mPreviouslyPostedVideoProgress];
        }

        if (aCurrentProgressTime < aPreviousPosterProgress)
        {
            aWeakSelf.mPreviouslyPostedVideoProgress = [NSString stringWithFormat:@"%lld", aCurrentProgressTime];
        }
    }
}

- (void)dimSelectedCellDetailViewAfterDelay
{
    [self removeDimSelectedCellDetailViewSelector];
    [self performSelector:@selector(dimSelectedCellDetailView) withObject:nil afterDelay:3.0];
}

- (void)dimSelectedCellDetailView
{
    if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
    {
        PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];
        if (aCell)
        {
            [UIView transitionWithView:aCell.mBrandLogoAndDescBGView
                              duration:0.27
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{

                              aCell.mBrandLogoAndDescBGView.alpha = 0.15;

                            }
                            completion:nil];
        }
        else
        {
            self.isSelectedCellDetailsDimmed = YES;
        }
    }
}

- (void)removeDimSelectedCellDetailViewSelector
{
    [UIViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(dimSelectedCellDetailView) object:nil];
}

#pragma mark
#pragma mark Video DetailView Show/Remove
- (void)showVideoDetails:(VideoModel *)aModel forIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEpisodeClicked || self.isLogoClicked || self.isFromGenre)
    {
        aModel.channelInfo = self.mChannelDataModel;
    }
    [self setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    //    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    if (indexPath)
    {
        [self forceToTopCollectionViewCellAtIndexPath:indexPath animated:YES];
        self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;

        self.mCollectionView.scrollEnabled = NO;
        self.isDetailViewOverLayVisible = YES;
        __weak PlayDetailViewController *weakSelf = self;
        VideoDetailView *aDetailView = [[VideoDetailView alloc] initWithFrame:CGRectMake(0, self.view.frame.origin.y + self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - ((self.view.frame.size.width / 16) * 9))];
        aDetailView.indexPath = indexPath;
        aDetailView.followButton.mIndexPath = indexPath;

        [aDetailView.followButton addTarget:self action:@selector(onClickingFollowButton:) forControlEvents:UIControlEventTouchUpInside];
        self.mDetailView = aDetailView;
        [self.view addSubview:self.mDetailView];
        if (self.isFromPlayList)
        {
            UITapGestureRecognizer *aTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapForImageView:)];
            aDetailView.publisherImageView.tag = indexPath.row;
            aDetailView.publisherImageView.userInteractionEnabled = YES;
            [aDetailView.publisherImageView addGestureRecognizer:aTapGestureRecognizer];
        }
        else
        {
            aDetailView.publisherImageView.alpha = 0.15;
        }

        // Below three lines added from BC: Modified AB

        [self.mDetailView updateWithVideoModel:aModel];
        self.controlsViewController.PublisherImg.image = aDetailView.publisherImageView.image;

        VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:indexPath.row - 1];
        self.controlsViewController.placeholderText.text = aVideoModel.title;
        [self addChannelLogoForControlsControllerInLandScapeMode];

        [UIView animateWithDuration:.3
            animations:^{

              CGRect aFrame = weakSelf.mDetailView.frame;

              aFrame.origin.y = weakSelf.view.frame.size.height - aFrame.size.height;
              weakSelf.mDetailView.frame = aFrame;
            }
            completion:^(BOOL finished) {
              weakSelf.mVideoDetailHideButton.hidden = NO;
              [weakSelf.view addSubview:weakSelf.mVideoDetailHideButton];
              [self.controlsViewController showPlayerControls];
            }];
    }
}

- (void)hideVideoDetailView
{
    self.mDetailView.hidden = YES;
}

- (void)removeVideoDetailView
{
    [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    //    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone]; //Added from BC : Modified AB
    self.controlsViewController.infoButtonForShowingDetailsView.hidden = NO;

    CGRect aFrame = self.mDetailView.frame;
    aFrame.origin.y = self.view.frame.size.height;
    self.isMoviePlayerInFullScreen = NO;
    [MoviePlayerSingleton removeDefaultControls];
    __weak PlayDetailViewController *weakSelf = self;
    weakSelf.mVideoDetailHideButton.hidden = YES;
    [weakSelf.mVideoDetailHideButton removeFromSuperview];
    [UIView animateWithDuration:.3
        animations:^{

          weakSelf.mDetailView.frame = aFrame;
          [self resetVideoViewFrame];
        }
        completion:^(BOOL finished) {
          weakSelf.isDetailViewOverLayVisible = NO;
          [weakSelf hideBackButton:NO];
          [weakSelf hideNarBarWithShareAddButton:NO];
          [weakSelf.mDetailView removeFromSuperview];

          weakSelf.mDetailView = nil;

        }];
}

- (void)removeVideoDetailViewForlastVideoInPlayList
{
    [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    //    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone]; //Added from BC : Modified AB
    self.controlsViewController.infoButtonForShowingDetailsView.hidden = NO;

    CGRect aFrame = self.mDetailView.frame;
    aFrame.origin.y = self.view.frame.size.height;
    self.isMoviePlayerInFullScreen = NO;
    [MoviePlayerSingleton removeDefaultControls];
    __weak PlayDetailViewController *weakSelf = self;
    weakSelf.mVideoDetailHideButton.hidden = YES;
    [weakSelf.mVideoDetailHideButton removeFromSuperview];
    [UIView animateWithDuration:0
        animations:^{

          weakSelf.mDetailView.frame = aFrame;
          [self resetVideoViewFrame];
        }
        completion:^(BOOL finished) {
          weakSelf.isDetailViewOverLayVisible = NO;
          [weakSelf hideBackButton:NO];
          [weakSelf hideNarBarWithShareAddButton:NO];
          [weakSelf.mDetailView removeFromSuperview];

          weakSelf.mDetailView = nil;

        }];
}
#pragma mark

- (BOOL)isFullScreenMovieViewPresented
{
    return self.isMoviePlayerInFullScreen;
}

- (BOOL)canChangeToLandScapeMode
{
    if (self.isDetailViewOverLayVisible)
        return self.canChangeToLandScape;
    else
        return NO;
}

- (void)setSelectedIndexToPreviouslyPlayedVideoId
{
    if (self.mSelectedIndexPath && self.mSelectedIndexPath.item > 0)
    {
        self.mPreviousVideoPlayIndex = self.mSelectedIndexPath.item;
    }
    else
    {
        self.mPreviousVideoPlayIndex = -1;
    }
}

- (void)setSelectedIndex:(NSIndexPath *)aIndex
{
    self.mSelectedIndexPath = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (!self.isDetailViewOverLayVisible)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    else if (self.isMoviePlaying)
    {
        return UIInterfaceOrientationMaskAll;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}
// Returns interface orientation masks.
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (!self.isDetailViewOverLayVisible)
    {
        return UIInterfaceOrientationPortrait;
    }
    else if (self.isMoviePlaying)
    {
        return UIInterfaceOrientationPortrait |
               UIInterfaceOrientationPortraitUpsideDown |
               UIInterfaceOrientationLandscapeLeft |
               UIInterfaceOrientationLandscapeRight;
    }
    else
    {
        return UIInterfaceOrientationPortrait;
    }
}

- (BOOL)shouldAutorotate
{
    if (!self.isDetailViewOverLayVisible)
    {
        return NO;
    }
    else if (self.isMoviePlaying)
    {
        return YES;
    }
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [UIViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeErrorViewFullScreenViewController) object:nil];
    self.mCollectionView.delegate = nil;
    [self stopMoviePlayerFromDelloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mCollectionView.dataSource = nil;
    self.mVideoListDataSource = nil;
}
#pragma mark BCOVPlaybackController Delegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventReady])
    {
        NSLog(@"++++++++++PlayDetailViewController:-Ready");
    }

    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPlay])
    {
        [self.controlsViewController.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPause"] forState:UIControlStateNormal];

        NSLog(@"++++++++++PlayDetailViewController:-Play");
        if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
        {
            self.isMoviePlaying = YES;

            if (self.mBrightPlayer && !self.isMoviePlayerInFullScreen)
            {
                PlayDetailCollectionViewCell *aCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:self.mSelectedIndexPath];
                self.currentCell = aCell;
                aCell.mVideoImageView.userInteractionEnabled = YES;
                self.videoView.hidden = YES;
                [aCell.mVideoImageView addSubview:_videoView];

                [aCell.mVideoImageView bringSubviewToFront:_videoView];
                self.isMoviePlaying = YES;
            }
        }

        [self dimSelectedCellDetailViewAfterDelay];

        [self resetVideoViewFrame];
    }
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventPause])
    {
        NSLog(@"++++++++++PlayDetailViewController:-Pause");
        [self.controlsViewController.playPauseButton setBackgroundImage:[UIImage imageNamed:@"playerPlay"] forState:UIControlStateNormal];
    }
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventEnd])
    {
        NSLog(@"++++++++++PlayDetailViewController:-End");
        [self playNextVideo];
    }

    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventTerminate])
    {
        NSLog(@"++++++++++PlayDetailViewController:-Terminate");
    }
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventFail])
    {
        NSLog(@"++++++++++PlayDetailViewController:-kBCOVPlaybackSessionLifecycleEventFail");
        if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0)
        {
            NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:self.mSelectedIndexPath, @"indexPath", [NSNumber numberWithBool:NO], @"isPlayblackURIFail", nil];
            [self performSelector:@selector(createVideoLoadingFailureErrorView:) withObject:aDict afterDelay:.5];
        }
    }
}

- (void)highLightCellWithPlayStateFrameForIndexPath:(NSIndexPath *)indexPath
{
    [self setCurrentPlayingVideoId:nil withTimeProgress:nil];
    [_controlsViewController setCurrentPlayingVideoId:nil withTimeProgress:nil];
    [_controlsViewController setCurrentPlayingVideoDuration:nil];

    if (self.mVideoListDataSource.count && indexPath.row <= self.mVideoListDataSource.count)
    {
        self.mSelectedIndexPath = indexPath;

        self.mVisibleCells = [[NSMutableSet alloc] initWithArray:[self.mCollectionView visibleCells]];

        [self applyBlurEffectOnVisibleCellsWithSelectedIndexPath:indexPath];
    }

    if (indexPath.row == 0)
    {
        [self breakVideoLockSetUp];
    }
}
- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration
{
}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeExternalPlaybackActive:(BOOL)externalPlaybackActive
{
}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didPassCuePoints:(NSDictionary *)cuePointInfo
{
}
- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    self.videoView.hidden = NO;
}

- (void)setPreviousSelectedIndex:(NSIndexPath *)aIndex
{
    self.mPreviousVideoPlayIndex = -1;
    [self removeBlurEffectOnVisibleCellsWithAnimationDuration:0.0 withResizingCell:YES];
    self.mSelectedIndexPath = aIndex;
    [self prepareDeeplinkingVideoToCenterWithIndex:aIndex];
}
- (void)prepareDeeplinkingVideoToCenterWithIndex:(NSIndexPath *)aIndex
{
    NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndex.row + 1 inSection:aIndex.section];
    if (!self.isMoviePlayerInFullScreen)
    {
        [self moveCollectionCellToCenterForIndexPath:aNextIndexPath withAnimation:NO];
    }
    [self performSelector:@selector(playNextVideo) withObject:nil afterDelay:0.2];
}
- (void)playNextVideo
{
    self.isMoviePlaying = NO;
    if (self.isMoviePlayerInFullScreen)
    {
        NSIndexPath *aIndexPath = self.mSelectedIndexPath;
        if (aIndexPath)
        {
            NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row + 1 inSection:aIndexPath.section];

            if (!self.isFromPlayList)
            {
                if (aNextIndexPath.row > self.mVideoListDataSource.count)
                {
                    aNextIndexPath = [NSIndexPath indexPathForRow:1 inSection:aIndexPath.section];
                }
            }

            self.mSelectedIndexPath = aNextIndexPath;

            if (aNextIndexPath.row > self.mVideoListDataSource.count)
            {
                @try
                {
                    self.isMoviePlayerInFullScreen = NO;
                    self.canChangeToLandScape = NO;
                    self.controlsViewController.isEntredFullScreen = NO;
                    self.controlsViewController.playerSkipBack.hidden = YES;
                    self.controlsViewController.PublisherImg.hidden = YES;
                    self.controlsViewController.placeholderText.hidden = YES;
                    [self hideNarBarWithShareAddButton:NO];

                    [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

                    //                    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

                    [self.controlsViewController.fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];

                    [self.fullscreenViewController dismissViewControllerAnimated:NO
                                                                      completion:^{
                                                                        NSLog(@" thread2=%@", [NSThread currentThread]);

                                                                        if (CGRectIsEmpty(self.cgRectVideoView))
                                                                        {
                                                                            self.cgRectVideoView = CGRectMake(0, self.isDetailViewOverLayVisible ? 0 + kVideoPlayerYaxisDelta : 0 + kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta);
                                                                            NSLog(@"Widthfrom = %f Heigtfrom = %f", self.cgRectVideoView.size.width, self.cgRectVideoView.size.height);
                                                                        }

                                                                        self.videoView.frame = self.cgRectVideoView;

                                                                        [self addChildViewController:self.controlsViewController];
                                                                        [self.controlsViewController didMoveToParentViewController:self];

                                                                        self.fullscreenViewController = nil;
                                                                        self.isfullscreenViewControllerPresented = NO;

                                                                      }];

                    {
                        [self resetSetupForVideoDetailView];
                        [self handleExitFullScreenButtonPressed];
                    }

                    if (self.isDetailViewOverLayVisible)
                    {
                        if (self.isFromPlayList)
                        {
                            [self removeVideoDetailViewForlastVideoInPlayList];
                        }
                        else
                        {
                            [self removeVideoDetailView];
                        }
                    }

                    [self performSelector:@selector(scrollToNextCell) withObject:nil afterDelay:.5];
                    if (self.isFromPlayList)
                    {
                        [self performSelector:@selector(popController) withObject:nil afterDelay:0.5];
                    }
                }
                @catch (NSException *exception)
                {
                    NSLog(@"Exception = %@", exception);
                }
            }
            else
            {
                if (self.isDetailViewOverLayVisible)
                {
                    CGRect aFrame = self.mDetailView.frame;
                    aFrame.origin.y = self.view.frame.size.height;
                    self.isMoviePlayerInFullScreen = YES;
                    [MoviePlayerSingleton removeDefaultControls];
                    __weak PlayDetailViewController *weakSelf = self;
                    weakSelf.mVideoDetailHideButton.hidden = YES;
                    [weakSelf.mVideoDetailHideButton removeFromSuperview];

                    weakSelf.mDetailView.frame = aFrame;
                    [self resetVideoViewFrame];

                    weakSelf.isDetailViewOverLayVisible = NO;
                    [weakSelf hideBackButton:NO];
                    [weakSelf.mDetailView removeFromSuperview];

                    weakSelf.mDetailView = nil;
                    self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;
                }
                [self resetVideoViewFrame];

                [self hideNarBarWithShareAddButton:NO];
                [self moveCollectionCellToCenterForIndexPath:self.mSelectedIndexPath withAnimation:NO];
                [self performSelector:@selector(highLightCellWithPlayStateFrameForIndexPath:) withObject:self.mSelectedIndexPath afterDelay:.3];
                if (self.mVideoListDataSource.count && aNextIndexPath.row <= self.mVideoListDataSource.count)
                {
                    self.currentCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:aNextIndexPath];

                    [self getPlayBackURIFromServerForSelectedVideoforIndexPath:aNextIndexPath];
                }
                else
                {
                    self.currentCell = nil;
                }
            }
        }
    }
    else
    {
        if (self.isFromPlayList)
        {
            NSIndexPath *IndexPath = self.mSelectedIndexPath;

            if (IndexPath)
            {
                NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:IndexPath.row + 1 inSection:IndexPath.section];
                if (aNextIndexPath.row > self.mVideoListDataSource.count)
                {
                    [self popController];
                }
            }
        }

        if (self.isDetailViewOverLayVisible)
        {
            [self removeVideoDetailView];
        }
        [self.controlsViewController.fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];

        [self.fullscreenViewController dismissViewControllerAnimated:NO
                                                          completion:^{
                                                            NSLog(@" thread1=%@", [NSThread currentThread]);

                                                            if (CGRectIsEmpty(self.cgRectVideoView))
                                                            {
                                                                self.cgRectVideoView = CGRectMake(self.mCollectionView.frame.origin.x, 0 + kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta);
                                                            }

                                                            self.videoView.frame = self.cgRectVideoView;

                                                            [self addChildViewController:self.controlsViewController];

                                                            NSIndexPath *aIndexPath = self.mSelectedIndexPath;
                                                            if (aIndexPath)
                                                            {
                                                                NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row + 1 inSection:aIndexPath.section];

                                                                if (self.mVideoListDataSource.count && aNextIndexPath.row <= self.mVideoListDataSource.count)
                                                                {
                                                                    self.currentCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:aNextIndexPath];
                                                                    [self.currentCell.mVideoImageView addSubview:self.videoView];
                                                                    [self.currentCell.mVideoImageView bringSubviewToFront:self.videoView];
                                                                }
                                                            }
                                                            [self.controlsViewController didMoveToParentViewController:self];
                                                            self.fullscreenViewController = nil;
                                                            self.isfullscreenViewControllerPresented = NO;
                                                          }];

        if (self.mSelectedIndexPath && self.mSelectedIndexPath.row != 0 && self.mSelectedIndexPath.row <= self.mVideoListDataSource.count)
        {
            [self resetSetupForVideoDetailView];
        }

        [self performSelector:@selector(scrollToNextCell) withObject:nil afterDelay:.5];
    }

    self.mCollectionView.scrollEnabled = YES;
}

- (void)playPreviousVideo
{
    self.isMoviePlaying = NO;
    if (self.isMoviePlayerInFullScreen)
    {
        NSIndexPath *aIndexPath = self.mSelectedIndexPath;
        if (aIndexPath)
        {
            NSIndexPath *aNextIndexPath = [NSIndexPath indexPathForRow:aIndexPath.row - 1 inSection:aIndexPath.section];

            self.mSelectedIndexPath = aNextIndexPath;

            if (aNextIndexPath.row < 1)
            {
                @try
                {
                    self.isMoviePlayerInFullScreen = NO;
                    self.canChangeToLandScape = NO;
                    self.controlsViewController.isEntredFullScreen = NO;
                    self.controlsViewController.playerSkipBack.hidden = YES;
                    self.controlsViewController.PublisherImg.hidden = YES;
                    self.controlsViewController.placeholderText.hidden = YES;
                    [self hideNarBarWithShareAddButton:NO];

                    [self setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

                    //                    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

                    [self.controlsViewController.fullscreenButton setImage:[UIImage imageNamed:@"playerExpand.png"] forState:UIControlStateNormal];

                    [self.fullscreenViewController dismissViewControllerAnimated:NO
                                                                      completion:^{
                                                                        NSLog(@" thread2=%@", [NSThread currentThread]);

                                                                        if (CGRectIsEmpty(self.cgRectVideoView))
                                                                        {
                                                                            self.cgRectVideoView = CGRectMake(0, self.isDetailViewOverLayVisible ? 0 + kVideoPlayerYaxisDelta : 0 + kVideoPlayerYaxisDelta, self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9.0) + kVideoPlayerHeightDelta);
                                                                        }

                                                                        self.videoView.frame = self.cgRectVideoView;

                                                                        [self addChildViewController:self.controlsViewController];
                                                                        [self.controlsViewController didMoveToParentViewController:self];
                                                                        self.fullscreenViewController = nil;
                                                                        self.isfullscreenViewControllerPresented = NO;

                                                                      }];

                    {
                        [self resetSetupForVideoDetailView];
                        [self handleExitFullScreenButtonPressed];
                    }

                    if (self.isDetailViewOverLayVisible)
                    {
                        [self removeVideoDetailView];
                    }

                    [self performSelector:@selector(scrollToNextCell) withObject:nil afterDelay:.5];
                }
                @catch (NSException *exception)
                {
                    NSLog(@"Exception = %@", exception);
                }
            }
            else
            {
                if (self.isDetailViewOverLayVisible)
                {
                    CGRect aFrame = self.mDetailView.frame;
                    aFrame.origin.y = self.view.frame.size.height;
                    self.isMoviePlayerInFullScreen = YES;
                    [MoviePlayerSingleton removeDefaultControls];
                    __weak PlayDetailViewController *weakSelf = self;
                    weakSelf.mVideoDetailHideButton.hidden = YES;
                    [weakSelf.mVideoDetailHideButton removeFromSuperview];

                    weakSelf.mDetailView.frame = aFrame;
                    [self resetVideoViewFrame];

                    weakSelf.isDetailViewOverLayVisible = NO;
                    [weakSelf hideBackButton:NO];
                    [weakSelf.mDetailView removeFromSuperview];

                    weakSelf.mDetailView = nil;
                    self.controlsViewController.infoButtonForShowingDetailsView.hidden = YES;
                }
                [self hideNarBarWithShareAddButton:NO];
                [self moveCollectionCellToCenterForIndexPath:self.mSelectedIndexPath withAnimation:NO];
                [self performSelector:@selector(highLightCellWithPlayStateFrameForIndexPath:) withObject:self.mSelectedIndexPath afterDelay:.3];
                if (self.mVideoListDataSource.count && aNextIndexPath.row <= self.mVideoListDataSource.count)
                {
                    self.currentCell = (PlayDetailCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:aNextIndexPath];

                    [self getPlayBackURIFromServerForSelectedVideoforIndexPath:aNextIndexPath];
                }
                else
                {
                    self.currentCell = nil;
                }
            }
        }
    }
}

#pragma mark Guest User Login

- (void)updateChannelSubscriptionStatusForVideoModelsInGenre
{
    if (self.isFromGenre)
    {
        [self.mVideoListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

          __block VideoModel *aVideoModel = (VideoModel *)obj;
          aVideoModel.isVideoFollowing = self.mAddFollowButton.selected;

        }];
    }
}

- (void)addNotificationForFollowStatusWhenGusetUserLogin
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchChannelSubscriptionWhenGuestLogin) name:@"fetchChannelSubscriptionWhenGuestLogin" object:nil];
    }
}

- (void)fetchChannelSubscriptionWhenGuestLogin
{
    if (self.isFromSearch || self.isFromGenre)
    {
        [self getSubscriptionStatusForChannelId];
    }
    else
    {
        [self fetchUniqueChannelsSubscriptionStatus:self.mVideoListDataSource];
    }
}

- (void)fetchUniqueChannelsSubscriptionStatus:(NSArray *)aVideoArr
{
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        __weak PlayDetailViewController *weakSelf = self;

        NSArray *channelId = [aVideoArr valueForKey:@"channelId"];

        NSSet *aSet = [NSSet setWithArray:channelId];
        [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {

          __block NSString *aChannelId = (NSString *)obj;
          [[ServerConnectionSingleton sharedInstance] sendrequestToGetSubscriptionStatusForChannel:aChannelId
                                                                                 withResponseBlock:^(BOOL success) {

                                                                                   [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                                     [weakSelf updateSubscribtionStatusForSameChannelId:aChannelId withStatus:success];
                                                                                   }];

                                                                                 }
                                                                                        errorBlock:^(NSError *error){

                                                                                        }];

        }];
    }
}

- (void)addCellBorderColor:(PlayDetailCollectionViewCell *)aCell
{
    float aCellImageXAxis = 0;
    aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
    aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
    aCell.mVideoImageView.layer.borderWidth = 12.0;
    aCell.mVideoImageView.layer.borderColor = [UIColor colorWithRed:0.105882 green:0.113725 blue:0.117647 alpha:1.0].CGColor;
}

- (void)removeCellBorderColor:(PlayDetailCollectionViewCell *)aCell
{
    float aCellImageXAxis = 0;
    aCell.mImageViewLeadingConstraint.constant = aCellImageXAxis;
    aCell.mImageViewTrailingConstraint.constant = aCellImageXAxis;
    aCell.mVideoImageView.layer.borderWidth = 0.0;
    aCell.mVideoImageView.layer.borderColor = [UIColor clearColor].CGColor;
}

//For deeplinking

- (void)scrollToDeeplinkingVideoId
{
    self.canSelectCell = YES;
    if (self.mVideoListDataSource.count > 0)
    {
        __block NSIndexPath *aIndexPath = nil;
        if (self.deeplinkVideoId)
        {
            [self.mVideoListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

              VideoModel *aVideoModel = (VideoModel *)obj;

              if ([aVideoModel.uniqueId isEqualToString:self.deeplinkVideoId])
              {
                  aIndexPath = [NSIndexPath indexPathForItem:idx + 1 inSection:0];
                  return;
              }
            }];
        }

        if ([self.deeplinkVideoId isEqualToString:@"0"])
        {
            if (aIndexPath == nil)
            {
                aIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
            }
        }
        else
        {
            if (aIndexPath == nil)
            {
                [self createErrorScreenForDeepLinkDataUnavailble:kDeepLinkingVideoUnAvailable];
                return;
            }
        }

        if (self.isViewDisappeared)
        {
            self.mPreviousVideoPlayIndex = aIndexPath.item + 1;
            return;
        }

        [self hideBackButton:NO];
        [self hideNarBarWithShareAddButton:NO];
        [self stopAndRemoveMoviePlayer];
        [self moveCollectionCellToCenterForIndexPath:aIndexPath withAnimation:NO];
        [self performSelector:@selector(highLightCollectionCellForIndexPath:) withObject:aIndexPath afterDelay:.4];
    }
}

// Error screen from deeplinking if data not avaliable
- (void)createErrorScreenForDeepLinkDataUnavailble:(NSString *)aMsg
{
    if (self.mDeepLinkErrorView == nil)
    {
        self.mDeepLinkErrorView = [[UIView alloc] initWithFrame:self.view.frame];
        CGRect aFrame = self.mDeepLinkErrorView.frame;
        self.mDeepLinkErrorView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];
        UIImage *aErrorImage = [UIImage imageNamed:@"attentionLarge.png"];
        UIImageView *aErrorImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.mDeepLinkErrorView.frame.size.width - aErrorImage.size.width) / 2, ((self.mDeepLinkErrorView.frame.size.height - aErrorImage.size.height) / 2) - 64, aErrorImage.size.width, aErrorImage.size.height)];
        aErrorImageView.image = aErrorImage;
        [self.mDeepLinkErrorView addSubview:aErrorImageView];

        float aErrorLabelWidth = aFrame.size.width - 20;
        UILabel *aErrorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, aErrorImageView.frame.size.height + aErrorImageView.frame.origin.y + 22, aErrorLabelWidth, 20)];
        aErrorLabel.numberOfLines = 1;
        aErrorLabel.textAlignment = NSTextAlignmentCenter;
        aErrorLabel.text = aMsg;
        aErrorLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
        aErrorLabel.adjustsFontSizeToFitWidth = YES;
        aErrorLabel.textColor = [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0];
        [self.mDeepLinkErrorView addSubview:aErrorLabel];

        UIButton *aBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aBackButton.frame = CGRectMake((aFrame.size.width - 90) / 2, aErrorLabel.frame.origin.y + aErrorLabel.frame.size.height + 38, 90, 30);
        [aBackButton setTitle:@" Back " forState:UIControlStateNormal];
        [aBackButton setTitleColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
        [aBackButton addTarget:self action:@selector(onClickingDeeplinkingBackButton) forControlEvents:UIControlEventTouchUpInside];
        aBackButton.layer.borderWidth = 1.0;
        aBackButton.layer.cornerRadius = 2.0;
        aBackButton.layer.borderColor = [UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:1.0].CGColor;
        aBackButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
        [self.mDeepLinkErrorView addSubview:aBackButton];
        [self.view addSubview:self.mDeepLinkErrorView];
    }
}

- (void)removeErrorScreenForDeepLinkDataUnavailble
{
    if (self.mDeepLinkErrorView)
    {
        [self.mDeepLinkErrorView removeFromSuperview];
        self.mDeepLinkErrorView = nil;
    }
}

- (void)onClickingDeeplinkingBackButton
{
    UITabBarController *aTabbarcntrl = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    UINavigationController *navigationController = (UINavigationController *)[aTabbarcntrl.viewControllers objectAtIndex:0];
    [navigationController popToRootViewControllerAnimated:NO];
    aTabbarcntrl.selectedIndex = 0;
}
#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    NSString *strToView = @"";
    if (self.isFromPlayList)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"PlaylistDetails/PlaylistId-%@/PlaylistTitle-%@", self.mDataModel.uniqueId, self.mDataModel.title]];
    }
    else if (self.isFromHistoryScreen)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"VideoId-%@/VideoTitle-%@/ShowDetails/ShowId-%@/ShowTitle-%@", self.mVideoModel.uniqueId, self.mVideoModel.title, self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }
    else if (self.isLogoClicked)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"VideoId-%@/VideoTitle-%@/ShowDetails/ShowId-%@/ShowTitle-%@", self.mClickedVideoModelShowLogo.uniqueId, self.mClickedVideoModelShowLogo.title, self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }
    else if (self.isFromSearch && self.isEpisodeClicked)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"VideoId-%@/VideoTitle-%@/ShowDetails/ShowId-%@/ShowTitle-%@", self.mVideoModel.uniqueId, self.mVideoModel.title, self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }
    else if (self.isFromSearch && self.isFromGenre)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"ShowDetails/ShowId-%@/ShowTitle-%@", self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }

    else if (self.isFromGenre)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"ShowDetails/ShowId-%@/ShowTitle-%@", self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }
    else if (self.isFromProvider)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"ShowDetails/ShowId-%@/ShowTitle-%@", self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }

    else if (self.isFromShowBottomPlayDetailScreen)
    {
        strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"ShowDetails/ShowId-%@/ShowTitle-%@", self.mChannelDataModel.uniqueId, self.mChannelDataModel.title]];
    }

    return strToView;
}

#pragma mark Apsflyer Tracking Events

- (void)trackPlaylistsShowsEventforContentView:(NSString *)valueForPlaylist_Shows trackVideoEvent:(NSString *)valueForVideo
{
    [[AppsFlyerTracker sharedTracker] trackEvent:AFEventContentView withValues:@{AFEventParam1 : valueForPlaylist_Shows, AFEventParam2 : valueForVideo}];
}

- (void)fetchPlaybackURIForNextVideoModelIndex:(NSIndexPath *)aIndexPath
{
    if (aIndexPath.item < self.mVideoListDataSource.count)
    {
        VideoModel *aVideoModel = [self.mVideoListDataSource objectAtIndex:aIndexPath.item];
        if (!aVideoModel.playbackURI)
        {
            if ([self.mFetchingVideoIndexPathArray containsObject:aIndexPath])
            {
                NSLog(@"Request is already in progress to get playbackUri For VideoId:%@", aVideoModel.uniqueId);
                return;
            }
            else
            {
                [self.mFetchingVideoIndexPathArray addObject:aIndexPath];
            }
            NSLog(@"Send request to get playbackUri For VideoId:%@", aVideoModel.uniqueId);

            __weak PlayDetailViewController *weakSelf = self;

            NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aVideoModel.uniqueId, @"videoId", [NSNumber numberWithBool:self.isFetchPlayBackURIWithMaxBitRate], @"isMaxBitRate", nil];

            [[ServerConnectionSingleton sharedInstance] sendRequestToGetPlaybackURIForVideoId:aDict
                responseBlock:^(NSDictionary *responseDict) {
                  weakSelf.isFetchPlayBackURIWithMaxBitRate = NO;
                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if ([weakSelf.mFetchingVideoIndexPathArray containsObject:aIndexPath])
                    {
                        [weakSelf.mFetchingVideoIndexPathArray removeObject:aIndexPath];
                    }
                    NSString *aPlaybackURI = [responseDict objectForKey:@"uri"];
                    NSDictionary *aLogDataDict = [responseDict objectForKey:@"logData"];
                    if (aLogDataDict)
                    {
                        aVideoModel.logData = aLogDataDict;
                    }
                    if (aPlaybackURI)
                    {
                        aVideoModel.playbackURI = aPlaybackURI;

                        if (aIndexPath.item + 1 == self.mSelectedIndexPath.item)
                        {
                            [weakSelf playVideoForURI:aPlaybackURI forIndexPath:self.mSelectedIndexPath];
                            self.controlsViewController.placeholderText.text = aVideoModel.title; // We are adding this from BC Merge
                            self.controlsViewController.videoModal = aVideoModel;
                            [self addChannelLogoForControlsControllerInLandScapeMode];
                        }
                    }

                  }];

                }
                errorBlock:^(NSError *error) {
                  NSLog(@"Error-%@", error.localizedDescription);
                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if ([weakSelf.mFetchingVideoIndexPathArray containsObject:aIndexPath])
                    {
                        [weakSelf.mFetchingVideoIndexPathArray removeObject:aIndexPath];
                    }

                  }];
                }];
        }
    }
}

- (void)rotateToPotraitMode
{
    [self performSelector:@selector(roatateToPotraitModeWithDelay) withObject:nil afterDelay:1.2];
}

- (void)roatateToPotraitModeWithDelay
{
    [self.controlsViewController exitFullScrenWhenSignUpAndLogin];
    [self breakVideoLockSetUp];
}

- (void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation
{
    _isHidden = hidden;
    _stausBarAnimation = animation;
    [self setNeedsStatusBarAppearanceUpdate];
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return self.stausBarAnimation;
}

- (BOOL)prefersStatusBarHidden
{
    return self.isHidden;
}

@end
