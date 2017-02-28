//
//  ProviderDetailViewController.m
//  Watchable
//
//  Created by Valtech on 3/11/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ProviderDetailViewController.h"
#import "GenreCollectionViewCell.h"

#import "ImageCacheSingleton.h"
#import "ServerConnectionSingleton.h"
#import "ImageURIBuilder.h"
#import "ShowModel.h"
#import "WatchableConstants.h"
#import "Utilities.h"
#import "ChannelModel.h"
#import "PlayDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "AnalyticsEventsHandler.h"
#import "SwrveUtility.h"
#import "ProviderModel.h"
#import "GAUtilities.h"
#import "Watchable-Swift.h"

@interface ProviderDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *mCollectionView;
@property (nonatomic, strong) NSMutableArray *mPlayListDataSource;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL isrefreshing;

@end

@implementation ProviderDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mProviderBGView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:kNavBarMaxAlphaValue];

    [Utilities addGradientToNavBarView:self.mProviderBGView withAplha:kNavBarMaxAlphaValue];

    [self.view bringSubviewToFront:self.mProviderBGView];
    [self setBackButtonOnView];

    self.mCollectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getDataFromServerForPlayListOnRefresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.mCollectionView addSubview:self.refreshControl];
    self.mCollectionView.alwaysBounceVertical = YES;
    [[self.refreshControl.subviews objectAtIndex:0] setFrame:CGRectMake(0, -8, self.refreshControl.frame.size.width, self.refreshControl.frame.size.height)];

    NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:_mProviderImageUrl ForImageType:Horizontal_logo withSize:CGSizeMake(_mProviderImageView.frame.size.width, _mProviderImageView.frame.size.height)];
    _mProviderImageView.backgroundColor = [UIColor clearColor];
    if (providerImageUrlString)
    {
        _mProviderImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_mProviderImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                               placeholderImage:nil
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                      }];
    }

    /* CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.mProviderBGView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor], nil];
    [self.mProviderBGView.layer insertSublayer:gradient atIndex:0];*/

    UINib *cellNib = [UINib nibWithNibName:@"GenreCollectionViewCell" bundle:nil];
    [self.mCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"GenreCollectionViewCell"];

    [self getDataFromServerForPlayList];
    //[self getSessionTokenFromServer];
    self.mPlayListDataSource = [[NSMutableArray alloc] init];
    [self addNotificationForFollowChannel];
    [Utilities setAppBackgroundcolorForView:self.mCollectionView];
    [Utilities setAppBackgroundcolorForView:self.view];
    [self addNotificationForFollowStatusWhenGusetUserLogin];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self postFeedFollowSwerveEvent:kSwrvefeedView andChannel:nil];
    if (self.isrefreshing)
    {
        self.mCollectionView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height - 60);
        [self.refreshControl beginRefreshing];
    }

    [GAUtilities setWatchbaleScreenName:@"ProviderDetailsScreen"];
    // [self getMyShowsListFromServer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.refreshControl endRefreshing];
}

- (void)getDataFromServerForPlayListOnRefresh
{
    self.isrefreshing = YES;
    [self getDataFromServerForPlayList];
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
}

- (void)postNotificationForFollowChannelId:(NSString *)aChannelId withFollowStatus:(BOOL)aFollowStatus
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:aChannelId, @"channelId", [NSNumber numberWithBool:aFollowStatus], @"followStatus", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationForFollowChannel" object:nil userInfo:userInfo];
}

- (void)updateDataSourceWithFollowStatus:(BOOL)aFollowStatus withChannelId:(NSString *)aChannelId
{
    [self.mPlayListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      ChannelModel *aChannelModel = (ChannelModel *)obj;

      if ([aChannelModel.uniqueId isEqualToString:aChannelId])
      {
          aChannelModel.isChannelFollowing = aFollowStatus;
      }

    }];

    [self.mCollectionView reloadData];
}

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
    GenreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GenreCollectionViewCell" forIndexPath:indexPath];
    cell.showImage.layer.cornerRadius = 1.0;
    cell.showImage.layer.masksToBounds = YES;

    ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];
    cell.showTitle.text = aModel.title;
    cell.showDescription.text = aModel.showDescription;

    cell.mFollowButton.selected = aModel.isChannelFollowing;

    cell.mFollowButton.hidden = NO;
    cell.mFollowButton.mIndexPath = indexPath;
    [cell.mFollowButton addTarget:self action:@selector(onClickingFollowButton:) forControlEvents:UIControlEventTouchUpInside];

    if (cell.mFollowButton.selected)
    {
        cell.mFollowButtonWidthConstraint.constant = 91.0;
    }
    else
    {
        cell.mFollowButtonWidthConstraint.constant = 70.0;
    }

    float aWidth = self.view.frame.size.width - (2 * 12);
    float aHeight = (aWidth / 2.0) * 1.0;
    CGSize aImageViewSize = CGSizeMake(aWidth, aHeight);

    NSString *imageUrlString = [ImageURIBuilder buildImageUrlWithString:aModel.relatedLinks[@"default-image"] ForImageType:Two2One_logo withSize:aImageViewSize];

    if (imageUrlString)
    {
        [cell.showImage sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                          placeholderImage:[UIImage imageNamed:@"logoEmptyState.png"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                 }];
    }
    else
    {
        cell.showImage.image = [UIImage imageNamed:@"logoEmptyState.png"];
    }

    return cell;
}

#pragma mark
#pragma mark UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];
    [self pushPlayDetailControllerWithData:aModel];
}

- (void)pushPlayDetailControllerWithData:(ChannelModel *)aModel
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Show"
                                          label:[NSString stringWithFormat:@"%@/ShowId-%@/ShowTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mChannelDataModel = aModel;
    aPlayListDetailViewController.isFromGenre = YES;
    aPlayListDetailViewController.isFromProvider = YES;
    aPlayListDetailViewController.mProviderModal = self.mProviderModel;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

#pragma mark
#pragma mark UICollectionViewDelegateFlowLayout

#pragma mark
#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;

    ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];

    CGRect labelRect = [aModel.showDescription
        boundingRectWithSize:CGSizeMake(collectionView.frame.size.width - 24, 60)
                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                  attributes:@{
                      NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:14.0]
                  }
                     context:nil];

    float CellImageDiff = 24.0;
    float aLabelHeight = labelRect.size.height > 20 ? (labelRect.size.height > 39 ? 57 : 38) : 19;
    float height = (((collectionView.frame.size.width - CellImageDiff) / 2.0) * 1.0) + 20 + 12 + 12 + aLabelHeight + 60 - 14;

    size = CGSizeMake(collectionView.frame.size.width, height);
    return size;
}
//

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getSessionTokenFromServer
{
    __weak ProviderDetailViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
                                                                     WithresponseBlock:^(NSDictionary *responseDict) {
                                                                       [weakSelf getDataFromServerForPlayList];

                                                                     }
                                                                            errorBlock:^(NSError *error){

                                                                            }];
}

- (void)getDataFromServerForPlayList
{
    __weak ProviderDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [self userInteractionEnableForViewElement:NO];
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetChannelForPublisherresponseBlock:^(NSArray *responseArray) {

      __block NSArray *array = responseArray;

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@"updateDataSource");
        [self userInteractionEnableForViewElement:YES];
        [weakSelf.refreshControl endRefreshing];
        [weakSelf updateDataSource:array];

      }];

      [self getFollowStatusForChannelList:array];

    }
        errorBlock:^(NSError *error) {

          [self userInteractionEnableForViewElement:YES];
          [weakSelf.refreshControl endRefreshing];

          [weakSelf performSelectorOnMainThread:@selector(errorInGetDataFromServerForPlayList:) withObject:error waitUntilDone:NO];

        }
        forAPiFormat:self.publisherApiFormat];
}

- (void)userInteractionEnableForViewElement:(BOOL)isEnable
{
    if (isEnable)
    {
        self.isrefreshing = NO;
    }
    self.mCollectionView.userInteractionEnabled = isEnable;
}

- (void)errorInGetDataFromServerForPlayList:(NSError *)error
{
    __weak ProviderDetailViewController *weakSelf = self;
    [weakSelf.refreshControl endRefreshing];
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getDataFromServerForPlayList) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataFromServerForPlayList) withInputParameters:nil];
    }
}

- (void)updateDataSource:(NSArray *)aArray
{
    [self.mPlayListDataSource removeAllObjects];
    [self.mPlayListDataSource addObjectsFromArray:aArray];
    [self.mCollectionView reloadData];
}

- (void)postFeedFollowSwerveEvent:(NSString *)eventName andChannel:(ChannelModel *)aModel
{
    NSDictionary *payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:nil
                                                                        assetId:nil
                                                                   channleTitle:(aModel) ? aModel.title : nil
                                                                      channleId:(aModel) ? aModel.uniqueId : nil
                                                                     genreTitle:nil
                                                                        genreId:nil
                                                                 publisherTitle:self.mProviderModel.title
                                                                    publisherId:self.mProviderModel.uniqueId
                                                                  playlistTitle:nil
                                                                     playlistId:nil];

    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}

- (IBAction)onClickingFollowButton:(CustomIndexButton *)sender
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvefeedCannotFollowNotLoggedIn];
        [kSharedApplicationDelegate showLoginSignInScreenForGuestUserOnClickingFollow];
        return;
    }

    __weak ProviderDetailViewController *weakSelf = self;

    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    GenreCollectionViewCell *aCell = (GenreCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:sender.mIndexPath];

    ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:sender.mIndexPath.row];

    if (!sender.selected && !aModel.isChannelFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Follow"
                                              label:[NSString stringWithFormat:@"%@/ShowId-%@/ShowTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                           andValue:nil];

        [[ServerConnectionSingleton sharedInstance] sendrequestToSubscribeChannel:aModel.uniqueId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedFollowSwerveEvent:kSwrvefeedFollow andChannel:aModel];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    aCell.mFollowButtonWidthConstraint.constant = 91.0;
                    aModel.isChannelFollowing = YES;
                    sender.selected = YES;

                    [weakSelf postNotificationForFollowChannelId:aModel.uniqueId withFollowStatus:YES];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction eventName:kEventNameFollow playListId:nil channelId:aModel.uniqueId andAssetId:nil andFromPlaylistPage:NO];

                  }];
              }

            }
            errorBlock:^(NSError *error) {

              [weakSelf performSelectorOnMainThread:@selector(onFollowUnFollowStatusFailure:) withObject:error waitUntilDone:NO];
            }];
    }
    else if (sender.selected && aModel.isChannelFollowing)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"UnFollow"
                                              label:[NSString stringWithFormat:@"%@/ShowId-%@/ShowTitle-%@", [self getTrackpath], aModel.uniqueId, aModel.title]
                                           andValue:nil];
        [[ServerConnectionSingleton sharedInstance] sendrequestToUnSubscribeChannel:aModel.uniqueId
            withResponseBlock:^(BOOL success) {

              if (success)
              {
                  [self postFeedFollowSwerveEvent:kSwrvefeedUnfollow andChannel:aModel];

                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    aCell.mFollowButtonWidthConstraint.constant = 70.0;
                    aModel.isChannelFollowing = NO;
                    sender.selected = NO;
                    [weakSelf postNotificationForFollowChannelId:aModel.uniqueId withFollowStatus:NO];
                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction eventName:kEventNameUnFollow playListId:nil channelId:aModel.uniqueId andAssetId:nil andFromPlaylistPage:NO];
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
    __weak ProviderDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
}

#pragma mark Scrollview Delegate Method
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}

#pragma mark Guest User Login

- (void)addNotificationForFollowStatusWhenGusetUserLogin
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchChannelSubscriptionWhenGuestLogin) name:@"fetchChannelSubscriptionWhenGuestLogin" object:nil];
    }
}

- (void)fetchChannelSubscriptionWhenGuestLogin
{
    [self getFollowStatusForChannelList:self.mPlayListDataSource];
}

- (void)getFollowStatusForChannelList:(NSArray *)array
{
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        __weak ProviderDetailViewController *weakSelf = self;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

          __block ChannelModel *aChannelModel = (ChannelModel *)obj;
          [[ServerConnectionSingleton sharedInstance] sendrequestToGetSubscriptionStatusForChannel:aChannelModel.uniqueId
              withResponseBlock:^(BOOL success) {

                aChannelModel.isChannelFollowing = success;

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                  for (NSIndexPath *aIndexPath in [weakSelf.mCollectionView indexPathsForVisibleItems])
                  {
                      ChannelModel *channelModel = [weakSelf.mPlayListDataSource objectAtIndex:aIndexPath.item];
                      if ([channelModel.uniqueId isEqualToString:aChannelModel.uniqueId])
                      {
                          GenreCollectionViewCell *cell = (GenreCollectionViewCell *)[weakSelf.mCollectionView
                              cellForItemAtIndexPath:aIndexPath];

                          cell.mFollowButton.selected = channelModel.isChannelFollowing;

                          if (cell.mFollowButton.selected)
                          {
                              cell.mFollowButtonWidthConstraint.constant = 91.0;
                          }
                          else
                          {
                              cell.mFollowButtonWidthConstraint.constant = 70.0;
                          }
                          break;
                      }
                  }
                }];

              }
              errorBlock:^(NSError *error) {
                NSLog(@"error in fetching follow status for channel id %@", aChannelModel.uniqueId);
              }];

        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshControl endRefreshing];
    self.mCollectionView.delegate = nil;
    self.mCollectionView.dataSource = nil;
    self.mPlayListDataSource = nil;
    self.refreshControl = nil;
}

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    NSString *strToView = @"";
    strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"ProviderDetails/ProviderId-%@/ProviderTitle-%@", self.mProviderModel.uniqueId, self.mProviderModel.title]];

    return strToView;
}

@end
