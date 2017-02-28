//
//  ViewController.m
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PlayListViewController.h"
#import "PlayListCollectionViewCell.h"
#import "ServerConnectionSingleton.h"
#import "ImageURIBuilder.h"
#import "ShowModel.h"
#import "WatchableConstants.h"
#import "Utilities.h"
#import "PlayDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "PlaylistModel.h"
#import "GAUtilities.h"
#import "SwrveUtility.h"
#import "Watchable-Swift.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface PlayListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    BOOL isCellVisible;
}
@property (weak, nonatomic) IBOutlet UICollectionView *mPlayListCollectionView;
@property (nonatomic, strong) NSMutableArray *mPlayListDataSource;
@property (nonatomic, strong) Reachability *internetReachable;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL isrefreshing;
@property (nonatomic, assign) BOOL isStatusBarHidden;
@property (nonatomic) UIStatusBarAnimation stausBarAnimation;
@end

@implementation PlayListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
    if (aSharedDelegate.isTutorialOverLayPresentToUser)
    {
        [aSharedDelegate addTutorialOverLayView];
    }
    [self initialSetUp];
    [self getDataFromServer];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _isStatusBarHidden = NO;
    _stausBarAnimation = UIStatusBarAnimationNone;
    //    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveplaylistHome];
    if (self.isrefreshing)
    {
        self.mPlayListCollectionView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height - 60);
        [self.refreshControl beginRefreshing];
    }

    [GAUtilities setWatchbaleScreenName:@"PlaylistHomeScreen"];

    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (aAppDelegate.isAppFromBGToFGFirstTimeToPlayListViewWillAppear)
    {
        aAppDelegate.isAppFromBGToFGFirstTimeToPlayListViewWillAppear = NO;
        if (!aAppDelegate.isGuestUser)
        {
            [aAppDelegate resetConfirmEmailToastGUIRemovedByTimerFireFlag];
            [self addConfirmEmailBannerVisibility];
        }
    }
    [Utilities setAppBackgroundcolorForView:self.mPlayListCollectionView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.refreshControl endRefreshing];
}

- (void)getDataFromServer
{
    [self getDataFromServerForPlayList];

    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!aAppDelegate.isEmailConfirmedStatusReceived && !aAppDelegate.isGuestUser)
        [self getUserProfileFromServer];
}
- (void)initialSetUp
{
    [self createNavBarWithHidden:NO];
    [self setNavigationBarTitle:kNavTitlePlaylists withFont:nil withTextColor:nil];

    self.mPlayListCollectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.mPlayListDataSource = [[NSMutableArray alloc] init];

    self.refreshControl = [[UIRefreshControl alloc] init];

    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getDataFromServerForPlayListWhileRefresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.mPlayListCollectionView addSubview:self.refreshControl];
    self.mPlayListCollectionView.alwaysBounceVertical = YES;
    [self addConfirmEmailBannerVisibility];
}

- (void)addConfirmEmailBannerVisibility
{
    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (aAppDelegate.isEmailConfirmedStatusReceived && !aAppDelegate.isEmailConfirmedForUser)
    {
        if (!self.mErrorView)
        {
            [kSharedApplicationDelegate hideConfirmBanner:NO];
            [self createTimerForRemovingConfirmEmailToast];
        }
        else if (self.mErrorView && self.mErrorType == InternetFailureInLandingScreenTryAgainButton)
        {
            [kSharedApplicationDelegate hideConfirmBanner:NO];
            [self createTimerForRemovingConfirmEmailToast];
        }
    }
    else
    {
        [kSharedApplicationDelegate hideConfirmBanner:YES];
    }
}

- (void)createTimerForRemovingConfirmEmailToast
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(removeConfirmEmailToastGUI)
                                               object:nil];

    [self performSelector:@selector(removeConfirmEmailToastGUI) withObject:nil afterDelay:kConfirmEmailToastRemovalTime];
}

- (void)removeConfirmEmailToastGUI
{
    [kSharedApplicationDelegate didTimerFireForRemovingConfirmEmailToastGUI];
}
#pragma mark
#pragma mark UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mPlayListDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForItemAtIndexPath.row=%ld", (long)indexPath.row);

    PlayListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlayListCellId" forIndexPath:indexPath];

    if (isCellVisible)
    {
        cell.mPlayListImageView.frame = CGRectMake(cell.mPlayListImageView.frame.origin.x, cell.mPlayListImageView.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
        [Utilities addGradientToPlayListCellImageView:cell.mPlayListImageView];
    }
    cell.mTitleLabelWidthConstraint.constant = cell.frame.size.width - 100;
    cell.mDescriptionLabelWidthConstraint.constant = cell.frame.size.width - 80;

    PlaylistModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];

    cell.mPlayTitleLabel.text = [aModel.title uppercaseString];
    NSString *categoryLabelText = nil;
    if (aModel.genreTitle && (![aModel.genreTitle isEqualToString:@""]))
    {
        categoryLabelText = [NSString stringWithFormat:@"  %@  ", [aModel.genreTitle uppercaseString]];

        //cell.mPlayListCategoryLabel.text=[NSString stringWithFormat:@" %@  ",[aModel.genreTitle uppercaseString]];
    }
    else
    {
        categoryLabelText = [@"  genre  " uppercaseString];
    }

    NSString *aStr = [aModel.title uppercaseString];
    UIFont *afont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:40.0];
    NSDictionary *attr = @{NSFontAttributeName : afont, NSForegroundColorAttributeName : [UIColor whiteColor]};
    NSMutableAttributedString *aAttributedString = [[NSMutableAttributedString alloc] initWithString:aStr attributes:attr];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 0.8;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [aAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [aStr length])];
    cell.mPlayTitleLabel.attributedText = aAttributedString;

    NSMutableAttributedString *attributedStringForCategory = [[NSMutableAttributedString alloc] initWithString:categoryLabelText];
    NSMutableParagraphStyle *aparagraphStyle = [[NSMutableParagraphStyle alloc] init];

    [attributedStringForCategory addAttribute:NSParagraphStyleAttributeName value:aparagraphStyle range:NSMakeRange(0, [categoryLabelText length])];
    cell.mPlayListCategoryLabel.attributedText = attributedStringForCategory;

    cell.mPlayListCategoryLabel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    cell.mPlayListCategoryLabel.layer.borderWidth = .5f;

    if (aModel.shortDescription && (![aModel.shortDescription isEqualToString:@""]))
    {
        cell.mPlayListDescriptionLabel.text = aModel.shortDescription;
    }
    else
    {
        cell.mPlayListDescriptionLabel.text = @"";
    }

    NSString *imageUrlString = [ImageURIBuilder buildURLWithString:aModel.imageUri withSize:cell.bounds.size];
    // [cell.mActivityIndicator startAnimating];
    if (imageUrlString)
    {
        [cell.mPlayListImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                   placeholderImage:[UIImage imageNamed:@"browsePlaylistEmptyState.png"]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                            //[cell.mActivityIndicator stopAnimating];
                                            if (isCoreSpotLightEnable)
                                            {
                                                NSString *strUniqueID = [NSString stringWithFormat:@"%@,%@", kDeepLinkPlayListIdKey, aModel.uniqueId];

                                                [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[ strUniqueID ]
                                                                                                               completionHandler:^(NSError *_Nullable error) {
                                                                                                                 [self setSearchableItem:aModel image:image];
                                                                                                               }];
                                            }
                                          }];
    }
    else
    {
        cell.mPlayListImageView.image = [UIImage imageNamed:@"browsePlaylistEmptyState.png"];
    }

    [cell.contentView sendSubviewToBack:cell.mPlayListImageView];
    return cell;
}

#pragma mark
#pragma mark UICollectionView Delegate

- (void)postFeedFollowSwerveEvent:(NSString *)eventName andPlaylist:(PlaylistModel *)aModel
{
    NSDictionary *payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:nil
                                                                        assetId:nil
                                                                   channleTitle:nil
                                                                      channleId:nil
                                                                     genreTitle:aModel.genreTitle
                                                                        genreId:nil
                                                                 publisherTitle:nil
                                                                    publisherId:nil
                                                                  playlistTitle:aModel.title
                                                                     playlistId:aModel.uniqueId];

    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PlaylistModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];
    [self postFeedFollowSwerveEvent:kSwrveplaylistView andPlaylist:aModel];
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Selects Playlist"
                                          label:[NSString stringWithFormat:@"%@/PlaylistId-%@/PlaylistTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                       andValue:nil];
    [self pushPlayDetailControllerWithData:aModel];
}

#pragma mark
#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"layout indexPath.row=%ld", (long)indexPath.row);
    //float height=(collectionView.frame.size.width/16)*9;
    float height = 250;
    isCellVisible = YES;
    return CGSizeMake(collectionView.frame.size.width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (void)pushPlayDetailControllerWithData:(PlaylistModel *)aModel
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mDataModel = aModel;
    aPlayListDetailViewController.isFromPlayList = YES;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

#pragma mark
#pragma mark Server Call Method
- (void)getSessionTokenFromServer
{
    __weak PlayListViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {
          [weakSelf getDataFromServerForPlayList];
          [weakSelf getUserProfileFromServer];
        }
        errorBlock:^(NSError *error) {
          NSLog(@"error in getting session token");
        }];
}

- (void)getDataFromServerForPlayList
{
    __weak PlayListViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [self checkToShowTweakedPlaylistError];

    [weakSelf userInteractionEnableForViewElement:NO];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetPlayListresponseBlock:^(NSArray *responseArray) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf userInteractionEnableForViewElement:YES];
        [weakSelf.refreshControl endRefreshing];
        [weakSelf updateDataSource:responseArray];
        NSLog(@"getDataFromServerForPlayList");

      }];

    }
        errorBlock:^(NSError *error) {

          [weakSelf userInteractionEnableForViewElement:YES];

          NSLog(@"error-rgetDataFromServerForPlayList");
          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakSelf.refreshControl endRefreshing];
            if (error.code == kErrorCodeNotReachable)
            {
                [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:self.mPlayListDataSource.count > 0 ? InternetFailureWithTryAgainMessage : InternetFailureInLandingScreenTryAgainButton withTryAgainSelector:@selector(getDataFromServer) withInputParameters:nil];
            }
            else /*if(error.code==kServerErrorCode)*/
            {    //
                [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataFromServer) withInputParameters:nil];
            }
            /*  else
             {
             NSString *aErrorMsg=error.localizedDescription;
             weakSelf.mErrorMsgLabel.text=aErrorMsg;
             weakSelf.mErrorMsgLabel.text=aErrorMsg;
             weakSelf.mErrorMsgLabel.hidden=NO;
             }*/

          }];

        }];
}

- (void)checkToShowTweakedPlaylistError
{
    __weak PlayListViewController *weakSelf = self;
    TweaksEnabler *tweaksEnabler = [[TweaksEnabler alloc] init];
    if (tweaksEnabler.testPlaylistError)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:(eErrorType)tweaksEnabler.playlistErrorCode withTryAgainSelector:@selector(dismissErrorView) withInputParameters:nil];
    }
}

- (void)dismissErrorView
{
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:self];
}

- (void)getDataFromServerForPlayListWhileRefresh
{
    self.isrefreshing = YES;
    [self getDataFromServerForPlayList];
}

- (void)userInteractionEnableForViewElement:(BOOL)isEnable
{
    if (isEnable)
    {
        self.mPlayListCollectionView.userInteractionEnabled = YES;
        self.isrefreshing = NO;
    }
    else
    {
        self.mPlayListCollectionView.userInteractionEnabled = NO;
    }
}
- (void)getUserProfileFromServer
{
    //return;
    __weak PlayListViewController *weakSelf = self;

    NSString *aUsernameOrEmailStr = [Utilities getValueFromUserDefaultsForKey:@"LoginUserNameOrEmailKey"];
    NSString *aUsernameOrEmailKey = @"username";
    NSRange range = [aUsernameOrEmailStr rangeOfString:@"@"];
    if (range.location != NSNotFound)
    {
        aUsernameOrEmailKey = @"email";
    }
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aUsernameOrEmailStr, aUsernameOrEmailKey, nil];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetUserProfile:aDict
        withResponseBlock:^(NSDictionary *responseDict) {

          [weakSelf performSelectorOnMainThread:@selector(onGetProfileSuccessfull:) withObject:responseDict waitUntilDone:NO];

        }
        errorBlock:^(NSError *error) {

          //[weakSelf addNotificationForNetworkChanges];
          NSLog(@"error in getting user profile");
          [weakSelf performSelectorOnMainThread:@selector(addNotificationForNetworkChanges) withObject:nil waitUntilDone:NO];

        }
        withVimondCookie:NO];
}

- (void)onGetProfileSuccessfull:(NSDictionary *)aResponseDict
{
    [self removeNotificationForNetworkChanges];
    NSLog(@"onGetProfileSuccessfull");
    NSString *aStr = [aResponseDict objectForKey:@"emailStatus"];
    if (aStr)
    {
        if (![aStr isEqualToString:@"1"])
        {
            AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
            aSharedDelegate.isEmailConfirmedForUser = NO;
            aSharedDelegate.isEmailConfirmedStatusReceived = YES;
            aSharedDelegate.isConfirmEmailToastSwipped = NO;
            if (!self.mErrorView)
            {
                [kSharedApplicationDelegate hideConfirmBanner:NO];
                [self createTimerForRemovingConfirmEmailToast];
            }
            else if (self.mErrorView && self.mErrorType == InternetFailureInLandingScreenTryAgainButton)
            {
                [kSharedApplicationDelegate hideConfirmBanner:NO];
                [self createTimerForRemovingConfirmEmailToast];
            }

            [Utilities setValueForKeyInUserDefaults:[NSNumber numberWithBool:NO] key:@"emailStatus"];
        }
        else
        {
            AppDelegate *aSharedDelegate = kSharedApplicationDelegate;
            aSharedDelegate.isEmailConfirmedForUser = YES;
            aSharedDelegate.isEmailConfirmedStatusReceived = YES;
            [kSharedApplicationDelegate hideConfirmBanner:YES];
            [Utilities setValueForKeyInUserDefaults:[NSNumber numberWithBool:YES] key:@"emailStatus"];
        }
    }
}

- (void)updateDataSource:(NSArray *)aArray
{
    [self.mPlayListDataSource removeAllObjects];
    [self.mPlayListDataSource addObjectsFromArray:aArray];

    if (isCoreSpotLightEnable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setPlaylistItemIdexedBeforeReload:aArray];
        });
    }

    [self.mPlayListCollectionView reloadData];
}

- (BOOL)shouldAutorotate
{
    // Return YES for supported orientations
    return NO;
}

#pragma mark Scrollview Delegate Method
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    /*if(aPoint.y>115)
     {
     [self hideNarBarWithAnimation];
     }
     else
     {
     [self showNavBarWithAnimation];
     }*/
    float NavBarAlpha = 0.0;
    float aYposition = aPoint.y;

    if (aYposition < 1)
    {
        aYposition = 1;
    }
    NavBarAlpha = (aYposition / 150) * kNavBarMaxAlphaValue;
    NavBarAlpha = kNavBarMaxAlphaValue - NavBarAlpha;

    if (NavBarAlpha > kNavBarMaxAlphaValue)
    {
        NavBarAlpha = kNavBarMaxAlphaValue;
    }
    else if (NavBarAlpha < 0.0)
    {
        NavBarAlpha = 0.0;
    }

    NavBarAlpha = kNavBarMaxAlphaValue;
    [self setNavBarVisiblityWithAlpha:NavBarAlpha];
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}

#pragma mark
#pragma mark Reachablity Notification

- (void)addNotificationForNetworkChanges
{
    [self removeNotificationForNetworkChanges];
    if (self.internetReachable)
    {
        self.internetReachable = nil;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkNetworkStatus:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];

    // Set up Reachability
    self.internetReachable = [Reachability reachabilityForInternetConnection];
    BOOL isNotify = [self.internetReachable startNotifier];
    NSLog(@"isNotify=%d", isNotify);
}

- (void)removeNotificationForNetworkChanges
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
}
- (void)checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    Reachability *internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
        }
        break;
        case ReachableViaWiFi:
        case ReachableViaWWAN:
        {
            [self removeNotificationForNetworkChanges];
            [self getUserProfileFromServer];
        }
        break;
    }
}

#pragma mark
#pragma mark Deeplinking Methods
- (BOOL)isPlayListDataSourceAvaliable
{
    if (self.mPlayListDataSource.count)
    {
        return true;
    }

    return false;
}

- (NSUInteger)getDataSourcePlayListIdIndex:(NSString *)aPlayListId
{
    __weak PlayListViewController *weakSelf = self;
    __block NSUInteger aIndex = -1;
    [weakSelf.mPlayListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      PlaylistModel *aPlaylistModel = (PlaylistModel *)obj;
      if ([aPlaylistModel.uniqueId isEqualToString:aPlayListId])
      {
          aIndex = idx;
          *stop = YES;
      }

    }];

    return aIndex;
}

- (void)pushPlaydetailControllerWithIndex:(NSUInteger)aIndex withPlayListId:(NSString *)aPlayListId withVideoId:(NSString *)aVideoId withDelay:(float)aDelay
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.isFetchPlayBackURIWithMaxBitRate = YES;
    if (aIndex > -1)
    {
        PlaylistModel *aModel = [self.mPlayListDataSource objectAtIndex:aIndex];
        aPlayListDetailViewController.mDataModel = aModel;
        [self.mPlayListCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:aIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    aPlayListDetailViewController.deeplinkPlayListId = aPlayListId;
    aPlayListDetailViewController.isFromPlayList = YES;
    aPlayListDetailViewController.deeplinkVideoId = aVideoId;
    aPlayListDetailViewController.isPlayVideoForDeeplink = YES;

    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:[[self navigationController] viewControllers]];

    // Find the things to remove
    NSMutableArray *toDelete = [NSMutableArray array];

    for (int aCount = 1; aCount < viewControllers.count; aCount++)
    {
        UIViewController *objVC = (UIViewController *)[viewControllers objectAtIndex:aCount];

        [toDelete addObject:objVC];
    }
    [viewControllers removeObjectsInArray:toDelete];
    [viewControllers addObject:aPlayListDetailViewController];
    self.navigationController.viewControllers = viewControllers;

    //[self.navigationController pushViewController:aPlayListDetailViewController animated:NO];
}

#pragma mark
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mPlayListCollectionView.delegate = nil;
    self.mPlayListCollectionView.dataSource = nil;
    self.mPlayListDataSource = nil;
    [self.refreshControl endRefreshing];
    self.refreshControl = nil;
}

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    return @"PlaylistTab";
}

#pragma mark Core spotlight methods

- (void)setPlaylistItemIdexedBeforeReload:(NSArray *)arrayItems
{
    for (PlaylistModel *pModal in arrayItems)
    {
        [self setSearchableItem:pModal image:nil];
    }
}

- (void)setSearchableItem:(PlaylistModel *)pModal image:(UIImage *)img
{
    PlaylistModel *playlistModel = pModal;

    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeImage];
    if (img != nil)
    {
        NSData *dataImg = UIImagePNGRepresentation(img);
        attributeSet.thumbnailData = dataImg;
    }
    attributeSet.title = playlistModel.title;
    attributeSet.contentDescription = playlistModel.shortDescription;
    attributeSet.keywords = @[ playlistModel.title ];

    NSString *strUniqueID = [NSString stringWithFormat:@"%@,%@", kDeepLinkPlayListIdKey, playlistModel.uniqueId];

    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:strUniqueID domainIdentifier:@"com.wtchable" attributeSet:attributeSet];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ]
                                                   completionHandler:^(NSError *_Nullable error) {
                                                     if (!error)
                                                         NSLog(@"Playlist item indexed");
                                                   }];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return self.stausBarAnimation;
}

- (BOOL)prefersStatusBarHidden
{
    return self.isStatusBarHidden;
}

@end
@interface UINavigationController (StatusBarStyle)

@end

@implementation UINavigationController (StatusBarStyle)

- (UIStatusBarStyle)preferredStatusBarStyle
{
    //also you may add any fancy condition-based code here
    return UIStatusBarStyleLightContent;
}
@end
