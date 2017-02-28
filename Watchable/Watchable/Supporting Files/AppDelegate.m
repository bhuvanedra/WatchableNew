//
//  AppDelegate.m
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "AppDelegate.h"
#import "PlayDetailViewController.h"
#import "ParentViewController.h"
#import "LoginParentViewController.h"
#import "PlayListViewController.h"
#import "AnalyticsTokens.h"
#import "AnalyticsEventsHandler.h"
#import "BrightCovePlayerSingleton.h"
#import "SettingsViewController.h"
#import "DBHandler.h"
#import "UserProfile.h"
#import "TutorialOverLayView.h"
#import "SignUpViewController.h"
#import "SignUpLoginOverLayView.h"
#import "LoginViewController.h"
#import "GAI.h"
#import "GAIFields.h"
#import "LaunchViewController.h"
#import "SwrveUtility.h"
#import "DeepLink.h"
#import "GenreViewController.h"
#import "Watchable-Swift.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

/*
 //Bitly Api Key
 #define kBitlySDKAppIDKey   @"a864d36b50bb4d269b3c11b010256005"
 #define kBitlySupportDomainURL  @"wchbl.co"
 #define kBitlySupportedScheme  @"Watchable"
 
 */

@interface AppDelegate () <UITabBarControllerDelegate>
@property (nonatomic, strong) TutorialOverLayView *mTutorialOverLayView;

@property (nonatomic, strong) UIView *aConfirmEmailView;
@property (nonatomic, weak) UIViewController *mPreviousErrorViewController;
@property (nonatomic, assign) BOOL isConfirmEmailToastGUIRemovedByTimer;
@property (strong, nonatomic) NSTimer *heartBeatTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, assign) NSUInteger mPreviousSelectedIndex;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[self performSelectorInBackground:@selector(initializeBitlySdk) withObject:nil];

    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification)
    {
        // Do something with remoteNotification
        [self handleSwrvePushData:remoteNotification];
    }

    //Swrve push notification config -- Start
    // [self registerForPushNotifications];

    [[SwrveUtility sharedInstance] intializeSwrveSdk];
    //Swrve push notification-- end

    [self clearTokens];
    [self initializeGoogleAnalyticsForWatchable];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    TweaksEnabler *tweaksEnabler = [[TweaksEnabler alloc] init];
    self.window = (UIWindow *)[tweaksEnabler tweakableWindowWithFrame:[[UIScreen mainScreen] bounds]];

    self.isHistoryScreenLanched = NO;
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
    self.isAppEnterBackground = NO;
    self.isAirplayConnected = NO;
    [[AnalyticsTokens new] getAnalyticsTokens];

    if (tweaksEnabler.shouldUseNewUI)
    {
        BaseTabBarController *tabBarController = [[BaseTabBarController alloc] init];

        self.window.rootViewController = tabBarController;
        [self.window makeKeyAndVisible];
    }
    else
    {
        if ([self checkIfUserAlreadyLoggedIn])
        {
            [self setTabBarControllerAsRootViewController];
        }
        else
        {
            [self setLoginNavControllerAsRootViewController];
        }
    }

    self.mPreviousSelectedIndex = 0;

    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(updateConfirmEmailToastGUI)
    //                                                 name:UIApplicationWillEnterForegroundNotification
    //                                               object:[UIApplication sharedApplication]];

    [self saveContext];

    [self appStartEvent];

    // [self performSelector:@selector(updateAnalyticsEvent:) withObject:kEventNameAppStart afterDelay:5];
    self.currentDeviceOrientation = UIDeviceOrientationPortrait;

    //AppsFlyer
    [self initializeAppsFlyer];

    //[self initializeBitlySdk];

    return YES;
}

- (void)initializeBitlySdk
{
    /*[Bitly initialize:kBitlySDKAppIDKey supportedDomains:[NSArray arrayWithObject:kBitlySupportDomainURL] supportedSchemes:[NSArray arrayWithObject:kBitlySupportedScheme] handler:^(BitlyResponse * _Nullable response, BitlyError * _Nullable error) {
     NSLog(@"----Bitly Response block -----");
     if(error)
     {
     NSLog(@" bitly error - %@",error);
     [Bitly retryError:error];
     }
     else if(response.url)
     {
     NSLog(@"response bitly response - %@",response);
     NSURL *aURL= [NSURL URLWithString:response.url];
     NSURL *aAppLinkURL= [NSURL URLWithString:response.applink];
     
     NSLog(@"response bitly aURL - %@",aURL);
     if(aAppLinkURL)
     {
     
     [self performSelectorOnMainThread:@selector(parseURLAndHandleDeepLink:) withObject:aAppLinkURL waitUntilDone:NO];
     }
     }
     }];*/
}

- (void)removeSignUpOverLay
{
    if (self.mSignUpLoginOverLayView)
    {
        [self.mSignUpLoginOverLayView cancelSignInOverLay];
    }
}

- (void)initializeGoogleAnalyticsForWatchable
{
    // Automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;

    // Set the dispatch interval for automatic dispatching.
    [GAI sharedInstance].dispatchInterval = 1;

    // Set the appropriate log level for the default logger.
    [GAI sharedInstance].logger.logLevel = kGAILogLevelVerbose;

    // Initialize a tracker using a Google Analytics property ID.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:kGoogleAnalyticsTrackingId];
    //    tracker.allowIDFACollection = YES;
    [tracker set:kGAIAppName value:@"Watchable iOS"];
}

- (void)updateAnalyticsEvent:(NSString *)eventName
{
    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeLifeCycle eventName:eventName andUserId:[Utilities getCurrentUserId]];
}

- (void)updateHeartBeat
{
    [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeHeartBeat eventName:kEventNameHeartBeat andUserId:[Utilities getCurrentUserId]];
}

- (void)startHeartBeatTimer
{
    [self stopHeartBeatTimer];
    self.heartBeatTimer = [NSTimer scheduledTimerWithTimeInterval:kHeartBeatTimeInterval
                                                           target:self
                                                         selector:@selector(updateHeartBeat)
                                                         userInfo:nil
                                                          repeats:YES];
    [self.heartBeatTimer fire];
}

- (void)stopHeartBeatTimer
{
    [self.heartBeatTimer invalidate];
    self.heartBeatTimer = nil;
}

- (void)showConfirmBannerinController:(UIViewController *)aController
{
    if (self.aConfirmEmailView == nil)
    {
        CGRect aFrame = aController.view.frame;
        self.aConfirmEmailView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, aFrame.size.width, 50)];
        self.aConfirmEmailView.backgroundColor = [UIColor colorWithRed:243.0 / 255.0 green:156.0 / 255.0 blue:18.0 / 255.0 alpha:.8];
        UIImage *aErrorImage = [UIImage imageNamed:@"error.png"];
        UIImageView *aErrorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 5, aErrorImage.size.width, aErrorImage.size.height)];
        aErrorImageView.image = aErrorImage;
        [self.aConfirmEmailView addSubview:aErrorImageView];

        UIButton *aViewMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aViewMoreButton.frame = CGRectMake(aFrame.size.width - 110, 10, 90, 30);
        [aViewMoreButton setTitle:@"View more" forState:UIControlStateNormal];
        [aViewMoreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [aViewMoreButton addTarget:self action:@selector(onClickingViewMoreButton) forControlEvents:UIControlEventTouchUpInside];
        aViewMoreButton.layer.borderWidth = 1.0;
        aViewMoreButton.layer.cornerRadius = 2.0;
        aViewMoreButton.layer.borderColor = [UIColor whiteColor].CGColor;
        aViewMoreButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
        [self.aConfirmEmailView addSubview:aViewMoreButton];

        float aErrorLabelWidth = aFrame.size.width - (aErrorImageView.frame.origin.x + aErrorImageView.frame.size.width + 12 + 115);
        UILabel *aErrorLabel = [[UILabel alloc] initWithFrame:CGRectMake(aErrorImageView.frame.origin.x + aErrorImageView.frame.size.width + 12, 0, aErrorLabelWidth, 50)];
        aErrorLabel.numberOfLines = 2;
        aErrorLabel.text = @"Please confirm your email";
        aErrorLabel.lineBreakMode = NSLineBreakByWordWrapping;
        aErrorLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
        aErrorLabel.textColor = [UIColor whiteColor];
        [self.aConfirmEmailView addSubview:aErrorLabel];
        //[self hideConfirmBanner:YES];

        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self.aConfirmEmailView addGestureRecognizer:swipeRight];

        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.aConfirmEmailView addGestureRecognizer:swipeLeft];
    }

    [self updateConfirmEmailToastGUI];

    [aController.view addSubview:self.aConfirmEmailView];

    /* if(self.isEmailConfirmedForUser)
     {
     
     [self onSuccessfullEmailConfirmation];
     }
     else
     {
     if(!self.isConfirmEmailToastSwipped)
     {
     [self hideConfirmBanner:NO];
     }
     else
     {
     [self hideConfirmBanner:YES];
     }
     }*/
}

- (void)onClickingViewMoreButton
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        [self.window.rootViewController presentViewController:[AlertFactory networkOffline] animated:YES completion:nil];

        return;
    }
    else
    {
        //do view more action

        UINavigationController *navigationController = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:2];
        [navigationController popToRootViewControllerAnimated:NO];
        self.tabBarCntlr.selectedIndex = 2;

        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

        SettingsViewController *aSettingsViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
        aSettingsViewController.isPushedForConfirmEmail = YES;
        [navigationController pushViewController:aSettingsViewController animated:NO];
    }
}

- (void)onSuccessfullEmailConfirmation
{
    self.isEmailConfirmedForUser = YES;
    [self hideConfirmBanner:YES];
}

- (void)onSwipConfirmEmailToast
{
    self.isConfirmEmailToastSwipped = YES;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture
{
    CGRect frame = self.aConfirmEmailView.frame;

    if (gesture.direction == UISwipeGestureRecognizerDirectionRight)
        frame.origin.x = self.aConfirmEmailView.bounds.size.width;
    else if (gesture.direction == UISwipeGestureRecognizerDirectionLeft)
        frame.origin.x = -self.aConfirmEmailView.bounds.size.width;
    else
        NSLog(@"Unrecognized swipe direction");

    // Now animate the changing of the frame

    [UIView animateWithDuration:0.5
        animations:^{
          self.aConfirmEmailView.frame = frame;

        }
        completion:^(BOOL finished) {
          self.isConfirmEmailToastSwipped = YES;
          [self.aConfirmEmailView setHidden:YES];
        }];
}

- (void)hideConfirmBanner:(BOOL)isHide
{
    NSLog(@"hide=%d", isHide);
    if (self.aConfirmEmailView != nil)
    {
        [self.aConfirmEmailView setHidden:isHide];

        if (isHide)
        {
            CGRect frame = self.aConfirmEmailView.frame;
            frame.origin.x = -self.aConfirmEmailView.bounds.size.width;
            frame.origin.y = 64;
            self.aConfirmEmailView.frame = frame;
        }
        else
        {
            CGRect frame = self.aConfirmEmailView.frame;
            frame.origin.x = 0;
            frame.origin.y = 64;
            self.aConfirmEmailView.frame = frame;
            NSInteger aSelectedIndex = [self.tabBarCntlr selectedIndex];
            UINavigationController *navigationController = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];

            ParentViewController *aController = (ParentViewController *)navigationController.topViewController;
            [aController.view bringSubviewToFront:self.aConfirmEmailView];
            if (aController.mErrorView && (aController.mErrorType == ServiceErrorWithTryAgainButton || aController.mErrorType == InternetFailureWithTryAgainButton))
            {
                self.aConfirmEmailView.hidden = YES;
            }
        }
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (tabBarController.selectedIndex != 2)
    {
        self.mPreviousSelectedIndex = tabBarController.selectedIndex;
    }
    if (tabBarController.selectedIndex == 1)
    {
        [self checkGenreNavigationStackHavingDeepLinkingShowController];
    }
    [self updateConfirmEmailToastGUI];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    UINavigationController *aNavigationStack = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:tabBarController.selectedIndex];

    if ([aNavigationStack.topViewController isMemberOfClass:[PlayDetailViewController class]])
    {
        PlayDetailViewController *aPlaydetailController = (PlayDetailViewController *)aNavigationStack.topViewController;
        if (aPlaydetailController.isMoviePlaying)
        {
            [aPlaydetailController setSelectedIndexToPreviouslyPlayedVideoId];
        }
    }

    return YES;
}
- (void)checkGenreNavigationStackHavingDeepLinkingShowController
{
    UINavigationController *GenreNavigationStack = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:1];

    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:GenreNavigationStack.viewControllers];

    if (viewControllers.count)
    {
        if (![[viewControllers objectAtIndex:0] isMemberOfClass:[GenreViewController class]])
        {
            UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

            GenreViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"GenreViewController"];
            [viewControllers removeAllObjects];
            [viewControllers addObject:aPlayListDetailViewController];
            GenreNavigationStack.viewControllers = viewControllers;
        }
    }
}

- (void)didTimerFireForRemovingConfirmEmailToastGUI
{
    self.isConfirmEmailToastGUIRemovedByTimer = YES;
    [UIView animateWithDuration:0.27
        delay:1.0
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{

          [self.aConfirmEmailView setHidden:YES];
        }
        completion:^(BOOL finished) {

          CGRect frame = self.aConfirmEmailView.frame;
          frame.origin.x = -self.aConfirmEmailView.bounds.size.width;
          frame.origin.y = 64;
          self.aConfirmEmailView.frame = frame;
        }];

    [self hideConfirmBanner:YES];
}

- (BOOL)isConfirmEmailToastGUIRemovedByTimerFire
{
    return self.isConfirmEmailToastGUIRemovedByTimer;
}

- (void)resetConfirmEmailToastGUIRemovedByTimerFireFlag
{
    self.isConfirmEmailToastGUIRemovedByTimer = NO;
}
- (void)updateConfirmEmailToastGUI
{
    // check if email status ==2

    if (self.isConfirmEmailToastGUIRemovedByTimerFire)
    {
        [self hideConfirmBanner:YES];
        return;
    }

    if (self.tabBarCntlr)
    {
        if (self.isEmailConfirmedStatusReceived)
        {
            if (!self.isEmailConfirmedForUser)
            {
                if (!self.isConfirmEmailToastSwipped)
                {
                    self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;

                    NSInteger aSelectedIndex = [self.tabBarCntlr selectedIndex];
                    NSLog(@"aselected index=%ld", aSelectedIndex);
                    UINavigationController *navigationController = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];

                    ParentViewController *aController = (ParentViewController *)navigationController.topViewController;

                    if (aController.scrollViewContentOffSet.y < 115)
                    {
                        if (aController.mErrorView && aController.mErrorType != InternetFailureInLandingScreenTryAgainButton)
                        {
                            [self hideConfirmBanner:YES];
                        }
                        else
                        {
                            [self hideConfirmBanner:NO];
                            if (!self.aConfirmEmailView.isHidden)
                            {
                                [aController.view bringSubviewToFront:self.aConfirmEmailView];
                            }
                        }
                    }
                    else
                    {
                        [self hideConfirmBanner:YES];
                    }
                }
                else
                {
                    [self hideConfirmBanner:YES];
                }
            }
            else
            {
                [self onSuccessfullEmailConfirmation];
            }
        }
        else
        {
            [self hideConfirmBanner:YES];
        }
    }
}

- (void)animateConfirmEmailToastToVisibleWithErrorViewVisible:(BOOL)isErrorViewVisible
{
    if (self.isConfirmEmailToastGUIRemovedByTimerFire)
    {
        [self hideConfirmBanner:YES];
        return;
    }

    if (!isErrorViewVisible)
    {
        if (self.isEmailConfirmedForUser || self.isConfirmEmailToastSwipped)
        {
            return;
        }
        else
        {
            if (self.isEmailConfirmedStatusReceived)
            {
                self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;

                UINavigationController *navigationController = (UINavigationController *)self.tabBarCntlr.selectedViewController;

                ParentViewController *aController = (ParentViewController *)navigationController.topViewController;

                if (aController.scrollViewContentOffSet.y < 115)
                {
                    //NSLog(@"visible");

                    self.aConfirmEmailView.frame = CGRectMake(0, 64, self.aConfirmEmailView.frame.size.width, 50);
                    self.aConfirmEmailView.hidden = NO;
                    //            [UIView animateWithDuration:.01
                    //                             animations:^{
                    //
                    //                                 self.aConfirmEmailView.frame=CGRectMake(0, 64, self.aConfirmEmailView.frame.size.width, 50);
                    //                                 self.aConfirmEmailView.hidden=NO;
                    //                             }
                    //                             completion:^(BOOL finished){
                    //
                    //                             }];
                }
                else
                {
                    self.aConfirmEmailView.frame = CGRectMake(0, -54, self.aConfirmEmailView.frame.size.width, 54);
                    self.aConfirmEmailView.hidden = NO;

                    //NSLog(@"not visible");
                    //            [UIView animateWithDuration:.01
                    //                             animations:^{
                    //
                    //                                 self.aConfirmEmailView.frame=CGRectMake(0, -54, self.aConfirmEmailView.frame.size.width, 54);
                    //                                 self.aConfirmEmailView.hidden=NO;
                    //                             }
                    //                             completion:^(BOOL finished){
                    //
                    //                             }];
                }

                if (aController.mErrorView)
                {
                    self.aConfirmEmailView.hidden = YES;
                }
            }
            else
            {
                [self hideConfirmBanner:YES];
            }
        }
    }
    else
    {
        self.aConfirmEmailView.hidden = YES;
    }

    if (self.tabBarCntlr)
    {
        UINavigationController *navigationController = (UINavigationController *)self.tabBarCntlr.selectedViewController;
        ParentViewController *aController = (ParentViewController *)navigationController.topViewController;

        if (aController.mErrorView)
        {
            if (aController.scrollViewContentOffSet.y < 115)
            {
                aController.mErrorView.frame = CGRectMake(0, 64, self.aConfirmEmailView.frame.size.width, aController.mErrorView.frame.size.height);
            }
            else
            {
                aController.mErrorView.frame = CGRectMake(0, -aController.mErrorView.frame.size.height, self.aConfirmEmailView.frame.size.width, aController.mErrorView.frame.size.height);
            }
        }
    }
}

- (void)getLoggedInUserEmailConfirmStatus
{
    NSArray *theArr = self.tabBarCntlr.viewControllers;
    UINavigationController *aNavController = (UINavigationController *)[theArr objectAtIndex:0];
    PlayListViewController *aPlayListViewController = (PlayListViewController *)[aNavController.viewControllers objectAtIndex:0];

    [aPlayListViewController getUserProfileFromServer];
}
- (BOOL)checkIfUserAlreadyLoggedIn
{
    NSString *aAuthorizationStr = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];

    UserProfile *aUserProfile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];

    if (aAuthorizationStr.length && aUserProfile)
        return YES;

    return NO;
}

- (void)setTabBarForGuestUserWithTutorialOverLay:(BOOL)presentTutorialOverlay
{
    [self setGuestUser:YES];
    self.mPreviousSelectedIndex = 0;
    [[DBHandler sharedInstance] deleteUserProfileFromDB];
    [Utilities resetPreferences];
    self.isConfirmEmailToastSwipped = NO;
    self.isEmailConfirmedForUser = NO;
    self.isEmailConfirmedStatusReceived = NO;
    self.isConfirmEmailToastGUIRemovedByTimer = NO;
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
    self.aConfirmEmailView = nil;

    self.isTutorialOverLayPresentToUser = presentTutorialOverlay;

    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    UIViewController *aTabBarController = [aStoryboard instantiateViewControllerWithIdentifier:@"TabbarController"];

    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    self.window.rootViewController = aTabBarController;
    self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;
    self.tabBarCntlr.selectedIndex = 0;
    self.tabBarCntlr.delegate = self;
    [self.window makeKeyAndVisible];
    [self setTabBarImages];
    [self startHeartBeatTimer];
}

- (void)setGuestUser:(BOOL)geustUser
{
    self.isGuestUser = geustUser;
}
- (void)setTabBarControllerAsRootViewControllerFromSignUp:(BOOL)isFromSignUp
{
    self.mPreviousSelectedIndex = 0;

    if (isFromSignUp)
    {
        self.isTutorialOverLayPresentToUser = YES;
    }
    else
    {
        self.isTutorialOverLayPresentToUser = NO;
    }
    [self setGuestUser:NO];
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    UIViewController *aTabBarController = [aStoryboard instantiateViewControllerWithIdentifier:@"TabbarController"];

    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    self.window.rootViewController = aTabBarController;
    self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;
    self.tabBarCntlr.selectedIndex = 0;
    self.tabBarCntlr.delegate = self;
    [self.window makeKeyAndVisible];
    [self setTabBarImages];
    [self startHeartBeatTimer];
}

- (void)setTabBarControllerAsRootViewController
{
    self.mPreviousSelectedIndex = 0;

    [self setGuestUser:NO];
    self.isTutorialOverLayPresentToUser = NO;
    NSNumber *aNumber = (NSNumber *)[Utilities getValueFromUserDefaultsForKey:@"emailStatus"];
    if (aNumber.boolValue)
    {
        self.isEmailConfirmedForUser = YES;
        self.isEmailConfirmedStatusReceived = YES;
    }
    else
    {
        self.isEmailConfirmedForUser = NO;
        self.isEmailConfirmedStatusReceived = NO;
        self.isConfirmEmailToastSwipped = NO;
        self.isConfirmEmailToastGUIRemovedByTimer = NO;
    }
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    UIViewController *aTabBarController = [aStoryboard instantiateViewControllerWithIdentifier:@"TabbarController"];

    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    self.window.rootViewController = aTabBarController;
    self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;
    self.tabBarCntlr.selectedIndex = 0;
    self.tabBarCntlr.delegate = self;
    [self.window makeKeyAndVisible];
    [self setTabBarImages];
}

- (void)setLoginNavControllerAsRootViewController
{
    [self setGuestUser:NO];
    self.isTutorialOverLayPresentToUser = NO;
    //[self stopHeartBeatTimer];
    //    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    //    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [Utilities resetPreferences];
    // NSString *aAuthorizationStr= [Utilities getValueFromUserDefaultsForKey:@"Authorization"];
    self.isConfirmEmailToastSwipped = NO;
    self.isEmailConfirmedForUser = NO;
    self.isEmailConfirmedStatusReceived = NO;
    self.isConfirmEmailToastGUIRemovedByTimer = NO;
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
    self.aConfirmEmailView = nil;
    self.tabBarCntlr = nil;
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    UINavigationController *aLoginNavigationController = [aStoryboard instantiateViewControllerWithIdentifier:@"LoginViewNavigationController"];
    self.window.rootViewController = aLoginNavigationController;
    [self.window makeKeyAndVisible];
}

- (void)presentSignUpControllerInPlayList
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SignUpViewController *aSignUpViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];
    aSignUpViewController.isPresented = YES;
    aSignUpViewController.presentedFromScreen = TutorialOverLayScreen;
    UINavigationController *playListNavigationStack = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:0];

    [playListNavigationStack presentViewController:aSignUpViewController animated:NO completion:nil];
}
- (void)setTabBarImages
{
    UITabBarItem *playListTabBarItem = [self.tabBarCntlr.tabBar.items objectAtIndex:0];
    UIImage *PlayTabHighLightimg = [UIImage imageNamed:@"tabPlaylists.png"];
    PlayTabHighLightimg = [PlayTabHighLightimg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    [playListTabBarItem setSelectedImage:PlayTabHighLightimg];
    playListTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);

    UITabBarItem *genreListTabBarItem = [self.tabBarCntlr.tabBar.items objectAtIndex:1];
    UIImage *genreTabHighLightimg = [UIImage imageNamed:@"tabBrowse.png"];
    genreTabHighLightimg = [genreTabHighLightimg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    [genreListTabBarItem setSelectedImage:genreTabHighLightimg];
    genreListTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);

    UITabBarItem *myShowsTabBarItem = [self.tabBarCntlr.tabBar.items objectAtIndex:2];
    UIImage *myShowsTabHighLightimg = [UIImage imageNamed:@"tabMyShows.png"];
    myShowsTabHighLightimg = [myShowsTabHighLightimg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    [myShowsTabBarItem setSelectedImage:myShowsTabHighLightimg];
    myShowsTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
}

- (void)createErrorViewForController:(UIViewController *)aController withErrorType:(eErrorType)aErrorType withTryAgainSelector:(SEL)aSelector withInputParameters:(NSArray *)aInputParameters
{
    if ([aController isKindOfClass:[ParentViewController class]])
    {
        ParentViewController *aParentController = (ParentViewController *)aController;
        if (aParentController.mErrorView)
            [self removeErrorViewFromController:aController];
    }
    else if ([aController isKindOfClass:[LoginParentViewController class]])
    {
        LoginParentViewController *aParentController = (LoginParentViewController *)aController;
        if (aParentController.mErrorView)
            [self removeErrorViewFromController:aController];
    }

    ErrorView *aErrorView = [[ErrorView alloc] initWithFrame:aController.view.frame withErrorType:aErrorType];
    if ([aController isKindOfClass:[ParentViewController class]])
    {
        ParentViewController *aParentController = (ParentViewController *)aController;
        aParentController.mErrorView = aErrorView;
        aParentController.mErrorType = aErrorType;
    }
    else if ([aController isKindOfClass:[LoginParentViewController class]])
    {
        LoginParentViewController *aLoginParentViewController = (LoginParentViewController *)aController;
        aLoginParentViewController.mErrorView = aErrorView;
    }
    aErrorView.tryAgainController = aController;
    aErrorView.tryAgainParameters = aInputParameters;
    aErrorView.tryAgainSelector = aSelector;
    [aController.view addSubview:aErrorView];

    [self animateWithBounceForErrorView:aErrorView];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

      if (aErrorType != InternetFailureInLandingScreenTryAgainButton)
      {
          [self.aConfirmEmailView setHidden:YES];
      }
      else
      {
          if (!self.aConfirmEmailView.isHidden)
          {
              [aController.view bringSubviewToFront:self.aConfirmEmailView];
          }
      }

      //        [NSObject cancelPreviousPerformRequestsWithTarget:self
      //                                                 selector:@selector(removeErrorViewFromController:)
      //                                                   object:nil];
    }];

    if (self.mPreviousErrorViewController == aController)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    self.mPreviousErrorViewController = aController;

    if (aErrorType == InternetFailureWithTryAgainMessage || aErrorType == ServiceErrorWithTryAgainMessage || aErrorType == ServiceErrorWithTryAgainMessageForBitlyShortURL)
    {
        [self performSelector:@selector(removeErrorViewFromController:) withObject:aController afterDelay:6];
    }
}

- (void)animateWithBounceForErrorView:(ErrorView *)aErrorView
{
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

- (void)removeErrorViewFromController:(UIViewController *)aController
{
    if ([aController isKindOfClass:[ParentViewController class]])
    {
        ParentViewController *aParentController = (ParentViewController *)aController;
        if (aParentController.mErrorView)
        {
            [aParentController.mErrorView removeFromSuperview];
            aParentController.mErrorView = nil;
        }
    }
    else if ([aController isKindOfClass:[LoginParentViewController class]])
    {
        LoginParentViewController *aLoginParentViewController = (LoginParentViewController *)aController;
        if (aLoginParentViewController.mErrorView)
        {
            [aLoginParentViewController.mErrorView removeFromSuperview];
            aLoginParentViewController.mErrorView = nil;
        }
    }
    [self updateConfirmEmailToastGUI];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (self.tabBarCntlr)
    {
        UINavigationController *navigationController = (UINavigationController *)self.tabBarCntlr.selectedViewController;

        UIViewController *aController = navigationController.topViewController;

        if (!self.isSignUpOverLayClicked)
        {
            UIInterfaceOrientationMask aUIInterfaceOrientationMask;
            if (self.currentDeviceOrientation == UIDeviceOrientationPortrait || self.currentDeviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            {
                aUIInterfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
            }
            else
            {
                aUIInterfaceOrientationMask = UIInterfaceOrientationMaskLandscape;
            }

            if (((AppDelegate *)kSharedApplicationDelegate).mSignUpLoginOverLayView)
            {
                return aUIInterfaceOrientationMask;
            }
            else
            {
                UIViewController *presentedVc = aController.presentedViewController;
                if ([presentedVc isMemberOfClass:[UINavigationController class]])
                {
                    UINavigationController *navCntlr = (UINavigationController *)presentedVc;
                    UIViewController *vc = [[navCntlr viewControllers] objectAtIndex:0];

                    if ([vc isMemberOfClass:[LoginViewController class]])
                    {
                        return aUIInterfaceOrientationMask;
                    }
                }
                else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
                {
                    return aUIInterfaceOrientationMask;
                }
            }
        }
        UIViewController *presentedVc = aController.presentedViewController;
        if ([presentedVc isMemberOfClass:[UINavigationController class]])
        {
            UINavigationController *navCntlr = (UINavigationController *)presentedVc;
            UIViewController *vc = [[navCntlr viewControllers] objectAtIndex:0];

            if ([vc isMemberOfClass:[LoginViewController class]])
            {
                return UIInterfaceOrientationMaskPortrait;
            }
        }
        else if ([presentedVc isMemberOfClass:[SignUpViewController class]])
        {
            return UIInterfaceOrientationMaskPortrait;
        }

        UIDeviceOrientation aOrientation = [UIDevice currentDevice].orientation;
        self.tabBarCntlr = (UITabBarController *)self.window.rootViewController;

        if ([aController isKindOfClass:[PlayDetailViewController class]])
        {
            PlayDetailViewController *aControl = (PlayDetailViewController *)aController;

            if (aControl.isMoviePlaying)
            {
                if ([aControl isFullScreenMovieViewPresented])
                {
                    return UIInterfaceOrientationMaskLandscape;
                }
                else if ([aControl canChangeToLandScapeMode])
                {
                    if (aOrientation == UIDeviceOrientationPortraitUpsideDown)
                        return UIInterfaceOrientationMaskPortrait;

                    return UIInterfaceOrientationMaskAllButUpsideDown;
                }

                return UIInterfaceOrientationMaskPortrait;
            }

            return UIInterfaceOrientationMaskPortrait;
        }
        else
            return UIInterfaceOrientationMaskPortrait;
    }
    else
        return UIInterfaceOrientationMaskPortrait;
}

- (void)dispalyPlayListControllerAddedEmailConfirmToastIfNotSwipeOut
{
    if (!self.isConfirmEmailToastSwipped)
    {
        if (self.tabBarCntlr)
        {
            if (self.tabBarCntlr.selectedIndex == 0)
            {
                UINavigationController *playListNavigationStack = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:0];

                NSArray *aPlayListStackControllers = playListNavigationStack.viewControllers;
                if (aPlayListStackControllers.count == 1)
                {
                    PlayListViewController *aPlayListViewController = (PlayListViewController *)[aPlayListStackControllers objectAtIndex:0];
                    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
                    [self resetConfirmEmailToastGUIRemovedByTimerFireFlag];
                    [aPlayListViewController addConfirmEmailBannerVisibility];

                    return;
                }
            }
            self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = YES;
        }
    }
}

- (void)signUpCompletedFromTutorialOverLayScreen
{
    [self setGuestUser:NO];
    self.isTutorialOverLayPresentToUser = NO;
}

- (void)showLoginSignInScreenForGuestUserOnClickingFollow
{
    if (!self.mSignUpLoginOverLayView)
    {
        NSString *aNibName = @"SignUpLoginOverLayView";
        BOOL isLandScape = NO;
        if (self.currentDeviceOrientation == UIDeviceOrientationLandscapeLeft || self.currentDeviceOrientation == UIDeviceOrientationLandscapeRight)
        {
            aNibName = @"SignUpLoginOverLayLandscapeView";
            isLandScape = YES;
        }

        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:aNibName
                                                             owner:self
                                                           options:nil];
        //I'm assuming here that your nib's top level contains only the view
        //you want, so it's the only item in the array.
        SignUpLoginOverLayView *myView = (SignUpLoginOverLayView *)[nibContents objectAtIndex:0];

        myView.mLandscapeDescViewConstraint.constant = 200;
        self.mSignUpLoginOverLayView = myView;
        self.mSignUpLoginOverLayView.frame = self.window.bounds;
        self.mSignUpLoginOverLayView.isPresentedInLandScape = isLandScape;
        [self.mSignUpLoginOverLayView addUIElements];

        UINavigationController *navigationController = (UINavigationController *)self.tabBarCntlr.selectedViewController;

        UIViewController *aController = navigationController.topViewController;

        [self.window addSubview:self.mSignUpLoginOverLayView];
        if ([aController isMemberOfClass:[PlayDetailViewController class]])
        {
            PlayDetailViewController *playVc = (PlayDetailViewController *)aController;

            [playVc handlePauseOfPlayerWhenOverlayPresented];
        }
    }
}

- (void)removeLoginSignInScreenForGuestUserByClickingFollow
{
    if (self.mSignUpLoginOverLayView)
    {
        [UIView animateWithDuration:0.0
            animations:^{
              self.mSignUpLoginOverLayView.alpha = 0.0;
            }
            completion:^(BOOL finished) {
              [self.mSignUpLoginOverLayView removeFromSuperview];
              self.mSignUpLoginOverLayView = nil;

            }];
    }
}

- (void)addTutorialOverLayView
{
    if (!self.mTutorialOverLayView)
    {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"TutorialOverLayView"
                                                             owner:self
                                                           options:nil];
        //I'm assuming here that your nib's top level contains only the view
        //you want, so it's the only item in the array.
        TutorialOverLayView *myView = (TutorialOverLayView *)[nibContents objectAtIndex:0];
        self.mTutorialOverLayView = myView;
        self.mTutorialOverLayView.frame = self.window.bounds;
        self.mTutorialOverLayView.mGetWatchingBtn.layer.cornerRadius = 4.0;
        self.mTutorialOverLayView.mGetWatchingBtn.layer.masksToBounds = YES;
        [self.mTutorialOverLayView addUIElements];
        [self.window addSubview:self.mTutorialOverLayView];
    }
}

- (void)showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial
{
    if (self.tabBarCntlr)
    {
        if (self.tabBarCntlr.selectedIndex == 0)
        {
            UINavigationController *playListNavigationStack = (UINavigationController *)[self.tabBarCntlr.viewControllers objectAtIndex:0];

            NSArray *aPlayListStackControllers = playListNavigationStack.viewControllers;
            if (aPlayListStackControllers.count == 1)
            {
                PlayListViewController *aPlayListViewController = (PlayListViewController *)[aPlayListStackControllers objectAtIndex:0];
                self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
                [self resetConfirmEmailToastGUIRemovedByTimerFireFlag];
                [aPlayListViewController addConfirmEmailBannerVisibility];

                return;
            }
        }
    }
}

- (void)removeTutorialOverlayView
{
    if (self.mTutorialOverLayView)
    {
        [UIView animateWithDuration:0.4
            animations:^{
              self.mTutorialOverLayView.alpha = 0.0;
            }
            completion:^(BOOL finished) {
              [self.mTutorialOverLayView removeFromSuperview];
              self.mTutorialOverLayView = nil;
            }];
    }
}

- (void)clearTokens
{
    [Utilities clearSessionToken];
    [Utilities removeObjectFromPreferencesForKey:kSubSessionId];
    [Utilities removeObjectFromPreferencesForKey:kSessionTrackingId];
}

- (void)setTabbarTabToBrowseTab
{
    self.tabBarCntlr.selectedIndex = 1;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    [BrightCovePlayerSingleton stopMoviePlayer];
    //    [self updateAnalyticsEvent:kEventNameAppEnd];
    [self pauseLaunchScreenPlayer];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)pauseLaunchScreenPlayer
{
    if (!self.tabBarCntlr)
    {
        if ([self.window.rootViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *aRootViewController = (UINavigationController *)self.window.rootViewController;
            NSArray *aStackControllers = aRootViewController.viewControllers;
            if (aStackControllers.count)
            {
                if ([aStackControllers.firstObject isMemberOfClass:[LaunchViewController class]])
                {
                    LaunchViewController *aLaunchViewController = (LaunchViewController *)aStackControllers.firstObject;
                    [aLaunchViewController pauseMoviePlayer];
                }
            }
        }
    }
}

- (void)playLaunchScreenPlayer
{
    if (!self.tabBarCntlr)
    {
        if ([self.window.rootViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *aRootViewController = (UINavigationController *)self.window.rootViewController;
            NSArray *aStackControllers = aRootViewController.viewControllers;
            if (aStackControllers.count)
            {
                if ([aStackControllers.firstObject isMemberOfClass:[LaunchViewController class]])
                {
                    LaunchViewController *aLaunchViewController = (LaunchViewController *)aStackControllers.firstObject;
                    [aLaunchViewController playMoviePlayer];
                }
            }
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self beginBackgroundUpdateTask];
    [self updateAnalyticsEvent:kEventNameAppEnd];
    self.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
    //    [self updateAnalyticsEvent:kEventNameAppEnd];
    //self.isConfirmEmailToastSwipped=NO;
    [self stopHeartBeatTimer];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.isAppEnterBackground = YES;
    [self performSelector:@selector(clearTokens) withObject:nil afterDelay:1.5];
    [self pauseLaunchScreenPlayer];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    AnalyticsTokens *tokens = [AnalyticsTokens new];
    [tokens analyticsSubSessionId];
    [tokens analyticsSessionTrackingIdShouldFetchFromServer:NO];
    [self dispalyPlayListControllerAddedEmailConfirmToastIfNotSwipeOut];
    [self playLaunchScreenPlayer];

    [self appStartEvent];

    // [[BrightCovePlayerSingleton sharedInstance]resumeAdIfNeeded];

    //    [BrightCovePlayerSingleton playMoviePlayer];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //  [self performSelector:@selector(updateAnalyticsEvent:) withObject:kEventNameAppStart afterDelay:3];
    //    //if (self.tabBarCntlr != nil){
    //
    //  [self performSelector:@selector(startHeartBeatTimer) withObject:nil afterDelay:4];

    //    }else{
    //
    //        [self stopHeartBeatTimer];
    //    }

    if (!self.isAirplayConnected)
    {
        [self performSelector:@selector(stopPlayer) withObject:self afterDelay:.3];
    }
    else
    {
        [self performSelector:@selector(stopPlayer) withObject:self afterDelay:3];
    }

    // NSLog(@"Appdelegate getIsAdPlaying :- %hhd",[[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying]);

    if ([[BrightCovePlayerSingleton sharedInstance] getIsAdPlaying])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AdsPause" object:nil];
    }
    else
    {
        //  [[NSNotificationCenter defaultCenter] postNotificationName:@"videoPause" object:nil];
    }

    [self playLaunchScreenPlayer];
    //    [BrightCovePlayerSingleton playMoviePlayer];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    //AppsFlyer
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    // (Optional) to get AppsFlyer's attribution data you can use AppsFlyerTrackerDelegate as follow . Note that the callback will fail as long as the appleAppID and developer key are not set properly.
    [AppsFlyerTracker sharedTracker].delegate = self; //Delegate methods below

    NSString *aUserId = [Utilities getValueFromUserDefaultsForKey:kUserId];
    if (aUserId == nil)
    {
        UserProfile *aUserProfile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];
        if (aUserProfile)
        {
            [Utilities setValueForKeyInUserDefaults:aUserProfile.mUserId key:kUserId];
        }
    }
}

- (void)stopPlayer
{
    [BrightCovePlayerSingleton stopMoviePlayer];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    // [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeLifeCycle eventName:kEventNameAppEnd];
    [self saveContext];
}

- (void)beginBackgroundUpdateTask
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
      [self endBackgroundUpdateTask];
    }];
}

- (void)endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.comcast.Watchable" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Watchable" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }

    // Create the coordinator and store

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                               NSInferMappingModelAutomaticallyOption : @YES };

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Watchable.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark Guest User

- (void)setPreviousSelectedIndexOfTabBarWhenCancelClicked
{
    if (self.tabBarCntlr.selectedIndex == 2)
    {
        [self.tabBarCntlr setSelectedIndex:self.mPreviousSelectedIndex];
    }
}

#pragma mark Guest User
- (void)sendInfoToDeepLink:(NSDictionary *)aUntrimmedWhiteSpaceDict
{
    NSMutableDictionary *atrimmedWhiteSpaceDict = nil;
    if (aUntrimmedWhiteSpaceDict)
    {
        NSArray *arr = aUntrimmedWhiteSpaceDict.allKeys;
        for (int aCount = 0; aCount < arr.count; aCount++)
        {
            NSString *aKeyWhiteSpaceUntrimmedStr = [arr objectAtIndex:aCount];
            id aValueId = [aUntrimmedWhiteSpaceDict objectForKey:aKeyWhiteSpaceUntrimmedStr];
            if (![aValueId isKindOfClass:[NSString class]])
            {
                continue;
            }
            NSString *aValueWhiteSpaceUntrimmedStr = (NSString *)aValueId;

            NSString *aKeyWhiteSpacetrimmedStr = nil;
            NSString *aValueWhiteSpacetrimmedStr = nil;

            if (aKeyWhiteSpaceUntrimmedStr.length && aValueWhiteSpaceUntrimmedStr.length)
            {
                aKeyWhiteSpacetrimmedStr = [aKeyWhiteSpaceUntrimmedStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                aValueWhiteSpacetrimmedStr = [aValueWhiteSpaceUntrimmedStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }

            if (aKeyWhiteSpacetrimmedStr != nil && aValueWhiteSpacetrimmedStr != nil && aKeyWhiteSpacetrimmedStr.length && aValueWhiteSpacetrimmedStr.length)
            {
                if (atrimmedWhiteSpaceDict == nil)
                {
                    atrimmedWhiteSpaceDict = [[NSMutableDictionary alloc] init];
                }

                [atrimmedWhiteSpaceDict setObject:aValueWhiteSpacetrimmedStr forKey:[aKeyWhiteSpacetrimmedStr lowercaseString]];
            }
        }
    }

    if (atrimmedWhiteSpaceDict)
    {
        DeepLink *aDeepLinkObj = [[DeepLink alloc] init];
        [aDeepLinkObj handleDeepLinkingForIncomingDict:atrimmedWhiteSpaceDict];
    }
}

- (void)handleSwrvePushData:(NSDictionary *)aDict
{
    [self sendInfoToDeepLink:aDict];
}

#pragma mark Swrve Notification
- (void)registerForPushNotifications
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound];
    }

    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.

    [[AppsFlyerTracker sharedTracker] registerUninstall:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState == UIApplicationStateInactive)
    {
        [self performSelector:@selector(preformSwrvePushWithDelay:) withObject:userInfo afterDelay:1.0];
    }
}

- (void)preformSwrvePushWithDelay:(NSDictionary *)aDict
{
    NSLog(@"state=%ld", [[UIApplication sharedApplication] applicationState]);
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        [self handleSwrvePushData:aDict];
    }
}
#pragma mark AppsFlyer

- (void)initializeAppsFlyer
{
    // Initialize the SDK **** THE NEXT 2 LINES ARE MANDATORY *****

    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = kAppsFlyerDevKey; // You can get this key at the coniguration page of your app on AppsFlyer's dashboard.
    [AppsFlyerTracker sharedTracker].appleAppID = kAppsFlyerAppleAppID;  // The Apple app ID. Example 34567899

    [AppsFlyerTracker sharedTracker].useUninstallSandbox = NO;
}
#pragma mark AppsFlyerTrackerDelegate methods
- (void)onConversionDataReceived:(NSDictionary *)installData
{
    id status = [installData objectForKey:@"af_status"];
    if ([status isEqualToString:@"Non-organic"])
    {
        id sourceID = [installData objectForKey:@"media_source"];
        id campaign = [installData objectForKey:@"campaign"];
        NSLog(@"This is a none organic install.");
        NSLog(@"Media source: %@", sourceID);
        NSLog(@"Campaign: %@", campaign);
    }
    else if ([status isEqualToString:@"Organic"])
    {
        NSLog(@"This is an organic install.");
    }
}

- (void)onConversionDataRequestFailure:(NSError *)error
{
    NSLog(@"Failed to get data from AppsFlyer's server: %@", [error localizedDescription]);
}

#pragma mark Deeplink URL Handler

- (void)removeAllOverLayForDeepLink
{
    [self performSelectorOnMainThread:@selector(removeSignUpOverLay) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(removeTutorialOverlayView) withObject:nil waitUntilDone:NO];
}
#pragma mark Deeplink URL Handler

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler
{
    NSLog(@"continueUserActivity VALUE %@", userActivity.userInfo);
    NSLog(@"userActivity.activityType VALUE %@", userActivity.activityType);
    NSLog(@"userActivity.TITLE VALUE %@", userActivity.title);
    [self removeAllOverLayForDeepLink];
    BOOL aReturnVal = YES;
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb])
    {
        //aReturnVal =[Bitly handleUserActivity:userActivity];
    }
    else
    {
        // CSSearchableItemActionType
        //handle corespotlight search results
        // This activity represents an item indexed using Core Spotlight, so restore the context related to the unique identifier.

        // Note that the unique identifier of the Core Spotlight item is set in the activity’s userInfo property for the key CSSearchableItemActivityIdentifier.

        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType] && isCoreSpotLightEnable)
        {
            NSString *uniqueIdentifier = [userActivity.userInfo objectForKey:CSSearchableItemActivityIdentifier];
            if (uniqueIdentifier != nil)
            {
                NSMutableDictionary *dictUserinfo;
                NSArray *arrayUniqueId = [uniqueIdentifier componentsSeparatedByString:@","];
                for (int aCount = 0; aCount < arrayUniqueId.count;)
                {
                    if (dictUserinfo == nil)
                    {
                        dictUserinfo = [[NSMutableDictionary alloc] init];
                    }
                    [dictUserinfo setObject:[arrayUniqueId objectAtIndex:aCount + 1] forKey:[arrayUniqueId objectAtIndex:aCount]];

                    aCount = aCount + 2;
                }
                [self sendInfoToDeepLink:dictUserinfo];
            }
            else
            {
                [self sendInfoToDeepLink:userActivity.userInfo];
            }
        }
    }
    NSLog(@"continueUserActivity %d", aReturnVal);
    return aReturnVal;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [self parseURLAndHandleDeepLink:url];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options
{
    [self parseURLAndHandleDeepLink:url];
    return YES;
}

- (void)parseURLAndHandleDeepLink:(NSURL *)aURL
{
    /* NSMutableDictionary *aDict=nil;
     NSString *str = aURL.absoluteString;
     NSArray *arr = [str componentsSeparatedByString:@"info?"];
     if(arr.count==2)
     {
     NSString *aCombinedKeyValueStr=[arr objectAtIndex:1];
     if(aCombinedKeyValueStr)
     {
     
     NSArray *arr=[aCombinedKeyValueStr componentsSeparatedByString:@"&"];
     for(int aCount=0; aCount<arr.count;aCount++)
     {
     NSString *aKeyValueStr=[arr objectAtIndex:aCount];
     NSArray *aArray=[aKeyValueStr componentsSeparatedByString:@"="];
     if(aArray.count==2)
     {
     if(aDict==nil)
     {
     aDict= [[NSMutableDictionary alloc]init];
     }
     [aDict setObject:[aArray objectAtIndex:1] forKey:[aArray objectAtIndex:0]];
     }
     }
     }
     }
     if(aDict)
     {
     [self sendInfoToDeepLink:aDict];
     }
     */

    NSMutableDictionary *aDict = nil;
    // NSString *str = @"watchable://screen/playlist/playlistid/12wq/videoid/123";

    NSString *str = aURL.absoluteString;
    NSArray *arr = [str componentsSeparatedByString:@"//"];
    if (arr.count == 2)
    {
        NSString *aCombinedKeyValueStr = [arr objectAtIndex:1];
        if (aCombinedKeyValueStr)
        {
            NSArray *arr = [aCombinedKeyValueStr componentsSeparatedByString:@"/"];
            if (arr.count % 2 == 0)
            {
                for (int aCount = 0; aCount < arr.count;)
                {
                    if (aDict == nil)
                    {
                        aDict = [[NSMutableDictionary alloc] init];
                    }
                    [aDict setObject:[arr objectAtIndex:aCount + 1] forKey:[arr objectAtIndex:aCount]];

                    aCount = aCount + 2;
                }
            }
        }
    }
    if (aDict)
    {
        [self sendInfoToDeepLink:aDict];
    }
}
- (void)appStartEvent
{
    [self performSelector:@selector(updateAnalyticsEvent:) withObject:kEventNameAppStart afterDelay:3];
    //if (self.tabBarCntlr != nil){

    [self performSelector:@selector(startHeartBeatTimer) withObject:nil afterDelay:4];
}

@end
