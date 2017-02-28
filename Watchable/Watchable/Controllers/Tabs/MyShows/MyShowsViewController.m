//
//  MyShowsViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "MyShowsViewController.h"
#import "SettingsViewController.h"
#import "HistoryViewController.h"
#import "MyShowsCustomCell.h"
#import "ServerConnectionSingleton.h"
#import "ShowModel.h"
#import "ImageURIBuilder.h"
#import "ImageCacheSingleton.h"
#import "UIImageView+WebCache.h"
#import "ChannelModel.h"
#import "PlayDetailViewController.h"
#import "UIColor+HexColor.h"
#import "AppDelegate.h"
#import "GAUtilities.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Watchable-Swift.h"

#define kPlayButtonTag 11111
@interface MyShowsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *mMyShowTableView;
@property (nonatomic, strong) NSMutableArray *mMyShowDataSource;
@property (nonatomic, assign) BOOL isPageNeedRefresh;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *mEmptyDataErrorView;
@property (nonatomic) BOOL isrefreshing;
@property (nonatomic, strong) SignUpLoginOverLayView *mSignUpLoginOverLayView;

@end

@implementation MyShowsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initialSetUp];

    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [self getMyShowsListFromServer];
    }
    else
    {
        [self addSignupLoginOverLay];
    }
    [self addNotificationForFollowChannel];

    [Utilities setAppBackgroundcolorForView:self.mMyShowTableView];
    [Utilities setAppBackgroundcolorForView:self.view];

    //Guest User Login Notification Registeration

    [self addNotificationToReloadMyShowsDataWhenGuestLogIn];
}

- (void)addSignupLoginOverLay
{
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"SignUpLoginOverLayView"
                                                         owner:self
                                                       options:nil];
    //I'm assuming here that your nib's top level contains only the view
    //you want, so it's the only item in the array.
    SignUpLoginOverLayView *myView = (SignUpLoginOverLayView *)[nibContents objectAtIndex:0];
    self.mSignUpLoginOverLayView = myView;
    self.mSignUpLoginOverLayView.frame = self.view.bounds;
    self.mSignUpLoginOverLayView.isPresentedFromMyShows = YES;
    self.mSignUpLoginOverLayView.isPresentedInLandScape = NO;
    self.mSignUpLoginOverLayView.mLoginBtnPortaritBottomSpace.constant = 35;
    [self.mSignUpLoginOverLayView addUIElements];
    [self.view addSubview:self.mSignUpLoginOverLayView];
}

- (void)removeSignupLoginOverLay
{
    if (self.mSignUpLoginOverLayView)
    {
        [self.mSignUpLoginOverLayView removeFromSuperview];
        self.mSignUpLoginOverLayView = nil;
    }
}
- (void)addNotificationForFollowChannel
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationStatusForFollow:) name:@"NotificationForFollowChannel" object:nil];
}

- (void)notificationStatusForFollow:(NSNotification *)aNotification
{
    //    NSDictionary *userInfo = aNotification.userInfo;
    //    NSString *aChannelId = [userInfo objectForKey:@"channelId"];
    //
    //    BOOL followStatus= [((NSNumber*)[userInfo objectForKey:@"followStatus"])boolValue];

    self.isPageNeedRefresh = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [GAUtilities setWatchbaleScreenName:@"MyShowsScreen"];
    }

    if (self.isPageNeedRefresh)
    {
        [self updateDataSource:self.mMyShowDataSource];
        [self getMyShowsListFromServer];
    }
    if (self.isrefreshing)
    {
        self.mMyShowTableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height - 30);
        [self.refreshControl beginRefreshing];
    }
    // [self getMyShowsListFromServer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];

    [self.refreshControl endRefreshing];
}

- (void)initialSetUp
{
    [self createNavBarWithHidden:NO];
    [self setSettingsHistoryButtonOnNavBar];
    [self setNavigationBarTitle:kNavTitleMyShows withFont:nil withTextColor:nil];
    self.mMyShowTableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);
    self.mMyShowDataSource = [[NSMutableArray alloc] init];

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadDataFromServer)
                  forControlEvents:UIControlEventValueChanged];
    [self.mMyShowTableView addSubview:self.refreshControl];
    [[self.refreshControl.subviews objectAtIndex:0] setFrame:CGRectMake(0, 20, self.refreshControl.frame.size.width, self.refreshControl.frame.size.height)];
}

- (void)reloadDataFromServer
{
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [self getMyShowsListFromServer];
        self.isrefreshing = YES;
    }
    else
    {
        [self.refreshControl endRefreshing];
        self.isrefreshing = NO;
    }
}
#pragma mark
#pragma mark Server Call-Fetch Myshow List
- (void)getMyShowsListFromServer
{
    __weak MyShowsViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    self.mMyShowTableView.userInteractionEnabled = NO;
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetMyShowListresponseBlock:^(NSArray *responseArray) {
      weakSelf.mMyShowTableView.userInteractionEnabled = YES;
      self.isrefreshing = NO;

      __block NSArray *array = responseArray;
      [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        ChannelModel *aChannelModel = (ChannelModel *)obj;
        aChannelModel.isChannelFollowing = YES;

      }];

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf.refreshControl endRefreshing];
        weakSelf.isPageNeedRefresh = NO;
        //[weakSelf performSelector:@selector(updateDataSource:) withObject:array afterDelay:1.0];
        [weakSelf updateDataSource:array];
      }];

    }
        errorBlock:^(NSError *error) {

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            self.isrefreshing = NO;
            [weakSelf.refreshControl endRefreshing];
            weakSelf.mMyShowTableView.userInteractionEnabled = YES;
            [weakSelf onGetMyShowsListRequestFailureWithError:error];
          }];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)onGetMyShowsListRequestFailureWithError:(NSError *)error
{
    __weak MyShowsViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:(self.mMyShowDataSource.count > 0) ? InternetFailureWithTryAgainMessage : InternetFailureInLandingScreenTryAgainButton withTryAgainSelector:@selector(getMyShowsListFromServer) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getMyShowsListFromServer) withInputParameters:nil];
    }
}

- (void)updateDataSource:(NSArray *)aArray
{
    if (aArray.count)
    {
        [self.mMyShowDataSource removeAllObjects];
        [self removeDataUnAvailableView];
        // remove no content found
        [self.mMyShowDataSource addObjectsFromArray:aArray];
    }
    else
    {
        [self.mMyShowDataSource removeAllObjects];
        if (!aArray.count)
        {
            //added no content found
            [self addDataUnAvailableView];
        }
    }

    if (isCoreSpotLightEnable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setMyShowsItemIdexedBeforeReload:aArray];
        });
    }

    [self.mMyShowTableView reloadData];
}

#pragma mark - Corespotlight Methods

- (void)setMyShowsItemIdexedBeforeReload:(NSArray *)array
{
    for (ChannelModel *cModel in array)
    {
        [self setSearchableItem:cModel withImage:nil];
    }
}

- (void)setSearchableItem:(ChannelModel *)model withImage:(UIImage *)image
{
    ChannelModel *cModel = model;

    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeImage];
    if (image != nil)
    {
        NSData *dataImg = UIImagePNGRepresentation(image);
        attributeSet.thumbnailData = dataImg;
    }
    attributeSet.title = cModel.title;
    attributeSet.contentDescription = cModel.showDescription;
    attributeSet.keywords = @[ cModel.title ];

    NSString *strId = [NSString stringWithFormat:@"%@,%@", kDeepLinkShowIdKey, cModel.uniqueId];

    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:strId domainIdentifier:@"com.wtchable" attributeSet:attributeSet];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ]
                                                   completionHandler:^(NSError *_Nullable error) {
                                                     if (!error)
                                                         NSLog(@"MyShows item indexed");
                                                   }];
}

- (void)deleteMyshowsItem:(ChannelModel *)aModel withImage:(UIImage *)image
{
    NSString *strId = [NSString stringWithFormat:@"%@,%@", kDeepLinkShowIdKey, aModel.uniqueId];
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[ strId ]
                                                                   completionHandler:^(NSError *_Nullable error) {
                                                                     [self setSearchableItem:aModel withImage:image];
                                                                   }];
}

- (void)addDataUnAvailableView
{
    if (!self.mEmptyDataErrorView)
    {
        UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height)];

        [Utilities setAppBackgroundcolorForView:aView];
        // aView.backgroundColor=[UIColor whiteColor];
        self.mEmptyDataErrorView = aView;

        UIImage *aImage = [UIImage imageNamed:@"myshows_icons.png"];
        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, aView.frame.size.width, aImage.size.height)];
        aImageView.image = aImage;
        [self.mEmptyDataErrorView addSubview:aImageView];

        float aDescFontSize = 16.0;
        float aBtnReferDistance = 50.0;
        float aDescLableYAxysDelta = 42;

        float deviceScreenHeight = [[UIScreen mainScreen] bounds].size.height;

        if (deviceScreenHeight <= 480.0)
        {
            aDescFontSize = 14.0;
            aBtnReferDistance = 30.0;
            aDescLableYAxysDelta = 32.0;
        }
        else if (deviceScreenHeight <= 568.0)
        {
            aDescFontSize = 15.0;
            aBtnReferDistance = 40.0;
            aDescLableYAxysDelta = 40.0;
        }

        NSString *aDescStr = @"Watchable collects the best of the web so you don't have to. And you can save it all here.\n\nWhen you follow shows, they're added here so you can watch your favorite moments anytime.\n\nReady to get started? So are we.";
        UILabel *aDescLbl = [[UILabel alloc] initWithFrame:CGRectMake(47, aImageView.frame.size.height + aImageView.frame.origin.y + aDescLableYAxysDelta, self.view.frame.size.width - (2 * 47), 300)];
        aDescLbl.numberOfLines = 15;
        aDescLbl.font = [UIFont fontWithName:@"AvenirNext-Regular" size:aDescFontSize];
        aDescLbl.textColor = [UIColor colorFromHexString:@"#D2D2D2"];
        aDescLbl.text = aDescStr;
        [aDescLbl sizeToFit];

        [self.mEmptyDataErrorView addSubview:aDescLbl];

        UIButton *aBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        aBtn.frame = CGRectMake(47, self.mEmptyDataErrorView.frame.size.height - 44 - 35 - 64, self.view.frame.size.width - (2 * 47), 44);
        aBtn.layer.cornerRadius = 4.0;
        aBtn.layer.masksToBounds = YES;
        aBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:aDescFontSize];
        [aBtn setTitle:@"Find shows to follow" forState:UIControlStateNormal];
        [aBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [aBtn setBackgroundColor:[UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0]];
        [aBtn addTarget:self action:@selector(onClickingShowToFollowBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.mEmptyDataErrorView addSubview:aBtn];
        //        self.mEmptyDataErrorView = [[EmptyDataErrorView alloc]initWithFrame:CGRectMake(0, 34, self.mMyShowTableView.frame.size.width, self.mMyShowTableView.frame.size.height-64) withErrorMsg:@"You are not following any shows yet."];
    }
    [self.view addSubview:self.mEmptyDataErrorView];
}

- (void)removeDataUnAvailableView
{
    if (self.mEmptyDataErrorView)
    {
        [self.mEmptyDataErrorView removeFromSuperview];
        self.mEmptyDataErrorView = nil;
    }
}

- (void)onClickingShowToFollowBtn
{
    AppDelegate *aDelegate = (AppDelegate *)kSharedApplicationDelegate;
    [aDelegate setTabbarTabToBrowseTab];
}

//#pragma mark Download Image Method

#pragma mark
#pragma mark Button Action

- (void)onClickingCellPlayButton:(UITapGestureRecognizer *)aSender
{
    UIView *aView = aSender.view;
    CustomIndexImageView *aPlayImageView = (CustomIndexImageView *)[aView viewWithTag:kPlayButtonTag];

    NSLog(@"clicked button indexpath=%ld", (long)aPlayImageView.mIndexPath.row);
    [self pushChannelDetailControllerWithData:(ChannelModel *)[self.mMyShowDataSource objectAtIndex:aPlayImageView.mIndexPath.row] withPlayLatestVideo:YES];
}

- (void)onClickingSettingsButton
{
    [self pushSettingsViewController];
}

- (void)onClickingHistoryButton
{
    [self pushHistoryViewController];
}

#pragma mark
#pragma mark Navigate-Settings&History
- (void)pushSettingsViewController
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Settings"
                                          label:[self getTrackpath]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    SettingsViewController *aSettingsViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    [self.navigationController pushViewController:aSettingsViewController animated:YES];
}

- (void)pushHistoryViewController
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on History"
                                          label:[self getTrackpath]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    HistoryViewController *aHistoryViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"HistoryViewController"];
    [self.navigationController pushViewController:aHistoryViewController animated:YES];
}

- (void)pushChannelDetailControllerWithData:(ChannelModel *)aModel withPlayLatestVideo:(BOOL)isPlayLatestVideo
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:isPlayLatestVideo ? @"Taps on Latest Video" : @"Taps on Show"
                                          label:[NSString stringWithFormat:@"%@/%@", [self getTrackpath], [self getPathStringForSelectedChannel:aModel playButtonTapped:isPlayLatestVideo]]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mChannelDataModel = aModel;
    aPlayListDetailViewController.isFromGenre = YES;
    aPlayListDetailViewController.isFromShowBottomPlayDetailScreen = YES;
    aPlayListDetailViewController.isPlayLatestVideo = isPlayLatestVideo;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

#pragma mark
#pragma mark UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mMyShowDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyShowsCustomCell *cell = (MyShowsCustomCell *)[tableView dequeueReusableCellWithIdentifier:@"MyShowsCustomCell"];

    cell.mShowImageView.layer.cornerRadius = 1.0;
    cell.mShowImageView.layer.masksToBounds = YES;
    cell.mPlayImageView.tag = kPlayButtonTag;
    cell.mPlayImageView.userInteractionEnabled = YES;
    cell.mPlayImageView.mIndexPath = indexPath;

    for (UIGestureRecognizer *recognizer in cell.mPlayButtonBGView.gestureRecognizers)
    {
        [cell.mPlayButtonBGView removeGestureRecognizer:recognizer];
    }

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickingCellPlayButton:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [cell.mPlayButtonBGView addGestureRecognizer:tapRecognizer];

    ChannelModel *aModel = [self.mMyShowDataSource objectAtIndex:indexPath.row];
    cell.mShowDescriptionLabel.text = @"";

    if (!aModel.nextVideoUnderchannel)
    {
        [self getNextVideoForChannel:aModel andCell:cell atIndex:indexPath.row];
    }
    else if (aModel.nextVideoUnderchannel.shortDescription)
    {
        cell.mShowDescriptionLabel.text = aModel.nextVideoUnderchannel.shortDescription;
    }

    cell.mShowTitleLabel.text = kWatchLatestEpisode;

    float aWidth = self.view.frame.size.width - (2 * 12);
    float aHeight = aWidth / 2.0;
    NSString *imageUrlString = [ImageURIBuilder buildImageUrlWithString:aModel.imageUri ForImageType:Two2One_logo withSize:CGSizeMake(aWidth, aHeight)];

    if (imageUrlString)
    {
        [cell.mShowImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                               placeholderImage:[UIImage imageNamed:@"logoEmptyState.png"]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {

                                        if (isCoreSpotLightEnable)
                                        {
                                            [self deleteMyshowsItem:aModel withImage:image];
                                        }
                                      }];
    }
    else
    {
        cell.mShowImageView.image = [UIImage imageNamed:@"logoEmptyState.png"];
    }

    [cell.contentView sendSubviewToBack:cell.mShowImageView];

    return cell;
}

#pragma mark NextVideo Under Channel

- (void)getNextVideoForChannel:(ChannelModel *)channel andCell:(MyShowsCustomCell *)cell atIndex:(NSUInteger)index
{
    NSLog(@"getNextVideoForChannel channel id=%@", channel.uniqueId);
    __weak MyShowsViewController *weakSelf = self;

    if (channel.nextVideoUnderchannel == nil)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetNextVideoForChannelId:channel.uniqueId
            responseBlock:^(VideoModel *videoModal) {

              NSLog(@"index=%ld,vedio id=%@", index, videoModal.uniqueId);
              NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", channel.uniqueId];

              NSArray *aChannelArray = [weakSelf.mMyShowDataSource filteredArrayUsingPredicate:aPredicate];

              for (ChannelModel *aChannel in aChannelArray)
              {
                  aChannel.nextVideoUnderchannel = videoModal;
              }
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                NSArray *aArray = [weakSelf.mMyShowTableView indexPathsForVisibleRows];
                for (NSIndexPath *aIndexPath in aArray)
                {
                    ChannelModel *aChannelModel = (ChannelModel *)[weakSelf.mMyShowDataSource objectAtIndex:aIndexPath.row];
                    if ([aChannelModel.uniqueId isEqualToString:channel.uniqueId])
                    {
                        MyShowsCustomCell *aCell = (MyShowsCustomCell *)[weakSelf.mMyShowTableView cellForRowAtIndexPath:aIndexPath];
                        aCell.mShowDescriptionLabel.text = videoModal.shortDescription;
                    }
                }
                //                NSLog(@"index=%ld,vedio id=%@",index,videoModal.uniqueId);
                //                ((ChannelModel*)[weakSelf.mMyShowDataSource objectAtIndex:index]).nextVideoUnderchannel = videoModal;
                //                cell.mShowDescriptionLabel.text=videoModal.shortDescription;

              }];

            }
            errorBlock:^(NSError *error) {

              NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);

            }];
    }
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected cell index=%ld", (long)indexPath.row);
    [self pushChannelDetailControllerWithData:(ChannelModel *)[self.mMyShowDataSource objectAtIndex:indexPath.row] withPlayLatestVideo:NO];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float aWidth = self.view.frame.size.width - (2 * 12);
    float cellHeight = 150.0 + (aWidth / 2.0);
    return cellHeight;
}

/*
 - (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 
 [self.mMyShowDataSource removeObjectAtIndex:[indexPath row]];
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 }
 */

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
    {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark

#pragma mark Scrollview Delegate Method
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
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

    [self.refreshControl endRefreshing];
    self.mMyShowTableView.delegate = nil;
    self.mMyShowTableView.dataSource = nil;
    self.mMyShowDataSource = nil;
}

#pragma mark Guest User Methods

- (void)addNotificationToReloadMyShowsDataWhenGuestLogIn
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNotificationToReloadMyShowsDataWhenGuestLogIn) name:@"fetchChannelSubscriptionWhenGuestLogin" object:nil];
        [self registerNotificationWhenGuestUserSignsIn];
    }
}

- (void)getNotificationToReloadMyShowsDataWhenGuestLogIn
{
    [self removeSignupLoginOverLay];
    [self getMyShowsListFromServer];
}

- (void)registerNotificationWhenGuestUserSignsIn
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshUserInterfaceWhenGuestLogIn) name:@"refreshUserInterfaceWhenGuestLogIn" object:nil];
}

- (void)refreshUserInterfaceWhenGuestLogIn
{
    [self removeSignupLoginOverLay];
    [self addDataUnAvailableView];
}

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    NSString *strToView = @"";
    strToView = @"MyshowsTab";
    return strToView;
}

- (NSString *)getPathStringForSelectedChannel:(ChannelModel *)channelModel playButtonTapped:(BOOL)isPlayButtonTapped
{
    NSString *str = @"";
    if (isPlayButtonTapped)
    {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"ShowId-%@/ShowTitle-%@/VideoId-%@/VideoTitle-%@", channelModel.uniqueId, channelModel.title, channelModel.nextVideoUnderchannel.uniqueId, channelModel.nextVideoUnderchannel.title]];
    }
    else
    {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"ShowId-%@/ShowTitle-%@", channelModel.uniqueId, channelModel.title]];
    }

    return str;
}

@end
