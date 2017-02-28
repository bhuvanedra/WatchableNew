//
//  GenreDetailViewController.m
//  Watchable
//
//  Created by Valtech on 3/9/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "GenreDetailViewController.h"
#import "GenreCollectionViewCell.h"
#import "GenreSignatureCollectionViewCell.h"
#import "ServerConnectionSingleton.h"
#import "ImageURIBuilder.h"
#import "ShowModel.h"
#import "WatchableConstants.h"
#import "Utilities.h"
#import "ChannelModel.h"
#import "UIImageView+WebCache.h"
#import "AnalyticsEventsHandler.h"
#import "PlayDetailViewController.h"
#import "SwrveUtility.h"
#import "GenreModel.h"
#import "GAUtilities.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Watchable-Swift.h"

/*Pagination #define kFooterViewTag 9999
 #define kViewMoreButtonTag 9998
 #define kFooterAccessoryIndicatorTag 9997*/

@interface GenreDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *mCollectionView;

@property (nonatomic, strong) NSMutableArray *mPlayListDataSource;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
/*Pagination @property (nonatomic,strong) UIView *mFooterView;*/
@property (nonatomic) BOOL isrefreshing;

@end

@implementation GenreDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self initialSetup];
    [self registerCollectionCells];
    [self getDataFromServerForPlayList];
    [self addNotificationForFollowChannel];

    [Utilities setAppBackgroundcolorForView:self.mCollectionView];
    [Utilities setAppBackgroundcolorForView:self.view];

    [self addNotificationForFollowStatusWhenGusetUserLogin];
}

- (void)initialSetup
{
    [self createNavBarWithHidden:YES];
    [self setNavigationBarTitle:[self.genreTitleString uppercaseString] withFont:nil withTextColor:nil];
    [self setBackButtonOnView];

    self.mPlayListDataSource = [[NSMutableArray alloc] init];
    //  self.mCollectionView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.isHidden?-20:-64, 0, 0, 0);

    self.mCollectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getDataFromServerForPlayListOnRefresh)
                  forControlEvents:UIControlEventValueChanged];

    [[self.refreshControl.subviews objectAtIndex:0] setFrame:CGRectMake(0, 5, self.refreshControl.frame.size.width, self.refreshControl.frame.size.height)];

    [self.mCollectionView addSubview:self.refreshControl];

    self.mCollectionView.alwaysBounceVertical = YES;

    /*Pagination [self.mCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
     
     UICollectionViewFlowLayout *aFlowLayout=[[UICollectionViewFlowLayout alloc]init];
     [aFlowLayout setFooterReferenceSize:CGSizeMake(self.view.frame.size.width, 0)];
     self.mCollectionView.collectionViewLayout=aFlowLayout; */
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

- (void)postNotificationForFollowChannelId:(NSString *)aChannelId withFollowStatus:(BOOL)aFollowStatus
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:aChannelId, @"channelId", [NSNumber numberWithBool:aFollowStatus], @"followStatus", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationForFollowChannel" object:nil userInfo:userInfo];
}
- (void)registerCollectionCells
{
    UINib *cellNib = [UINib nibWithNibName:@"GenreCollectionViewCell" bundle:nil];
    [self.mCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"GenreCollectionViewCell"];

    UINib *firstCellNib = [UINib nibWithNibName:@"GenreSignatureCollectionViewCell" bundle:nil];
    [self.mCollectionView registerNib:firstCellNib forCellWithReuseIdentifier:@"GenreSignatureCollectionViewCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.mCollectionView reloadData];
    [self postFeedViewSwerveEvent:kSwrvefeedView andChannel:self.genreModel];
    [GAUtilities setWatchbaleScreenName:@"GenreDetailsScreen"];
    if (self.isrefreshing)
    {
        self.mCollectionView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
        [self.refreshControl beginRefreshing];
    }
}

- (void)postFeedViewSwerveEvent:(NSString *)eventName andChannel:(GenreModel *)aModel
{
    NSDictionary *payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:nil
                                                                        assetId:nil
                                                                   channleTitle:nil
                                                                      channleId:nil
                                                                     genreTitle:aModel.genreTitle
                                                                        genreId:aModel.genreId
                                                                 publisherTitle:nil
                                                                    publisherId:nil
                                                                  playlistTitle:nil
                                                                     playlistId:nil];

    [[SwrveUtility sharedInstance] postSwrveEvent:eventName withPayload:payload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.refreshControl endRefreshing];
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
    UICollectionViewCell *retrnCell = nil;

    /* if (indexPath.row==0) {
     
     GenreSignatureCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GenreSignatureCollectionViewCell" forIndexPath:indexPath];
     
     if(isNewGenreAPIEnable)
     {
     NSString *aImgURL= self.genreModel.relatedLinks[@"default-image"];
     
     
     NSString *imageUrlString=[ImageURIBuilder buildURLWithString:aImgURL withSize:cell.bounds.size];
     
     if(imageUrlString)
     {
     [cell.genreSignatureImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
     placeholderImage:nil
     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
     }];
     }
     else
     {
     cell.genreSignatureImageView.image=nil;
     }
     }
     else
     {
     cell.genreSignatureImageView.image = [Utilities getGenreImagesForGenereId:self.genreModel.genreId];
     }
     
     cell.genreTitleLabel.text = [self.genreTitleString uppercaseString];
     
     [cell sendSubviewToBack:cell.genreSignatureImageView];
     
     CGRect arect = cell.frame;
     arect.size.height = arect.size.height-5;
     
     [Utilities addGradientToGenreDetailFirstCellImageView:cell.genreSignatureImageView withFrame:arect];
     retrnCell = cell;
     
     }else{*/

    GenreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GenreCollectionViewCell" forIndexPath:indexPath];
    cell.showImage.layer.cornerRadius = 1.0;
    cell.showImage.layer.masksToBounds = YES;
    ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];

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

    cell.showTitle.text = aModel.title;
    // [cell.showTitle sizeToFit];
    cell.showDescription.text = aModel.showDescription;
    //[cell.showDescription sizeToFit];

    float aWidth = self.view.frame.size.width - (2 * 12);
    float aHeight = (aWidth / 2.0) * 1.0;
    CGSize aImageViewSize = CGSizeMake(aWidth, aHeight);
    NSString *imageUrlString = [ImageURIBuilder buildImageUrlWithString:aModel.relatedLinks[@"default-image"] ForImageType:Two2One_logo withSize:aImageViewSize];
    NSLog(@"INDEXPATH=%ld", indexPath.row);
    NSLog(@"imageUrlString=%@", imageUrlString);
    if (imageUrlString)
    {
        [cell.showImage sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                          placeholderImage:[UIImage imageNamed:@"logoEmptyState.png"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {

                                   if (isCoreSpotLightEnable)
                                   {
                                       NSString *strUniqueID = [NSString stringWithFormat:@"%@,%@", kDeepLinkShowIdKey, aModel.uniqueId];

                                       [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[ strUniqueID ]
                                                                                                      completionHandler:^(NSError *_Nullable error) {
                                                                                                        [self setSearchableItemForShows:aModel image:image];

                                                                                                      }];
                                   }
                                 }];
    }
    else
    {
        cell.showImage.image = [UIImage imageNamed:@"logoEmptyState.png"];
    }

    retrnCell = cell;

    //}

    return retrnCell;
}

#pragma mark
#pragma mark UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= 0)
    {
        ChannelModel *aModel = [self.mPlayListDataSource objectAtIndex:indexPath.row];
        [self pushPlayDetailControllerWithData:aModel];
    }
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
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

#pragma mark
#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;

    //    if (indexPath.row == 0 ) {
    //        size = CGSizeMake(collectionView.frame.size.width, 160);
    //    }else{

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

    //}

    return size;
}
//

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

/*Pagination
 
 - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
 
 UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
 
 if (reusableview==nil) {
 reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
 }
 UIView *aView= [reusableview viewWithTag:kFooterViewTag];
 if(!aView)
 {
 [self createFooterViewForCollectionView];
 aView=self.mFooterView;
 [reusableview addSubview:aView];
 }
 
 return reusableview;
 }
 return nil;
 }
 
 -(void)createFooterViewForCollectionView
 {
 @synchronized(self)
 {
 if(!self.mFooterView)
 {
 UIView *aView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
 aView.backgroundColor=[UIColor blackColor];
 CustomIndexButton *aIndexButton=[CustomIndexButton buttonWithType:UIButtonTypeCustom];
 aIndexButton.tag=kViewMoreButtonTag;
 [aIndexButton setTitle:@"View more..." forState:UIControlStateNormal];
 float aButtonWidth=80.0;
 aIndexButton.titleLabel.font=[UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
 aIndexButton.frame=CGRectMake((aView.frame.size.width-aButtonWidth)/2, 7, aButtonWidth, 30);
 [aIndexButton addTarget:self action:@selector(onClickingViewMoreButton:) forControlEvents:UIControlEventTouchUpInside];
 [aView addSubview:aIndexButton];
 
 UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
 activityIndicator.frame=CGRectMake(aIndexButton.frame.origin.x+aIndexButton.frame.size.width, 0, 44, 44);
 activityIndicator.tag=kFooterAccessoryIndicatorTag;
 activityIndicator.hidesWhenStopped = YES;
 [aView addSubview:activityIndicator];
 self.mFooterView=aView;
 
 }
 }
 }
 
 -(void)startViewMoreActivityIndicator
 {
 if(self.mFooterView)
 {
 UIActivityIndicatorView *activityIndicator =(UIActivityIndicatorView*)[self.mFooterView viewWithTag:kFooterAccessoryIndicatorTag];
 [activityIndicator startAnimating];
 
 CustomIndexButton *aViewMoreButton=(CustomIndexButton*)[self.mFooterView viewWithTag:kViewMoreButtonTag];
 aViewMoreButton.enabled=NO;
 }
 }
 
 -(void)stopViewMoreActivityIndicator
 {
 if(self.mFooterView)
 {
 UIActivityIndicatorView *activityIndicator =(UIActivityIndicatorView*)[self.mFooterView viewWithTag:kFooterAccessoryIndicatorTag];
 [activityIndicator stopAnimating];
 
 CustomIndexButton *aViewMoreButton=(CustomIndexButton*)[self.mFooterView viewWithTag:kViewMoreButtonTag];
 aViewMoreButton.enabled=YES;
 }
 }
 
 -(void)onClickingViewMoreButton:(CustomIndexButton*)aButton
 {
 if(self.mFooterView)
 {
 NSInteger aButtonIndex= aButton.mIndexPath.row;
 if(aButtonIndex>0)
 {
 NSString *aPageNumber=[NSString stringWithFormat:@"%ld",aButtonIndex];
 [self getDataFromServerForPlayListWithPageNo:aPageNumber];
 }
 
 }
 }*/

#pragma mark Scrollview Delegate Method
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    /* if(aPoint.y>=115)
     {
     [self showNavBarWithAnimation];
     }
     else
     {
     [self hideNarBarWithAnimation];
     
     }*/

    /* float NavBarAlpha=0.0;
     
     NavBarAlpha=(aPoint.y/52.0)*kNavBarMaxAlphaValue;
     
     
     if(NavBarAlpha>kNavBarMaxAlphaValue)
     {
     NavBarAlpha=kNavBarMaxAlphaValue;
     }
     else if(NavBarAlpha<0.0)
     {
     NavBarAlpha=0.0;
     }
     
     [self setNavBarVisiblityWithAlpha:NavBarAlpha];*/

    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}

#pragma mark Server Call Method

- (void)getSessionTokenFromServer
{
    __weak GenreDetailViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
                                                                     WithresponseBlock:^(NSDictionary *responseDict) {
                                                                       [weakSelf getDataFromServerForPlayList];

                                                                     }
                                                                            errorBlock:^(NSError *error){

                                                                            }];
}

- (void)getDataFromServerForPlayList
{
    //[self getDataFromServerForPlayListWithPageNo:@"1"];

    __weak GenreDetailViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [weakSelf userInteractionEnableForViewElement:NO];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetChannelresponseBlock:^(NSDictionary *responseDict) {

      NSArray *responseArray = nil;
      if (responseDict)
      {
          responseArray = [responseDict objectForKey:@"response"];
          self.genreModel.totalChannels = [responseDict objectForKey:@"totalItems"];
      }
      __block NSArray *array = responseArray;

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf.refreshControl endRefreshing];
        [weakSelf updateDataSource:array];
        [weakSelf userInteractionEnableForViewElement:YES];

      }];

      [self getFollowStatusForChannelList:array];

    }
        errorBlock:^(NSError *error) {

          [weakSelf performSelectorOnMainThread:@selector(errorInGetDataFromServerForPlayList:) withObject:error waitUntilDone:NO];
          [weakSelf userInteractionEnableForViewElement:YES];
          [weakSelf.refreshControl endRefreshing];

        }
        forGenreId:self.genreModel.allChannelsUri];
}
/*
 
 -(void)getDataFromServerForPlayListWithPageNo:(NSString*)aPageNumber
 {
 __weak GenreDetailViewController *weakSelf = self;
 if(self.mErrorView)
 [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];
 if([aPageNumber isEqualToString:@"1"])
 {
 [weakSelf userInteractionEnableForViewElement:NO];
 }
 else
 {
 [weakSelf startViewMoreActivityIndicator];
 }
 
 [[ServerConnectionSingleton sharedInstance]sendRequestToGetChannelresponseBlock:^(NSDictionary *responseDict) {
 
 NSArray *responseArray=nil;
 if(responseDict)
 {
 responseArray=[responseDict objectForKey:@"response"];
 self.genreModel.totalChannels=[responseDict objectForKey:@"totalItems"];
 }
 __block NSArray *array = responseArray;
 
 [ [NSOperationQueue mainQueue]addOperationWithBlock:^{
 [weakSelf.refreshControl endRefreshing];
 [weakSelf stopViewMoreActivityIndicator];
 [weakSelf updateDataSource:array withPageNo:aPageNumber];
 [weakSelf userInteractionEnableForViewElement:YES];
 
 }];
 
 
 [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
 
 __block ChannelModel *aChannelModel = (ChannelModel*) obj;
 
 [[ServerConnectionSingleton sharedInstance]sendrequestToGetSubscriptionStatusForChannel:aChannelModel.uniqueId withResponseBlock:^(BOOL success) {
 if(aChannelModel)
 {
 aChannelModel.isChannelFollowing = success;
 [ [NSOperationQueue mainQueue]addOperationWithBlock:^{
 //                        NSArray *aVisibleIndexPaths= [weakSelf.mCollectionView indexPathsForVisibleItems];
 //                        if(aVisibleIndexPaths.count)
 //                            [weakSelf.mCollectionView reloadItemsAtIndexPaths:aVisibleIndexPaths];
 for (NSIndexPath *aIndexPath in [weakSelf.mCollectionView indexPathsForVisibleItems]) {
 if(aIndexPath.item!=0)
 {
 ChannelModel *channelModel=[weakSelf.mPlayListDataSource objectAtIndex:aIndexPath.item-1];
 if([channelModel.uniqueId isEqualToString:aChannelModel.uniqueId])
 {
 GenreCollectionViewCell *cell = (GenreCollectionViewCell*)[weakSelf.mCollectionView
 cellForItemAtIndexPath:aIndexPath];
 
 cell.mFollowButton.selected=channelModel.isChannelFollowing;
 
 if(cell.mFollowButton.selected)
 {
 cell.mFollowButtonWidthConstraint.constant=91.0;
 }
 else
 {
 cell.mFollowButtonWidthConstraint.constant=70.0;
 }
 break;
 }
 }
 }
 }];
 }
 
 //get the visible cell and update follow status
 
 } errorBlock:^(NSError *error) {
 
 }];
 
 }];
 
 
 
 
 } errorBlock:^(NSError *error) {
 
 NSDictionary *aDict=[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",aPageNumber,@"pageNo",nil];
 [weakSelf performSelectorOnMainThread:@selector(errorInGetDataFromServerForPlayList:) withObject:aDict waitUntilDone:NO];
 [weakSelf stopViewMoreActivityIndicator];
 [weakSelf userInteractionEnableForViewElement:YES];
 [weakSelf.refreshControl endRefreshing];
 
 } forGenreId:self.genreModel.allChannelsUri withPageNumber:aPageNumber];
 
 }
 */

- (void)userInteractionEnableForViewElement:(BOOL)isEnable
{
    if (isEnable)
    {
        self.mCollectionView.userInteractionEnabled = YES;
        self.isrefreshing = NO;
    }
    else
    {
        self.mCollectionView.userInteractionEnabled = NO;
    }
}

- (void)errorInGetDataFromServerForPlayList:(NSError *)aerror
{
    __weak GenreDetailViewController *weakSelf = self;

    NSError *error = aerror;

    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainButton withTryAgainSelector:@selector(getDataFromServerForPlayList) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataFromServerForPlayList) withInputParameters:nil];
    }

    [weakSelf performSelector:@selector(endRefresh) withObject:nil afterDelay:0.45];
}

- (void)endRefresh
{
    __weak GenreDetailViewController *weakSelf = self;

    [weakSelf.refreshControl endRefreshing];
}

- (void)updateDataSource:(NSArray *)aArray
{
    NSMutableArray *aMutableArray = nil;

    if (aArray)
    {
        aMutableArray = [[NSMutableArray alloc] initWithArray:aArray];
    }

    [self.mPlayListDataSource removeAllObjects];
    if (aMutableArray.count)
    {
        [self.mPlayListDataSource addObjectsFromArray:aMutableArray];
    }

    if (isCoreSpotLightEnable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setShowItemsIndexingBeforeReload:aArray];

        });
    }

    [self.mCollectionView reloadData];
}

/*-(void)updateDataSource:(NSArray*)aArray withPageNo:(NSString*)aPageNumber
 {
 NSMutableArray *aMutableArray=nil;
 
 if(aArray)
 {
 aMutableArray=[[NSMutableArray alloc]initWithArray:aArray];
 
 }
 if([aPageNumber isEqualToString:@"1"])
 {
 [self.mPlayListDataSource removeAllObjects];
 [self.mPlayListDataSource addObjectsFromArray:aMutableArray];
 [self.mCollectionView reloadData];
 
 if(aArray.count)
 [self showFooterView:YES WithPageNumber:aPageNumber];
 else
 [self showFooterView:NO WithPageNumber:@""];
 
 return;
 
 
 }
 else
 {
 if(aMutableArray)
 {
 NSArray *aKeyArray=  [aArray valueForKey:@"uniqueId"];
 NSMutableSet *aIncomingChannelIdsSet=[NSMutableSet setWithArray:aKeyArray];
 NSSet *aPresentChannelIdsSet = [NSSet setWithArray:[self.mPlayListDataSource valueForKey:@"uniqueId"]];
 [aIncomingChannelIdsSet minusSet:aPresentChannelIdsSet];
 if(aIncomingChannelIdsSet.count)
 {
 NSPredicate *aPredicate=  [NSPredicate predicateWithFormat:@"(uniqueId IN %@)", [aIncomingChannelIdsSet allObjects]];
 [aMutableArray filterUsingPredicate:aPredicate];
 }
 }
 }
 
 [self.mCollectionView performBatchUpdates:^{
 NSInteger resultsSize = [self.mPlayListDataSource count]+1; //data is the previous array of data
 if(aMutableArray.count)
 {
 [self.mPlayListDataSource addObjectsFromArray:aMutableArray];
 NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
 for (NSInteger i = resultsSize; i < resultsSize + aMutableArray.count; i++) {
 [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i
 inSection:0]];
 }
 [self.mCollectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
 }
 }
 completion:nil];
 
 
 if(aArray.count)
 [self showFooterView:YES WithPageNumber:aPageNumber];
 else
 [self showFooterView:NO WithPageNumber:@""];
 
 //[self.mCollectionView reloadData];
 
 }
 
 
 -(void)showFooterView:(BOOL)isShow WithPageNumber:(NSString*)aPageNumber
 {
 if(isShow)
 {
 int totalNoOfItems=self.genreModel.totalChannels.intValue;
 if(self.mPlayListDataSource.count>=totalNoOfItems)
 {
 isShow=NO;
 }
 }
 
 UICollectionViewFlowLayout *aFlowLayout= (UICollectionViewFlowLayout*)self.mCollectionView.collectionViewLayout;
 [aFlowLayout setFooterReferenceSize:CGSizeMake(self.view.frame.size.width,isShow?44: 0)];
 [self createFooterViewForCollectionView];
 
 if(isShow)
 {
 CustomIndexButton *aViewMoreButton= (CustomIndexButton*)[self.mFooterView viewWithTag:kViewMoreButtonTag];
 aViewMoreButton.mIndexPath=[NSIndexPath indexPathForRow:([aPageNumber intValue] +1) inSection:0];
 }
 
 }
 */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark
#pragma mark Button Action

- (void)postFeedFollowSwerveEvent:(NSString *)eventName andChannel:(ChannelModel *)aModel
{
    NSDictionary *payload = [SwrveUtility getPayloadforSwrveEventWithAssetTitle:nil
                                                                        assetId:nil
                                                                   channleTitle:aModel.title
                                                                      channleId:aModel.uniqueId
                                                                     genreTitle:self.genreModel.genreTitle
                                                                        genreId:self.genreModel.genreId
                                                                 publisherTitle:nil
                                                                    publisherId:nil
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

    __weak GenreDetailViewController *weakSelf = self;

    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

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

                    GenreCollectionViewCell *aCell = (GenreCollectionViewCell *)[weakSelf.mCollectionView cellForItemAtIndexPath:sender.mIndexPath];
                    if (aCell)
                    {
                        aCell.mFollowButtonWidthConstraint.constant = 91.0;
                        aCell.mFollowButton.selected = YES;
                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsEventType:kEventTypeUserAction eventName:kEventNameFollow playListId:nil channelId:aModel.uniqueId andAssetId:nil andFromPlaylistPage:NO];
                    }
                    aModel.isChannelFollowing = YES;

                    [weakSelf postNotificationForFollowChannelId:aModel.uniqueId withFollowStatus:YES];

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
                    GenreCollectionViewCell *aCell = (GenreCollectionViewCell *)[weakSelf.mCollectionView cellForItemAtIndexPath:sender.mIndexPath];
                    if (aCell)
                    {
                        aCell.mFollowButtonWidthConstraint.constant = 70.0;
                        aCell.mFollowButton.selected = NO;
                    }
                    aModel.isChannelFollowing = NO;
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
    __weak GenreDetailViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
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
        __weak GenreDetailViewController *weakSelf = self;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

          __block ChannelModel *aChannelModel = (ChannelModel *)obj;

          [[ServerConnectionSingleton sharedInstance] sendrequestToGetSubscriptionStatusForChannel:aChannelModel.uniqueId
                                                                                 withResponseBlock:^(BOOL success) {
                                                                                   if (aChannelModel)
                                                                                   {
                                                                                       aChannelModel.isChannelFollowing = success;
                                                                                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                                         //                        NSArray *aVisibleIndexPaths= [weakSelf.mCollectionView indexPathsForVisibleItems];
                                                                                         //                        if(aVisibleIndexPaths.count)
                                                                                         //                            [weakSelf.mCollectionView reloadItemsAtIndexPaths:aVisibleIndexPaths];
                                                                                         for (NSIndexPath *aIndexPath in [weakSelf.mCollectionView indexPathsForVisibleItems])
                                                                                         {
                                                                                             if (aIndexPath.item != 0)
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
                                                                                         }
                                                                                       }];
                                                                                   }

                                                                                   //get the visible cell and update follow status

                                                                                 }
                                                                                        errorBlock:^(NSError *error){

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
    strToView = [strToView stringByAppendingString:[NSString stringWithFormat:@"GenreDetails/GenreId-%@/GenreTitle-%@", self.genreModel.genreId, self.genreModel.genreTitle]];

    return strToView;
}

#pragma mark Core spot light  Methods
//Corespot light methods
- (void)setShowItemsIndexingBeforeReload:(NSArray *)arrayItems
{
    for (ChannelModel *cModal in arrayItems)
    {
        [self setSearchableItemForShows:cModal image:nil];
    }
}

- (void)setSearchableItemForShows:(ChannelModel *)cModal image:(UIImage *)img
{
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeImage];
    if (img != nil)
    {
        NSData *dataImg = UIImagePNGRepresentation(img);
        attributeSet.thumbnailData = dataImg;
    }

    attributeSet.title = cModal.title;
    attributeSet.contentDescription = cModal.showDescription;
    attributeSet.keywords = @[ cModal.title ];

    NSString *strUniqueID = [NSString stringWithFormat:@"%@,%@", kDeepLinkShowIdKey, cModal.uniqueId];
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:strUniqueID domainIdentifier:@"com.wtchable" attributeSet:attributeSet];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ]
                                                   completionHandler:^(NSError *_Nullable error) {
                                                     NSLog(@"Shows indexed");
                                                   }];
}

@end
