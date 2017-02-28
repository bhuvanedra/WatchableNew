//
//  AppDelegate.h
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//
//  AppStoreProvisioningProfile : Watchable_V5_AppStoreProfile_Updated_24Mar16.mobileprovision // with pushnotification
//  BundleID: com.Xidio.Watchable

//testin push notification

// Swrve sandbox : Watchable_development_push
// Swrve Prodution : Watchable_updated_APNS_Appsflyer

#import <AppsFlyerLib/AppsFlyerTracker.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "SignUpLoginOverLayView.h"
#import "WatchableConstants.h"

typedef enum {
    InternetFailureWithTryAgainMessage = 4000,
    InternetFailureInLandingScreenTryAgainButton,
    InternetFailureWithTryAgainButton,
    ServiceErrorWithTryAgainButton,
    ServiceErrorWithTryAgainMessage,
    ServiceErrorWithTryAgainMessageForBitlyShortURL

} eErrorType;

@interface AppDelegate : UIResponder <UIApplicationDelegate, AppsFlyerTrackerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign) BOOL isConfirmEmailToastSwipped;
@property (nonatomic, assign) BOOL isEmailConfirmedForUser;
@property (nonatomic, assign) BOOL isEmailConfirmedStatusReceived;
@property (nonatomic, weak) UIView *mErrorView;
@property (nonatomic, assign) BOOL isHistoryScreenLanched;
@property (nonatomic, assign) BOOL isAppFromBGToFGFirstTimeToPlayListViewWillAppear;
@property (nonatomic, assign) BOOL isAppEnterBackground;
@property (nonatomic, assign) BOOL isAirplayConnected;
@property (nonatomic, assign) BOOL isTutorialOverLayPresentToUser;
@property (nonatomic, assign) BOOL isGuestUser;
@property (nonatomic, strong) UITabBarController *tabBarCntlr;
@property (nonatomic) UIDeviceOrientation currentDeviceOrientation;
@property (nonatomic, strong) SignUpLoginOverLayView *mSignUpLoginOverLayView;
@property (nonatomic, assign) BOOL isSignUpOverLayClicked;
@property (nonatomic) BOOL isVideoPlay;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)setTabBarControllerAsRootViewController;
- (void)setLoginNavControllerAsRootViewController;
- (void)showConfirmBannerinController:(UIViewController *)aController;
- (void)hideConfirmBanner:(BOOL)isHide;
- (void)onSuccessfullEmailConfirmation;
- (void)animateConfirmEmailToastToVisibleWithErrorViewVisible:(BOOL)isErrorViewVisible;

- (void)createErrorViewForController:(UIViewController *)aController withErrorType:(eErrorType)aErrorType withTryAgainSelector:(SEL)aSelector withInputParameters:(NSArray *)aInputParameters;
- (void)removeErrorViewFromController:(UIViewController *)aController;
- (void)getLoggedInUserEmailConfirmStatus;

- (void)didTimerFireForRemovingConfirmEmailToastGUI;

- (void)resetConfirmEmailToastGUIRemovedByTimerFireFlag;

- (void)setTabBarControllerAsRootViewControllerFromSignUp:(BOOL)isFromSignUp;
- (void)addTutorialOverLayView;
- (void)removeTutorialOverlayView;
//-(void)setTabBarForGuestUser;
- (void)setGuestUser:(BOOL)geustUser;
- (void)presentSignUpControllerInPlayList;
- (void)signUpCompletedFromTutorialOverLayScreen;
- (void)showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial;
- (void)showLoginSignInScreenForGuestUserOnClickingFollow;
- (void)removeLoginSignInScreenForGuestUserByClickingFollow;
- (void)setPreviousSelectedIndexOfTabBarWhenCancelClicked;
- (void)setTabbarTabToBrowseTab;
- (void)setTabBarForGuestUserWithTutorialOverLay:(BOOL)presentTutorialOverlay;
@end
