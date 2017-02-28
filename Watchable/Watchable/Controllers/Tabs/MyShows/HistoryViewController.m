//
//  HistoryViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "HistoryViewController.h"
#import "HistoryCustomCell.h"
#import "ShowModel.h"
#import "ImageURIBuilder.h"
#import "UIImageView+WebCache.h"
#import "ServerConnectionSingleton.h"
#import "HistoryModel.h"
#import "VideoModel.h"
#import "PlayDetailViewController.h"
#import "DBHandler.h"
#import "ChannelModel.h"
#import "SwrveUtility.h"
#import "GAUtilities.h"

@interface HistoryViewController ()
@property (weak, nonatomic) IBOutlet UITableView *mHistoryTableView;
@property (nonatomic, strong) NSMutableArray *mHistoryDataSource;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableArray *mVideoIdListFetchingFromServer;
@property (nonatomic, assign) BOOL isNewHistoryAssetInsertedInDB;
@property (nonatomic, strong) NSMutableArray *mChannelIDForFetchingChannelLogoArray;
@property (nonatomic) BOOL isrefreshing;
@end

@implementation HistoryViewController

- (void)addNotificationForUpdateHistoryDataFromDB
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newHistoryAssetsAddedToDB:) name:kUpdatedHistoryAssetInCoreDataNotification object:nil];
}

- (void)newHistoryAssetsAddedToDB:(id)sender
{
    self.isNewHistoryAssetInsertedInDB = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addNotificationForUpdateHistoryDataFromDB];
    self.mClearAllBGViewHeightConstraint.constant = 0.0;
    [self.mClearAllButton setTitle:@"" forState:UIControlStateNormal];
    // Do any additional setup after loading the view.
    [self initialSetUp];
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [self getHistoryDataFromServer];
    }

    [Utilities setAppBackgroundcolorForView:self.view];
    [Utilities setAppBackgroundcolorForView:self.mHistoryTableView];
    [self addNotificationToReloadHistoryDataWhenGuestLogIn];
}

- (void)getHistoryDataFromServer
{
    if (!((AppDelegate *)kSharedApplicationDelegate).isHistoryScreenLanched)
    {
        NSArray *aHistoryModelArray = [[DBHandler sharedInstance] getAllHistoryModelsForLoggedInUser];
        if (aHistoryModelArray.count)
        {
            NSTimeInterval aTimeDifference = [self timeDifferenceFromLastHistoryTime];
            if (aTimeDifference > kHistoryUpdateDataFetchInterval)
            {
                [self getMyHistoryUpdatesFromServerWithLastUpdatedTime:aTimeDifference];
            }
            else
            {
                ((AppDelegate *)kSharedApplicationDelegate).isHistoryScreenLanched = YES;
                [self updateDataSource:aHistoryModelArray];
            }
        }
        else
        {
            [self getMyHistoryListFromServer];
        }
    }
    else
    {
        NSArray *aHistoryModelArray = [[DBHandler sharedInstance] getAllHistoryModelsForLoggedInUser];
        if (aHistoryModelArray.count)
        {
            [self updateDataSource:aHistoryModelArray];
        }
        else
        {
            [self getMyHistoryListFromServer];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [GAUtilities setWatchbaleScreenName:@"HistoryScreen"];
    }
    if (self.isNewHistoryAssetInsertedInDB)
    {
        __weak HistoryViewController *weakSelf = self;
        weakSelf.isNewHistoryAssetInsertedInDB = NO;
        NSArray *aHistoryModelArray = [[DBHandler sharedInstance] getAllHistoryModelsForLoggedInUser];
        [weakSelf updateDataSource:aHistoryModelArray];
    }

    if (self.isrefreshing)
    {
        self.mHistoryTableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height - 30);
        [self.refreshControl beginRefreshing];
    }

    // [self getMyShowsListFromServer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.refreshControl endRefreshing];
}

- (NSTimeInterval)timeDifferenceFromLastHistoryTime
{
    NSDate *aLastSyncedDate = [[DBHandler sharedInstance] getLastHistorySyncedDate];
    NSDate *aCurrentDate = [NSDate date];
    NSTimeInterval aTimeDifference = [aCurrentDate timeIntervalSinceDate:aLastSyncedDate];

    return aTimeDifference;
}

- (void)initialSetUp
{
    [self createNavBarWithHidden:NO];
    [self setBackButtonOnNavBar];
    [self setDeleteHistoryButtonOnNavBar];
    [self setNavigationBarTitle:kNavTitleHistory withFont:nil withTextColor:nil];
    self.mVideoIdListFetchingFromServer = [[NSMutableArray alloc] init];
    self.mHistoryTableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);

    self.mHistoryDataSource = [[NSMutableArray alloc] init];
    self.mChannelIDForFetchingChannelLogoArray = [[NSMutableArray alloc] init];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadDataFromServer)
                  forControlEvents:UIControlEventValueChanged];
    [self.mHistoryTableView addSubview:self.refreshControl];
    [[self.refreshControl.subviews objectAtIndex:0] setFrame:CGRectMake(0, 20, self.refreshControl.frame.size.width, self.refreshControl.frame.size.height)];
}

- (void)reloadDataFromServer
{
    if (!((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        __weak HistoryViewController *weakSelf = self;
        if (self.mErrorView)
            [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

        if ([[DBHandler sharedInstance] canRefreshHistory] || self.mHistoryDataSource.count == 0)
        {
            self.isrefreshing = YES;
            [self getMyHistoryListFromServer];
        }
        else
        {
            self.isrefreshing = NO;
            [self.refreshControl endRefreshing];
        }
    }
    else
    {
        [self.refreshControl endRefreshing];
        self.isrefreshing = NO;
    }
}

- (void)getMyHistoryUpdatesFromServerWithLastUpdatedTime:(NSTimeInterval)aDifferenceTime
{
    //Delta sync service
    //on successfull response make
    //((AppDelegate*)kSharedApplicationDelegate).isHistoryScreenLanched=YES;
    [self getMyHistoryListFromServer];
}
#pragma mark
#pragma mark Server Call-Fetch Myshow List
- (void)getMyHistoryListFromServer
{
    __weak HistoryViewController *weakSelf = self;
    [weakSelf userInteractionEnableForViewElement:NO];
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetMyHistoryListresponseBlock:^(NSArray *responseArray) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf userInteractionEnableForViewElement:YES];
        [weakSelf.refreshControl endRefreshing];
        [weakSelf updateDataSource:responseArray];
        ((AppDelegate *)kSharedApplicationDelegate).isHistoryScreenLanched = YES;
      }];

    }
        errorBlock:^(NSError *error) {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakSelf userInteractionEnableForViewElement:YES];
            [weakSelf.refreshControl endRefreshing];
            [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:error.code == kErrorCodeNotReachable ? InternetFailureWithTryAgainButton : ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getMyHistoryListFromServer) withInputParameters:nil];
          }];
          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)userInteractionEnableForViewElement:(BOOL)isEnable
{
    if (isEnable)
    {
        self.mHistoryTableView.userInteractionEnabled = YES;
        self.mClearAllButton.userInteractionEnabled = YES;
        //[self enableDeleteHistoryButton:YES];
        self.isrefreshing = NO;
    }
    else
    {
        self.mHistoryTableView.userInteractionEnabled = NO;
        self.mClearAllButton.userInteractionEnabled = NO;
        //[self enableDeleteHistoryButton:NO];
    }
}

- (void)updateDataSource:(NSArray *)aArray
{
    [self.mHistoryDataSource removeAllObjects];

    [self.mHistoryDataSource addObjectsFromArray:aArray];
    [self.mHistoryTableView reloadData];
}

- (void)getVideoInfoForVideoId:(NSString *)aVideoId withIndexPath:(NSIndexPath *)aIndexPath
{
    // kURLGetVideoInfo

    __weak HistoryViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetVideoForVideoId:aVideoId
        responseBlock:^(VideoModel *videoModal) {

          //  NSArray *aArray=[weakSelf.mHistoryTableView indexPathsForVisibleRows];

          [weakSelf.mHistoryDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

            HistoryModel *aHistoryModel = (HistoryModel *)obj;
            if ([aHistoryModel.mVideoId isEqualToString:aVideoId])
            {
                aHistoryModel.mVideoModel = videoModal;

                NSIndexPath *aIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];

                HistoryCustomCell *aCell = (HistoryCustomCell *)[weakSelf.mHistoryTableView cellForRowAtIndexPath:aIndexPath];
                if (aCell)
                {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                      [weakSelf updateCellInfo:aCell withModel:aHistoryModel];
                    }];
                }

                *stop = YES;
            }

          }];

        }
        errorBlock:^(NSError *error) {

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}
- (void)onClickingHistoryDeleteButton:(UIButton *)aSender
{
    aSender.selected = !aSender.selected;
    NSLog(@"onClickingHistoryDeleteButton");
    if (aSender.selected)
    {
        self.mClearAllBGViewHeightConstraint.constant = 60.0;
        [self.mClearAllButton setTitle:@"Clear all" forState:UIControlStateNormal];
        self.mHistoryTableView.contentInset = UIEdgeInsetsMake(24 + 64, 0, 0, 0);
    }
    else
    {
        self.mClearAllBGViewHeightConstraint.constant = 0.0;
        self.mHistoryTableView.contentInset = UIEdgeInsetsMake(24, 0, 0, 0);
        [self.mClearAllButton setTitle:@"" forState:UIControlStateNormal];
    }
}

- (void)deleteVideoIdFromMyHistory:(NSString *)videoId forIndexPath:(NSIndexPath *)aIndexPath
{
    [self userInteractionEnableForViewElement:NO];
    __weak HistoryViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
    [[ServerConnectionSingleton sharedInstance] sendRequestToDeleteMyHistoryVideoId:videoId
        responseBlock:^(NSDictionary *responseDict) {

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            HistoryModel *aHistoryModel = [weakSelf.mHistoryDataSource objectAtIndex:aIndexPath.row];
            if ([aHistoryModel.mVideoId isEqualToString:videoId])
            {
                [[DBHandler sharedInstance] deleteHistoryAssestForId:aHistoryModel.mVideoId];
                [weakSelf.mHistoryDataSource removeObjectAtIndex:[aIndexPath row]];
                [weakSelf.mHistoryTableView beginUpdates];
                [weakSelf.mHistoryTableView deleteRowsAtIndexPaths:@[ aIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
                [weakSelf.mHistoryTableView endUpdates];
                [weakSelf userInteractionEnableForViewElement:YES];
            }

          }];

        }
        errorBlock:^(NSError *error) {
          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
          [weakSelf performSelectorOnMainThread:@selector(onFailureClearAllHistoryFromServer:) withObject:error waitUntilDone:NO];
        }];
}
- (IBAction)onClickingClearAllButton:(UIButton *)aSender
{
    __weak HistoryViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    if (self.mHistoryDataSource.count)
    {
        [self userInteractionEnableForViewElement:NO];

        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Taps on Clear All"
                                              label:[self getTrackpath]
                                           andValue:nil];

        [[ServerConnectionSingleton sharedInstance] sendRequestToDeleteMyHistoryListresponseBlock:^(NSDictionary *responseDict) {
          [weakSelf performSelectorOnMainThread:@selector(onSuccessfullClearAllHistoryFromServer) withObject:nil waitUntilDone:NO];
        }
            errorBlock:^(NSError *error) {
              NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
              [weakSelf performSelectorOnMainThread:@selector(onFailureClearAllHistoryFromServer:) withObject:error waitUntilDone:NO];
            }];
    }
}

- (void)onSuccessfullClearAllHistoryFromServer
{
    [[DBHandler sharedInstance] deleteAllHistoryAssestsForCurrentLoggedInUser];
    [self getDeleteButton].selected = NO;
    self.mClearAllBGViewHeightConstraint.constant = 0.0;
    self.mHistoryTableView.contentInset = UIEdgeInsetsMake(24, 0, 0, 0);
    [self.mClearAllButton setTitle:@"" forState:UIControlStateNormal];
    [self.mHistoryDataSource removeAllObjects];
    [self.mHistoryTableView reloadData];
    [self userInteractionEnableForViewElement:YES];
}

- (void)onFailureClearAllHistoryFromServer:(NSError *)error
{
    __weak HistoryViewController *weakSelf = self;

    [weakSelf userInteractionEnableForViewElement:YES];
    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:error.code == kErrorCodeNotReachable ? InternetFailureWithTryAgainMessage : ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
}

#pragma mark -
#pragma mark UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mHistoryDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HistoryCustomCell *cell = (HistoryCustomCell *)[tableView dequeueReusableCellWithIdentifier:@"HistoryCustomCell"];
    [self addTapGestureForChannelLogo:cell.mPublisherImageView];
    cell.mPublisherImageView.tag = indexPath.row;
    cell.mPublisherImageView.userInteractionEnabled = YES;
    cell.mPublisherImageView.backgroundColor = [UIColor clearColor];

    HistoryModel *aModel = [self.mHistoryDataSource objectAtIndex:indexPath.row];

    if (![self.mVideoIdListFetchingFromServer containsObject:aModel.mVideoId])
    {
        if (!(aModel.mVideoModel))
        {
            [self getVideoInfoForVideoId:aModel.mVideoId withIndexPath:indexPath];
        }
    }
    float aPubhlisherImageWidth = self.view.frame.size.width - (149.0 + 12.0);

    if (aPubhlisherImageWidth > 190)
        aPubhlisherImageWidth = 190.0;

    float aHeight = (aPubhlisherImageWidth * 22.0) / 190.0;

    cell.mPublisherLogoImageViewWidthConstraint.constant = aPubhlisherImageWidth;
    cell.mPublisherLogoImageHeightConstraint.constant = aHeight;

    [self updateCellInfo:cell withModel:aModel];

    return cell;
}

- (void)addTapGestureForChannelLogo:(UIImageView *)aImageView
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(channelLogoTapped:)];
    [aImageView addGestureRecognizer:tapGesture];
}

- (void)channelLogoTapped:(UITapGestureRecognizer *)aRecognizer
{
    UIImageView *imageView = (UIImageView *)aRecognizer.view;
    HistoryModel *aModel = [self.mHistoryDataSource objectAtIndex:imageView.tag];

    if (aModel)
    {
        if (aModel.mVideoModel)
        {
            [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                                 action:@"Taps on Show Logo"
                                                  label:[NSString stringWithFormat:@"%@/%@", [self getTrackpath], [self getPathStringForSelectedVideo:aModel channelLogoTapped:YES]]
                                               andValue:nil];
        }

        [self onSelectingLogoImageWithVideoModel:aModel.mVideoModel];
    }
}

- (void)onSelectingLogoImageWithVideoModel:(VideoModel *)aVideoModel
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mVideoModel = aVideoModel;
    aPlayListDetailViewController.isLogoClicked = YES;
    aPlayListDetailViewController.isFromSearch = YES;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

- (void)getChannelInfoForVideo:(VideoModel *)aVideoModel
{
    NSString *aChannelUrl = [aVideoModel.relatedLinks objectForKey:@"channel"];
    if (aChannelUrl.length)
    {
        [self.mChannelIDForFetchingChannelLogoArray addObject:aVideoModel.channelId];
        __weak HistoryViewController *weakSelf = self;
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
                        NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"mChannelId == %@", aVideoModel.channelId];

                        NSArray *aVideoModelArray = [weakSelf.mHistoryDataSource filteredArrayUsingPredicate:aPredicate];

                        [aVideoModelArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

                          __block HistoryModel *aHistoryModel = (HistoryModel *)obj;
                          aHistoryModel.mVideoModel.channelInfo = aChannelModel;

                        }];

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
    __weak HistoryViewController *weakSelf = self;
    NSArray *aVisibleCollectionViewIndexs = [weakSelf.mHistoryTableView indexPathsForVisibleRows];
    [aVisibleCollectionViewIndexs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      NSIndexPath *aIndexPath = (NSIndexPath *)obj;

      VideoModel *aVideoModel = ((HistoryModel *)[self.mHistoryDataSource objectAtIndex:aIndexPath.row]).mVideoModel;
      if ([aVideoModel.channelId isEqualToString:aChannelId])
      {
          __block HistoryCustomCell *aHistoryCustomCell = (HistoryCustomCell *)[weakSelf.mHistoryTableView cellForRowAtIndexPath:aIndexPath];

          NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:aVideoModel.channelInfo.imageUri ForImageType:Horizontal_lc_logo withSize:CGSizeMake(aHistoryCustomCell.mPublisherImageView.frame.size.width, aHistoryCustomCell.mPublisherImageView.frame.size.height)];
          aHistoryCustomCell.mPublisherImageView.contentMode = UIViewContentModeScaleAspectFit;
          [aHistoryCustomCell.mPublisherImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                                    placeholderImage:nil
                                                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                           }];
      }

    }];
}
- (void)updateCellInfo:(HistoryCustomCell *)cell withModel:(HistoryModel *)aModel
{
    cell.mDescriptionLabel.text = aModel.mVideoModel.shortDescription;

    NSDictionary *aRelativeLinksDict = aModel.mVideoModel.relatedLinks;
    NSString *aVideoImageUrl = [aRelativeLinksDict objectForKey:@"default-image"];
    cell.mShowImageView.image = nil;
    if (aVideoImageUrl.length)
    {
        NSString *showImageUrlString = [ImageURIBuilder buildURLWithString:aVideoImageUrl withSize:cell.mShowImageView.frame.size];

        if (showImageUrlString)
        {
            [cell.mShowImageView sd_setImageWithURL:[NSURL URLWithString:showImageUrlString]
                                   placeholderImage:nil
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                              //[cell.mActivityIndicator stopAnimating];
                                          }];
        }
        else
        {
            cell.mShowImageView.image = nil;
        }
    }

    cell.mPublisherImageView.image = nil;

    if (aModel.mVideoModel.channelInfo)
    {
        NSString *brandLogoURLString = aModel.mVideoModel.channelInfo.imageUri;
        if (brandLogoURLString)
        {
            NSString *providerImageUrlString = [ImageURIBuilder buildImageUrlWithString:brandLogoURLString ForImageType:Horizontal_lc_logo withSize:CGSizeMake(self.view.frame.size.width - 149 - 12, cell.mPublisherImageView.frame.size.height)];

            cell.mPublisherImageView.contentMode = UIViewContentModeScaleAspectFit;
            [cell.mPublisherImageView sd_setImageWithURL:[NSURL URLWithString:providerImageUrlString]
                                        placeholderImage:nil
                                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                               }];
        }
        else
        {
            cell.mPublisherImageView.image = nil;
        }
    }
    else
    {
        if (![self.mChannelIDForFetchingChannelLogoArray containsObject:aModel.mVideoModel.channelId])
        {
            [self getChannelInfoForVideo:aModel.mVideoModel];
        }
        cell.mPublisherImageView.image = nil;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        HistoryModel *aHistoryModel = [self.mHistoryDataSource objectAtIndex:indexPath.row];

        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Taps on Delete Video"
                                              label:[NSString stringWithFormat:@"%@/%@", [self getTrackpath], [self getPathStringForSelectedVideo:aHistoryModel channelLogoTapped:NO]]
                                           andValue:nil];

        [self deleteVideoIdFromMyHistory:aHistoryModel.mVideoId forIndexPath:indexPath];
    }
}

#pragma mark UITableView Delegate

- (void)postFeedFollowSwerveEvent:(NSString *)eventName andVideo:(VideoModel *)aModel
{
    NSDictionary *payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:aModel.title
                                                                        assetId:aModel.uniqueId
                                                                   channleTitle:aModel.channelTitle
                                                                      channleId:aModel.channelId
                                                                     genreTitle:nil
                                                                        genreId:nil
                                                                 publisherTitle:nil
                                                                    publisherId:nil
                                                                  playlistTitle:nil
                                                                     playlistId:nil];

    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected cell index=%ld", (long)indexPath.row);
    [self onSelectingVideoCellWithIndex:indexPath];
}

- (void)onSelectingVideoCellWithIndex:(NSIndexPath *)aIndexPath
{
    HistoryModel *aHistoryModel = [self.mHistoryDataSource objectAtIndex:aIndexPath.row];
    VideoModel *aVideoModel = aHistoryModel.mVideoModel;
    if (aVideoModel)
    {
        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Taps on Video"
                                              label:[NSString stringWithFormat:@"%@/%@", [self getTrackpath], [self getPathStringForSelectedVideo:aHistoryModel channelLogoTapped:NO]]
                                           andValue:nil];

        [self postFeedFollowSwerveEvent:kSwrveHistoryVideoView andVideo:aVideoModel];
        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

        PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
        aPlayListDetailViewController.mVideoModel = aVideoModel;
        aPlayListDetailViewController.isEpisodeClicked = YES;
        aPlayListDetailViewController.isPlayLatestVideo = YES;
        aPlayListDetailViewController.isFromSearch = YES;
        aPlayListDetailViewController.isFromHistoryScreen = YES;
        [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float cellHeight = 96.0;
    /*  float paddingHeight=0.0;
    NSLog(@"tableView.frame.size.width=%d",tableView.frame.size.width);
     HistoryModel *aModel=[self.mHistoryDataSource objectAtIndex:indexPath.row];
    if(aModel.mVideoModel.shortDescription.length)
    {
        NSLog(@"aModel.mVideoModel.shortDescription=%@",aModel.mVideoModel.shortDescription);
        CGRect labelRect = [aModel.mVideoModel.shortDescription
                            boundingRectWithSize:CGSizeMake(self.view.frame.size.width-(12+125+12+12), 1000)
                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                            attributes:@{
                                         NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:14.0]
                                         }
                            context:nil];
        
        NSLog(@"labelRect=%f %f",labelRect.size.width,labelRect.size.height);
         paddingHeight=labelRect.size.height>40?11:0;
    }
    NSLog(@"paddingHeight=%f",paddingHeight);*/
    return cellHeight;
}

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc
{
    [self.refreshControl endRefreshing];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mHistoryTableView.delegate = nil;
    self.mHistoryTableView.dataSource = nil;
    self.mHistoryDataSource = nil;
    self.refreshControl = nil;
}

#pragma mark Guest User Methods

- (void)addNotificationToReloadHistoryDataWhenGuestLogIn
{
    if (((AppDelegate *)kSharedApplicationDelegate).isGuestUser)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getHistoryDataFromServer) name:@"fetchChannelSubscriptionWhenGuestLogin" object:nil];
    }
}

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    NSString *strToView = @"";
    strToView = @"ViewHistory";
    return strToView;
}

- (NSString *)getPathStringForSelectedVideo:(HistoryModel *)HistoryModel channelLogoTapped:(BOOL)ischannelLogoTapped
{
    NSString *str = @"";
    if (ischannelLogoTapped)
    {
        VideoModel *videoModel = HistoryModel.mVideoModel;

        str = [str stringByAppendingString:[NSString stringWithFormat:@"VideoId-%@/VideoTitle-%@/ShowId-%@/ShowTitle-%@", videoModel.uniqueId, videoModel.title, videoModel.channelInfo.uniqueId, videoModel.channelInfo.title]];
    }
    else
    {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"VideoId-%@/VideoTitle-%@", HistoryModel.mVideoId, HistoryModel.mVideoModel.title ? HistoryModel.mVideoModel.title : @""]];
    }
    return str;
}

@end
