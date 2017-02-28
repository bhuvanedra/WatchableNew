//
//  GenreViewController.m
//  Watchable
//
//  Created by Valtech on 3/9/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "GenreViewController.h"
#import "PlayListCollectionViewCell.h"
#import "GenreDetailViewController.h"
#import "Utilities.h"
#import "ServerConnectionSingleton.h"
#import "GenreModel.h"
#import "SearchViewController.h"
#import "SwrveUtility.h"
#import "GAUtilities.h"
#import "ImageURIBuilder.h"
#import "UIImageView+WebCache.h"
#import "GenreWatchableOriginalsCollectionViewCell.h"
#import "ChannelModel.h"
#import "PlayDetailViewController.h"
#import "Watchable-Swift.h"

@interface GenreViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    GenreCollectionReusableView *headerVw;
    NSMutableArray *arrayExclusives, *arrayTempExclusives;
    NSString *mFeaturedShowTitle;
}

@property (weak, nonatomic) IBOutlet UICollectionView *mPlayListCollectionView;
@property (strong, nonatomic) NSMutableArray *mGenreArray;

@end

@implementation GenreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.mPlayListCollectionView.hidden = YES;
    [self createNavBarWithHidden:NO];
    [self setNavigationBarTitle:kNavTitleBrowse withFont:nil withTextColor:nil];
    [self setSearchButtonOnNarBar];

    self.mPlayListCollectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:YES];
    self.mGenreArray = [[NSMutableArray alloc] init];
    arrayExclusives = [[NSMutableArray alloc] init];
    arrayTempExclusives = [[NSMutableArray alloc] init];
    [self getDataFromServer];
    [Utilities setAppBackgroundcolorForView:self.mPlayListCollectionView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"GenreScreen"];
}

- (void)getGenreIDFromServer
{
    __weak GenreViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [[ServerConnectionSingleton sharedInstance] sendRequestTogetGenreWithResponseBlock:^(NSArray *responseArray) {

      [weakSelf performSelectorOnMainThread:@selector(updateDataSource:) withObject:responseArray waitUntilDone:NO];

    }
        errorBlock:^(NSError *error) {
          [weakSelf performSelectorOnMainThread:@selector(onGetGenreRequestFailureWithError:) withObject:error waitUntilDone:NO];
        }];
}

- (void)getFeatureShowFromServer
{
    __weak GenreViewController *weakSelf = self;
    if (self.mErrorView)
        [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [[ServerConnectionSingleton sharedInstance] sendRequestTogetFeaturedShowWithResponseBlock:^(NSDictionary *responseDict) {

      [weakSelf performSelectorOnMainThread:@selector(updateDataSourceForFeaturedShow:) withObject:responseDict waitUntilDone:NO];

    }
        errorBlock:^(NSError *error) {
          [weakSelf performSelectorOnMainThread:@selector(onGetGenreRequestFailureWithError:) withObject:error waitUntilDone:NO];
        }];
}

- (void)getDataFromServer
{
    BOOL isFeaturedShowDataSourceAvaliable = NO;

    BOOL isGenreDataSourceAvaliable = NO;

    if (arrayTempExclusives.count > 0)
    {
        isFeaturedShowDataSourceAvaliable = YES;
    }

    if (self.mGenreArray.count > 0)
    {
        isGenreDataSourceAvaliable = YES;
    }

    if (!isFeaturedShowDataSourceAvaliable)
    {
        [self getFeatureShowFromServer];
    }

    if (!isGenreDataSourceAvaliable)
    {
        [self getGenreIDFromServer];
    }
}
- (void)onGetGenreRequestFailureWithError:(NSError *)error
{
    __weak GenreViewController *weakSelf = self;
    //self.mPlayListCollectionView.hidden = YES;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureInLandingScreenTryAgainButton withTryAgainSelector:@selector(getDataFromServer) withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainButton withTryAgainSelector:@selector(getDataFromServer) withInputParameters:nil];
    }
}

- (void)updateDataSourceForFeaturedShow:(NSDictionary *)aDict
{
    [arrayTempExclusives removeAllObjects];
    [arrayExclusives removeAllObjects];
    NSArray *aArray = [aDict objectForKey:@"response"];
    mFeaturedShowTitle = [aDict objectForKey:@"title"];
    if (aArray.count > 3)
    {
        aArray = [aArray subarrayWithRange:NSMakeRange(0, 3)];
    }

    if (aArray.count)
    {
        [arrayTempExclusives addObjectsFromArray:aArray];
    }

    [arrayExclusives addObjectsFromArray:aArray];

    if (aArray.count > 1)
    {
        [arrayExclusives addObject:[arrayTempExclusives objectAtIndex:0]];
        [arrayExclusives insertObject:[arrayTempExclusives lastObject] atIndex:0];
    }

    [self performSelectorOnMainThread:@selector(reloadCollectionView) withObject:nil waitUntilDone:NO];

    [self performSelector:@selector(insertObjectInFirstIndex) withObject:nil afterDelay:0.05];
}

- (void)updateDataSource:(NSArray *)aArray
{
    [self.mGenreArray removeAllObjects];
    [self.mGenreArray addObjectsFromArray:aArray];

    //    if (_mGenreArray.count % 2 != 0) {
    //        GenreModel *modal = [[GenreModel alloc]init];
    //        [_mGenreArray addObject:modal];
    //    }

    [self performSelectorOnMainThread:@selector(reloadCollectionView) withObject:nil waitUntilDone:NO];
}

- (void)insertObjectInFirstIndex
{
    if (arrayExclusives.count > 1)
    {
        [headerVw.collectionVwOriginals scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    }
}

- (void)reloadCollectionView
{
    [self.mPlayListCollectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == _mPlayListCollectionView)
    {
        return self.mGenreArray.count;
    }
    else
    {
        return arrayExclusives.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _mPlayListCollectionView)
    {
        PlayListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GenereListCellId" forIndexPath:indexPath];

        cell.mPlayListImageView.frame = CGRectMake(cell.mPlayListImageView.frame.origin.x, cell.mPlayListImageView.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
        GenreModel *theModel = [self.mGenreArray objectAtIndex:indexPath.row];

        //        if (theModel.genreId == nil) {
        //            cell.mPlayListImageView.image = [UIImage imageNamed:@""];
        //            cell.mGenreTitleLabel.text = @"";
        //        }else{

        if (isNewGenreAPIEnable)
        {
            NSString *aGenreTitleStr = theModel.genreTitle;
            cell.mGenreTitleLabel.text = aGenreTitleStr;
            cell.mGenreTitleLabel.font = kRobotoBold(24);
            //cell.mPlayListImageView.image = [Utilities getNewGenreImagesWithTitleName:theModel.genreTitle];

            NSString *aImgURL = theModel.relatedLinks[@"default-image"];

            NSString *imageUrlString = [ImageURIBuilder buildURLWithString:aImgURL withSize:cell.bounds.size];
            NSLog(@"imageUrlString=%@", imageUrlString);

            if (imageUrlString)
            {
                [cell.mPlayListImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                           placeholderImage:nil
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                  }];
            }
            else
            {
                cell.mPlayListImageView.image = nil;
            }
        }
        else
        {
            cell.mGenreTitleLabel.text = [[Utilities getGenreTitlesForGenereId:theModel.genreId] uppercaseString];
            cell.mPlayListImageView.image = [Utilities getGenreImagesForGenereId:theModel.genreId];
            cell.mPlayListImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        // }
        return cell;
    }
    else
    {
        GenreWatchableOriginalsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WatchableOriginalsCellID" forIndexPath:indexPath];

        ChannelModel *aModel = arrayExclusives[indexPath.row];

        float aScreenWidth = CGRectGetWidth(self.view.frame);
        CGSize aImageViewSize = CGSizeMake(aScreenWidth, (aScreenWidth / 2));

        NSString *imageUrlString = [ImageURIBuilder buildImageUrlWithString:aModel.relatedLinks[@"default-image"] ForImageType:Two2One_logo withSize:aImageViewSize];
        NSLog(@"INDEXPATH=%ld", indexPath.row);
        NSLog(@"imageUrlString=%@", imageUrlString);
        if (imageUrlString)
        {
            [cell.imgVwWatchableOriginal sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                           placeholderImage:[UIImage imageNamed:@"logoEmptyState.png"]
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                                  }];
        }
        else
        {
            cell.imgVwWatchableOriginal.image = [UIImage imageNamed:@"logoEmptyState.png"];
        }

        return cell;
    }
}

#pragma mark
#pragma mark UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //    [self presentSearchController];
    //    return;

    if (collectionView != _mPlayListCollectionView)
    {
        ChannelModel *aModel = [arrayExclusives objectAtIndex:indexPath.row];
        [self pushPlayDetailControllerWithData:aModel];
    }
    else if (self.mGenreArray.count > 0)
    {
        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        //PlayListDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayListDetailViewController"];
        GenreDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"GenreDetailViewController"];

        GenreModel *theModel = [self.mGenreArray objectAtIndex:indexPath.row];

        // aPlayListDetailViewController.genreTitleString =[Utilities getGenreTitlesForGenereId:theModel.genreTitle];

        aPlayListDetailViewController.genreTitleString = isNewGenreAPIEnable ? theModel.genreTitle : [Utilities getGenreTitlesForGenereId:theModel.genreId];
        //aPlayListDetailViewController.genreSignatureImage = [Utilities getGenreImagesForGenereId:theModel.genreId];
        aPlayListDetailViewController.genreModel = theModel;
        //aPlayListDetailViewController.genreTitleString = theModel.genreTitle;

        if (isNewGenreAPIEnable)
        {
            //Swrve Events Starts
            NSString *replaceSpaceWithUnderScoreStr = [[theModel.genreTitle lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSString *replaceAndSymbolWithAndChar = [replaceSpaceWithUnderScoreStr stringByReplacingOccurrencesOfString:@"&" withString:@"and"];

            NSString *browseEventName = kSwrveBrowseEvent(replaceAndSymbolWithAndChar);
            [[SwrveUtility sharedInstance] postSwrveEvent:browseEventName];
        }
        else
        {
            NSString *strTitle = [Utilities getGenreTitlesForGenereId:theModel.genreId];

            NSArray *browseCategories = @[ @"Entertainment",
                                           @"Funny",
                                           @"Gaming",
                                           @"Fashion & Style",
                                           @"Food & Travel",
                                           @"Science & Tech",
                                           @"News",
                                           @"Sports",
                                           @"Automotive",
                                           @"Music" ];

            int selectedItemIndex = (int)[browseCategories indexOfObject:strTitle];

            switch (selectedItemIndex)
            {
                case 0:
                    // Item 1
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseEntertainment];
                    break;
                case 1:
                    // Item 2
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseFunny];

                    break;
                case 2:
                    // Item 3
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseGaming];
                    break;
                case 3:
                    // Item 4
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseFashion_and_style];
                    break;
                case 4:
                    // Item 5
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseFood_and_travel];
                    break;
                case 5:
                    // Item 6
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseScience_and_tech];
                    break;
                case 6:
                    // Item 7
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseNews];
                    break;
                case 7:
                    // Item 8
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseSports];
                    break;
                case 8:
                    // Item 9
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseAutomotive];
                    break;
                case 9:
                    // Item 10
                    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrvebrowseMusic];
                    break;
                default:
                    break;
            }

            //Swrve Events Ends
        }

        [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                             action:@"Selects Genre"
                                              label:[NSString stringWithFormat:@"%@/GenreId-%@/GenreTitle-%@", [self getTrackpath], theModel.genreId, theModel.genreTitle]
                                           andValue:nil];

        //          if (theModel.genreId == nil) {
        //              [self onClickingSearchButton];
        //          }else{
        [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
        //  }
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
    if (collectionView == _mPlayListCollectionView)
    {
        return CGSizeMake(self.view.frame.size.width / 2, self.view.frame.size.width / 2);
    }
    else
    {
        float aScreenWidth = CGRectGetWidth(self.view.frame);
        return CGSizeMake(aScreenWidth, (aScreenWidth / 2));
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    headerVw = nil;
    if (collectionView == _mPlayListCollectionView)
    {
        headerVw = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"GenreHeaderViewID" forIndexPath:indexPath];

        [self setCollectionViewHeaderTitle:@"Watchable Original" withGenreTitle:@"EXPLORE MORE CATEGORIES"];
        [headerVw setTotalPage:arrayTempExclusives.count];
    }
    else
    {
        headerVw = (GenreCollectionReusableView *)[[UIView alloc] initWithFrame:CGRectZero];
    }

    return headerVw;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (collectionView == _mPlayListCollectionView)
    {
        if (arrayExclusives.count > 0)
        {
            float aScreenWidth = CGRectGetWidth(self.view.frame);
            return CGSizeMake(aScreenWidth, (aScreenWidth / 2) + 120);
        }
        else
        {
            return CGSizeZero;
        }
    }
    else
    {
        return CGSizeZero;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (void)setCollectionViewHeaderTitle:(NSString *)aTitle withGenreTitle:(NSString *)aGenreTitle
{
    if (headerVw != nil && [headerVw isMemberOfClass:[GenreCollectionReusableView class]])
    {
        headerVw.lblGenreTopTitle.font = kRobotoMedium(15);
        headerVw.lblGenreTopTitle.text = _mGenreArray.count > 0 ? aGenreTitle : @"";
        headerVw.lblHeaderTitle.font = kRobotoMedium(15);
        headerVw.lblHeaderTitle.text = mFeaturedShowTitle ? mFeaturedShowTitle : @"Watchable Original";
    }
}

- (void)relaodCollectionViewHeader
{
    [self setCollectionViewHeaderTitle:@"Watchable Original" withGenreTitle:@"EXPLORE MORE CATEGORIES"];
    [headerVw.collectionVwOriginals reloadData];
    int pageCount = headerVw.collectionVwOriginals.contentOffset.x / headerVw.collectionVwOriginals.frame.size.width;
    [headerVw setPageControlIndex:pageCount];
}
#pragma mark Scrollview Delegate Method

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}

#pragma mark
#pragma mark Button Action
- (void)onClickingSearchButton
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Search Button"
                                          label:[NSString stringWithFormat:@"%@", [self getTrackpath]]
                                       andValue:nil];
    [self presentSearchController];
}
- (void)presentSearchController
{
    SearchViewController *aSearchViewController = [[SearchViewController alloc] initWithNibName:@"SearchViewController" bundle:nil];
    [self.navigationController pushViewController:aSearchViewController animated:NO];
}

- (void)dealloc
{
    self.mPlayListCollectionView.delegate = nil;
    self.mPlayListCollectionView.dataSource = nil;
    self.mGenreArray = nil;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    return @"GenreTab";
}

#pragma mark - ScrollviewDelegates

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Calculate where the collection view should be at the right-hand end item
    if (scrollView == headerVw.collectionVwOriginals && arrayExclusives.count > 1)
    {
        float contentOffsetWhenFullyScrolledRight = headerVw.collectionVwOriginals.frame.size.width * (arrayExclusives.count - 1);
        if (scrollView.contentOffset.x == contentOffsetWhenFullyScrolledRight)
        {
            // user is scrolling to the right from the last item to the 'fake' item 1.
            // reposition offset to show the 'real' item 1 at the left-hand end of the collection view
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];

            [headerVw.collectionVwOriginals scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        }
        else if (scrollView.contentOffset.x == 0)
        {
            // user is scrolling to the left from the first item to the fake 'item N'.
            // reposition offset to show the 'real' item N at the right end end of the collection view
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:([arrayExclusives count] - 2) inSection:0];

            [headerVw.collectionVwOriginals scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        }

        CGRect visibleRect = (CGRect){.origin = headerVw.collectionVwOriginals.contentOffset, .size = headerVw.collectionVwOriginals.bounds.size};
        CGPoint visiblePoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
        NSIndexPath *visibleIndexPath = [headerVw.collectionVwOriginals indexPathForItemAtPoint:visiblePoint];

        ChannelModel *aChannelObj = [arrayExclusives objectAtIndex:visibleIndexPath.row];
        [headerVw setPageControlIndex:(int)[arrayTempExclusives indexOfObject:aChannelObj]];
    }
}

@end
