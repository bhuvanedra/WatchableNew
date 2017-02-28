//
//  SearchViewController.m
//  Watchable
//
//  Created by Valtech on 5/12/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "SearchViewController.h"
#import "ServerConnectionSingleton.h"
#import "VideoModel.h"
#import "ChannelModel.h"
#import "PlaylistModel.h"
#import "EpisodeTableViewCell.h"
#import "ImageURIBuilder.h"
#import "UIImageView+WebCache.h"
#import "PlayDetailViewController.h"
#import "AnalyticsEventsHandler.h"
#import "GAUtilities.h"
#import "Watchable-Swift.h"

#define kSeperatorLineTag 11111
@interface SearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mSearchTableView;
@property (strong, nonatomic) NSMutableArray *mChannelsArray;
@property (strong, nonatomic) NSMutableArray *mVideosArray;
@property (strong, nonatomic) NSMutableArray *mPlayListArray;
@property (strong, nonatomic) NSString *mSearchedText;
@property (strong, nonatomic) EmptyDataErrorView *mEmptyDataErrorView;
@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeUIElement];
    [self performSelector:@selector(makeSearchTextFieldFirstResponder) withObject:nil afterDelay:0.5];
    [Utilities setAppBackgroundcolorForView:self.mSearchTableView];
    [Utilities setAppBackgroundcolorForView:self.view];
    [Utilities setAppBackgroundcolorForView:self.mSearchBarBGView];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"SearchScreen"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)makeSearchTextFieldFirstResponder
{
    [self.mSearchBarTextField becomeFirstResponder];
}
- (IBAction)onClickingCancelButton:(id)sender
{
    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Cancel Search"
                                          label:[NSString stringWithFormat:@"%@", [self getTrackpath]]
                                       andValue:nil];

    [[ServerConnectionSingleton sharedInstance] cancelSearchServerAPICall];
    [self.navigationController popViewControllerAnimated:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.mSearchBarTextField resignFirstResponder];
    return YES;
}

- (void)executeSearchWithString:(NSString *)searchString
{
    __weak SearchViewController *weakSelf = self;

    if ((self.mErrorView && ![Utilities isNetworkConnectionAvaliable]))
    {
        return;
    }
    [kSharedApplicationDelegate removeErrorViewFromController:weakSelf];

    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSearchResultForString:searchString
        withResponseBlock:^(NSDictionary *responseDict) {

          [weakSelf performSelectorOnMainThread:@selector(updateDataSource:) withObject:responseDict waitUntilDone:NO];
          //[weakSelf updateDataSource:responseDict ];

        }
        errorBlock:^(NSError *error) {
          [weakSelf performSelectorOnMainThread:@selector(onExecuteSearchWithStringFailure:) withObject:error waitUntilDone:NO];

        }];
}

- (void)onExecuteSearchWithStringFailure:(NSError *)error
{
    __weak SearchViewController *weakSelf = self;
    if (error.code == kErrorCodeNotReachable)
    {
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
    else /*if(error.code==kServerErrorCode)*/
    {    //
        [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
    }
}
- (void)updateDataSource:(NSDictionary *)aResponseDict
{
    [self.mChannelsArray removeAllObjects];
    [self.mPlayListArray removeAllObjects];
    [self.mVideosArray removeAllObjects];

    NSDictionary *aDict = [aResponseDict objectForKey:@"response"];
    NSString *aSearchedString = [aResponseDict objectForKey:@"searchedStirng"];

    if (aDict)
    {
        NSArray *aChannelArray = [aDict objectForKey:@"Channels"];
        if (aChannelArray.count)
        {
            [self.mChannelsArray addObjectsFromArray:aChannelArray];
        }

        NSArray *aVideoArray = [aDict objectForKey:@"Videos"];
        if (aVideoArray.count)
        {
            // NSArray *aVideoTitleArray=[aVideoArray valueForKey:@"title"];
            // NSArray *aChannelTitleArray=[aVideoArray valueForKey:@"channelTitle"];
            [self.mVideosArray addObjectsFromArray:aVideoArray];
        }

        NSArray *aPlayListArray = [aDict objectForKey:@"PlayList"];
        if (aPlayListArray.count)
        {
            [self.mPlayListArray addObjectsFromArray:aPlayListArray];
        }

        [[AnalyticsEventsHandler sharedInstance] postAnalyticsSearchEventType:kEventTypeSearch eventName:kEventNameSearch searchQuery:aSearchedString andSearchResults:[NSString stringWithFormat:@"%lu,%lu", _mChannelsArray.count, _mVideosArray.count]];
    }
    [self.mSearchTableView reloadData];

    if (self.mChannelsArray.count == 0 && self.mVideosArray.count == 0 && self.mPlayListArray.count == 0)
    {
        [self addDataUnAvailableViewForSearchSring:aSearchedString];
    }
    else
    {
        [self removeDataUnAvailableView];
    }
}

- (void)addDataUnAvailableViewForSearchSring:(NSString *)aSearchedString
{
    if (!self.mEmptyDataErrorView)
    {
        NSString *aFormattedString = nil;
        if (aSearchedString.length)
        {
            aFormattedString = [NSString stringWithFormat:@"No results found for \"%@\"", aSearchedString];
        }
        else
        {
            aFormattedString = @"No results found";
        }
        CGRect errorViewFrame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
        self.mEmptyDataErrorView = [[EmptyDataErrorView alloc] initWithFrame:errorViewFrame errorMsg:aFormattedString];
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

- (NSMutableAttributedString *)attributedStringForSearchedString:(NSString *)searchString inStr:(NSString *)str isForEpisodeProvider:(BOOL)isEpisodeProvider
{
    NSLog(@" searchString %@ in string %@", searchString, str);
    NSMutableAttributedString *aAttributedText = [[NSMutableAttributedString alloc] initWithString:str
                                                                                        attributes:@{
                                                                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:isEpisodeProvider ? 14.0 : 16.0],
                                                                                            NSForegroundColorAttributeName : /*isEpisodeProvider?[UIColor colorWithRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1.0]: [UIColor colorWithRed:189.0/255.0 green:195.0/255.0 blue:199.0/255.0 alpha:1.0]*/
                                                                                                [UIColor colorWithRed:189.0 / 255.0
                                                                                                                green:195.0 / 255.0
                                                                                                                 blue:199.0 / 255.0
                                                                                                                alpha:1.0],
                                                                                        }];
    NSUInteger length = [str length];
    NSRange range = NSMakeRange(0, length);
    while (range.location != NSNotFound)
    {
        range = [str rangeOfString:searchString options:NSCaseInsensitiveSearch range:range];
        [aAttributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
        [aAttributedText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-DemiBold" size:isEpisodeProvider ? 14.0 : 16.0] range:range];

        //NSLog(@"%d,%d",range.location,range.length);
        if (range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            //NSLog(@"range %d,%d",range.location,range.length);

            //            count++;
            //            [aRangeArray addObject:[NSValue valueWithRange:range]];
        }
    }
    return aAttributedText;
}

- (void)initializeUIElement
{
    UIView *aSearchBarLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    UIImage *aSearchImage = [UIImage imageNamed:@"searchBarSearch.png"];
    UIImageView *aSearchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 8, 14, 14)];
    aSearchImageView.image = aSearchImage;
    [aSearchBarLeftView addSubview:aSearchImageView];
    [self.mSearchBarTextField setLeftView:aSearchBarLeftView];
    [self.mSearchBarTextField setLeftViewMode:UITextFieldViewModeAlways];
    //    self.mSearchBarTextField.tintColor = [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];

    UIView *aSearchBarClearButtonLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    UIButton *aClearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aClearButton addTarget:self action:@selector(onClickingSearchClearButton) forControlEvents:UIControlEventTouchUpInside];
    aClearButton.frame = CGRectMake(10, 8, 14, 14);
    [aClearButton setImage:[UIImage imageNamed:@"searchBarClear.png"] forState:UIControlStateNormal];
    [aSearchBarClearButtonLeftView addSubview:aClearButton];
    [self.mSearchBarTextField setRightView:aSearchBarClearButtonLeftView];
    [self.mSearchBarTextField setRightViewMode:UITextFieldViewModeWhileEditing];
    self.mSearchBarTextField.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
    self.mSearchBarTextField.tintColor = [UIColor grayColor];
    self.mSearchBarTextField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Search"
                                        attributes:@{
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:241.0 / 255.0 green:241.0 / 255.0 blue:241.0 / 255.0 alpha:.35],
                                            NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:16.0]
                                        }];

    self.mChannelsArray = [[NSMutableArray alloc] init];
    self.mVideosArray = [[NSMutableArray alloc] init];
    self.mPlayListArray = [[NSMutableArray alloc] init];
    self.mSearchTableView.delegate = self;
    self.mSearchTableView.dataSource = self;
}

- (void)onClickingSearchClearButton
{
    [[ServerConnectionSingleton sharedInstance] cancelSearchServerAPICall];
    [self resetTableView];
    self.mSearchedText = @"";
    self.mSearchBarTextField.text = @"";
    [self removeDataUnAvailableView];
}
- (void)searchForDB:(NSString *)aSearchText
{
    NSMutableArray *aVideoArray = [[NSMutableArray alloc] init];
    NSMutableArray *aChannelArray = [[NSMutableArray alloc] init];

    [aChannelArray addObject:@"Prank"];
    [aChannelArray addObject:@"Red Bull sports"];
    [aChannelArray addObject:@"sports Bull sports"];
    [aChannelArray addObject:@"Sports"];
    [aVideoArray addObject:@"African accent"];
    [aVideoArray addObject:@"A Troublesome Teen"];
    [aVideoArray addObject:@"Anger boys"];
    [aVideoArray addObject:@"sports Football sports flop prank"];
    [aVideoArray addObject:@"Good cop pull over prank"];

    [self.mChannelsArray removeAllObjects];
    [self.mVideosArray removeAllObjects];

    NSArray *channelARRAY = [aChannelArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[c] %@", aSearchText]];
    if (channelARRAY.count)
    {
        [self.mChannelsArray addObjectsFromArray:channelARRAY];
    }

    NSArray *videoARRAY = [aVideoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[c] %@", aSearchText]];
    if (videoARRAY.count)
    {
        [self.mVideosArray addObjectsFromArray:videoARRAY];
    }

    self.mSearchedText = aSearchText;

    [self.mSearchTableView reloadData];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self resetTableView];
    NSString *modifiedFieldText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // NSString *aTrimmedString=[modifiedFieldText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (modifiedFieldText.length > 2)
    {
        // [self searchForDB:modifiedFieldText];
        self.mSearchedText = modifiedFieldText;
        [self executeSearchWithString:modifiedFieldText];
    }
    else
    {
        [[ServerConnectionSingleton sharedInstance] cancelSearchServerAPICall];
    }
    [self removeDataUnAvailableView];
    return YES;
}

- (void)resetTableView
{
    [self.mVideosArray removeAllObjects];
    [self.mChannelsArray removeAllObjects];
    [self.mPlayListArray removeAllObjects];
    [self.mSearchTableView reloadData];
}
#pragma mark
#pragma mark UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.mChannelsArray.count;
    }
    if (section == 1)
    {
        return self.mPlayListArray.count;
    }
    if (section == 2)
    {
        return self.mVideosArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1)
    {
        static NSString *cellIdentifier = @"SearchCell";
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];

            cell.contentView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];

            UIView *aSeperatorLine = [[UIView alloc] initWithFrame:CGRectMake(10, 59, self.view.frame.size.width - 20, 1)];
            aSeperatorLine.backgroundColor = [UIColor blackColor];
            aSeperatorLine.tag = kSeperatorLineTag;
            [cell addSubview:aSeperatorLine];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        UIView *aSeperatorLineView = [cell viewWithTag:kSeperatorLineTag];
        aSeperatorLineView.hidden = NO;

        if (indexPath.section == 0 || indexPath.section == 1)
        {
            if (indexPath.section == 0 && indexPath.row == self.mChannelsArray.count - 1)
            {
                aSeperatorLineView.hidden = YES;
            }
            else if (indexPath.section == 1 && indexPath.row == self.mPlayListArray.count - 1)
            {
                aSeperatorLineView.hidden = YES;
            }
        }

        if (indexPath.section == 0)
        {
            ChannelModel *aChannelModel = [self.mChannelsArray objectAtIndex:indexPath.row];
            NSString *aChannelTitle = aChannelModel.title;

            NSAttributedString *aAttributedStr = nil;
            if (aChannelTitle.length)
            {
                aAttributedStr = [self attributedStringForSearchedString:self.mSearchedText inStr:aChannelTitle isForEpisodeProvider:NO];
            }
            cell.textLabel.attributedText = aAttributedStr;
        }
        else if (indexPath.section == 1)
        {
            PlaylistModel *aModel = [self.mPlayListArray objectAtIndex:indexPath.row];
            NSString *aVideoTitle = aModel.title;
            NSAttributedString *aAttributedStr = nil;
            if (aVideoTitle.length)
            {
                aAttributedStr = [self attributedStringForSearchedString:self.mSearchedText inStr:aVideoTitle isForEpisodeProvider:NO];
            }

            cell.textLabel.attributedText = aAttributedStr;
        }
        return cell;
    }
    else
    {
        EpisodeTableViewCell *cell = (EpisodeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];

        if (!cell)
        {
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EpisodeTableViewCell" owner:self options:nil];
                cell = (EpisodeTableViewCell *)[nib objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            VideoModel *aVideoModel = [self.mVideosArray objectAtIndex:indexPath.row];
            //cell.mLogoImageView.image=nil;
            NSLog(@"video title=%@, video channel=%@", aVideoModel.title, aVideoModel.channelTitle);
            NSAttributedString *aTitleAttributedStr = nil;
            if (aVideoModel.title.length)
            {
                aTitleAttributedStr = [self attributedStringForSearchedString:self.mSearchedText inStr:aVideoModel.title isForEpisodeProvider:YES];
            }
            NSAttributedString *aProviderAttributedStr = nil;
            if (aVideoModel.channelTitle.length)
            {
                aProviderAttributedStr = [self attributedStringForSearchedString:self.mSearchedText inStr:aVideoModel.channelTitle isForEpisodeProvider:NO];
            }

            //cell.mTitleLabel should be channel title
            //cell.mProviderNameLabel should be video title

            cell.mTitleLabel.attributedText = aProviderAttributedStr;
            cell.mProviderNameLabel.attributedText = aTitleAttributedStr;

            NSString *imageUrlString = [ImageURIBuilder buildURLWithString:aVideoModel.imageUri withSize:cell.mLogoImageView.frame.size];

            cell.mLogoImageView.image = nil;
            if (imageUrlString)
            {
                [cell.mLogoImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                       placeholderImage:nil
                                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                              }];
            }
            else
            {
                cell.mLogoImageView.image = nil;
            }
        }
        return cell;
    }
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        [self onSelectingShowSectionWithIndex:indexPath];
    }
    else if (indexPath.section == 1)
    {
        [self onSelectingPlayListSectionWithIndex:indexPath];
    }
    else if (indexPath.section == 2)
    {
        [self onSelectingEpisodeSectionWithIndex:indexPath];
    }
    NSLog(@"selected cell index=%ld", (long)indexPath.row);
}

- (void)onSelectingShowSectionWithIndex:(NSIndexPath *)aIndexPath
{
    ChannelModel *aChannelModel = [self.mChannelsArray objectAtIndex:aIndexPath.row];

    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Search Show"
                                          label:[NSString stringWithFormat:@"%@/ShowId-%@/ShowTitle-%@", [self getTrackpath], aChannelModel.uniqueId, aChannelModel.title]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mChannelDataModel = aChannelModel;
    aPlayListDetailViewController.isFromGenre = YES;
    aPlayListDetailViewController.isFromSearch = YES;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

- (void)onSelectingPlayListSectionWithIndex:(NSIndexPath *)aIndexPath
{
    PlaylistModel *aModel = [self.mPlayListArray objectAtIndex:aIndexPath.row];
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mDataModel = aModel;
    aPlayListDetailViewController.isFromSearch = YES;
    //aPlayListDetailViewController.isFromPlayList=YES;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

- (void)onSelectingEpisodeSectionWithIndex:(NSIndexPath *)aIndexPath
{
    VideoModel *aVideoModel = [self.mVideosArray objectAtIndex:aIndexPath.row];

    [GAUtilities sendWatchableEventWithCategory:kGoogleAnalyticsUserActionEvent
                                         action:@"Taps on Search Video"
                                          label:[NSString stringWithFormat:@"%@/VideoId-%@/VideoTitle-%@", [self getTrackpath], aVideoModel.uniqueId, aVideoModel.title]
                                       andValue:nil];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
    aPlayListDetailViewController.mVideoModel = aVideoModel;
    aPlayListDetailViewController.isEpisodeClicked = YES;
    aPlayListDetailViewController.isPlayLatestVideo = YES;
    aPlayListDetailViewController.isFromSearch = YES;
    [self.navigationController pushViewController:aPlayListDetailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
    {
        return 97;
    }
    return 60.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.mChannelsArray.count > 0 ? 40.0 : 0.0;
    }
    if (section == 1)
    {
        return self.mPlayListArray.count > 0 ? 40.0 : 0.0;
    }
    if (section == 2)
    {
        return self.mVideosArray.count > 0 ? 40.0 : 0.0;
    }
    return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *aHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40.0)];
    UILabel *aTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 1, aHeaderView.frame.size.width - 5, aHeaderView.frame.size.height - 2)];
    aTitleLabel.textColor = [UIColor colorWithRed:106.0 / 255.0 green:110.0 / 255.0 blue:113.0 / 255.0 alpha:1.0];
    aTitleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:16.0];
    if (section == 0)
    {
        aTitleLabel.text = @"SHOWS";
    }
    else if (section == 1)
    {
        aTitleLabel.text = @"PLAYLISTS";
    }
    else if (section == 2)
    {
        aTitleLabel.text = @"VIDEOS";
    }

    [aHeaderView addSubview:aTitleLabel];
    aHeaderView.backgroundColor = [UIColor blackColor];
    return aHeaderView;
}

/*-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 8, 0, 8)];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}*/

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    //return 270.0;
//}

#pragma mark Scrollview Delegate Method
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint aPoint = scrollView.contentOffset;
    self.scrollViewContentOffSet = aPoint;
    [kSharedApplicationDelegate animateConfirmEmailToastToVisibleWithErrorViewVisible:self.mErrorView ? NO : NO];
}

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

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    return @"SearchView";
}

@end
