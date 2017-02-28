//
//  DeepLink.m
//  Watchable
//
//  Created by Valtech on 1/25/16.
//  Copyright © 2016 comcast. All rights reserved.
//

#import "DeepLink.h"
#import "WatchableConstants.h"
#import "AppDelegate.h"
#import "PlayListViewController.h"
#import "PlayDetailViewController.h"
#import "ChannelModel.h"
#import "PlaylistModel.h"

@interface DeepLink ()

- (void)navigateToDeeplinkMyShowsScreen;
- (void)navigateToDeeplinkGenreScreen;
- (void)navigateToDeeplinkPlayListScreen;
- (void)navigateToPlayDetailScreenWithPlayListId:(NSString *)aPlayListId withVideoId:(NSString *)aVideoId;
@end

@implementation DeepLink

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (void)handleDeepLinkingForIncomingDict:(NSDictionary *)aDict
{
    float aDelay = 0.0;
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        UINavigationController *playListNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:tabBarCntlr.selectedIndex];

        NSArray *aPlayListStackControllers = playListNavigationStack.viewControllers;

        if (aPlayListStackControllers.count)
        {
            UIViewController *aController = playListNavigationStack.topViewController;

            if ([aController isMemberOfClass:[PlayDetailViewController class]])
            {
                PlayDetailViewController *aPlaydetailController = (PlayDetailViewController *)aController;

                if (aPlaydetailController.isFullScreenMovieViewPresented)
                {
                    aPlaydetailController.shouldNotCallViewDidAppear = YES;
                    [aPlaydetailController setSelectedIndex:nil];
                    [aPlaydetailController rotateToPotraitMode];
                    aDelay = 2.0;
                }
            }
        }
    }

    [self performSelector:@selector(handleIncomingDict:) withObject:aDict afterDelay:aDelay];

    /* else if([aPushScreen caseInsensitiveCompare:@"myshows"]== NSOrderedSame)
     {
     
     if(aVideoId!=nil)
     {
     [self navigateToDeeplinkMyShowsScreen];
     }
     else
     {
     [self navigateToDeeplinkMyShowsScreen];
     }
     }*/
}

- (void)handleIncomingDict:(NSDictionary *)aDict
{
    NSString *aPlayListId = [aDict objectForKey:kDeepLinkPlayListIdKey];
    NSString *aVideoId = [aDict objectForKey:kDeepLinkVideoIdKey];
    NSString *aShowId = [aDict objectForKey:kDeepLinkShowIdKey];

    NSString *aPushScreen = [aDict objectForKey:kDeepLinkScreenIdKey];

    if (aPushScreen == nil)
    {
        if (aPlayListId != nil)
        {
            aPushScreen = kDeepLinkPlaylistScreenValue;
        }
        else if (aShowId != nil)
        {
            aPushScreen = kDeepLinkGenreScreenValue;
        }
    }

    if ([aPushScreen caseInsensitiveCompare:kDeepLinkPlaylistScreenValue] == NSOrderedSame)
    {
        if (aPlayListId != nil)
        {
            if (aVideoId != nil)
            {
                [self navigateToPlayDetailScreenWithPlayListId:aPlayListId withVideoId:aVideoId];
            }
            else
            {
                //play the first video
                [self navigateToPlayDetailScreenWithPlayListId:aPlayListId withVideoId:@"0"];
            }
        }
        else
        {
            [self navigateToDeeplinkPlayListScreen];
        }
    }
    else if ([aPushScreen caseInsensitiveCompare:kDeepLinkGenreScreenValue] == NSOrderedSame)
    {
        if (aShowId != nil)
        {
            if (aVideoId != nil)
            {
                [self navigateToShowScreenWithChannelId:aShowId withVideoId:aVideoId];
            }
            else
            {
                //play the first video
                [self navigateToShowScreenWithChannelId:aShowId withVideoId:@"0"];
            }
        }
        else
        {
            [self navigateToDeeplinkGenreScreen];
        }
    }
}
- (void)navigateToDeeplinkPlayListScreen
{
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        if (tabBarCntlr.selectedIndex != 0)
        {
            tabBarCntlr.selectedIndex = 0;
        }

        UINavigationController *playListNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:0];

        NSArray *aPlayListStackControllers = playListNavigationStack.viewControllers;

        if (aPlayListStackControllers.count > 1)
        {
            [playListNavigationStack popToRootViewControllerAnimated:NO];
        }
    }
    else
    {
        // navigate as guest user
        [self allowDeeplinkAsGuestUser];
        [self performSelector:@selector(navigateToDeeplinkPlayListScreen) withObject:nil afterDelay:0.01];
    }
}

- (void)navigateToDeeplinkGenreScreen
{
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        if (tabBarCntlr.selectedIndex != 1)
        {
            tabBarCntlr.selectedIndex = 1;
        }

        UINavigationController *aGenreNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:1];

        NSArray *aGenreNavigationStackControllers = aGenreNavigationStack.viewControllers;

        if (aGenreNavigationStackControllers.count > 1)
        {
            [aGenreNavigationStack popToRootViewControllerAnimated:NO];
        }
    }
    else
    {
        // navigate as guest user
        [self allowDeeplinkAsGuestUser];
        [self performSelector:@selector(navigateToDeeplinkGenreScreen) withObject:nil afterDelay:0.01];
    }
}

- (void)navigateToDeeplinkMyShowsScreen
{
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        if (tabBarCntlr.selectedIndex != 2)
        {
            tabBarCntlr.selectedIndex = 2;
        }

        UINavigationController *aMyShowNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:2];

        NSArray *aMyShowNavigationStackControllers = aMyShowNavigationStack.viewControllers;

        if (aMyShowNavigationStackControllers.count > 1)
        {
            [aMyShowNavigationStack popToRootViewControllerAnimated:NO];
        }
    }
    else
    {
        // navigate as guest user
        [self allowDeeplinkAsGuestUser];
        [self performSelector:@selector(navigateToDeeplinkMyShowsScreen) withObject:nil afterDelay:0.01];
    }
}

- (void)navigateToPlayDetailScreenWithPlayListId:(NSString *)aPlayListId withVideoId:(NSString *)aVideoId
{
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        if (tabBarCntlr.selectedIndex != 0)
        {
            tabBarCntlr.selectedIndex = 0;
        }

        UINavigationController *playListNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:0];

        NSArray *aPlayListStackControllers = playListNavigationStack.viewControllers;

        if (aPlayListStackControllers.count)
        {
            PlayListViewController *aPlayListViewController = (PlayListViewController *)[aPlayListStackControllers objectAtIndex:0];

            if ([aPlayListViewController isPlayListDataSourceAvaliable])
            {
                NSUInteger aIndex = [aPlayListViewController getDataSourcePlayListIdIndex:aPlayListId];
                if (aIndex == -1)
                {
                    //data is not available
                    //refresh
                    [aPlayListViewController pushPlaydetailControllerWithIndex:-1 withPlayListId:aPlayListId withVideoId:aVideoId withDelay:0.0];
                }
                else
                {
                    //data available in index = aindex
                    if (aPlayListStackControllers.count > 1)
                    {
                        PlayDetailViewController *aPlayDetailViewController = (PlayDetailViewController *)[aPlayListStackControllers objectAtIndex:1];
                        aPlayDetailViewController.isFetchPlayBackURIWithMaxBitRate = YES;
                        if ([aPlayDetailViewController isPlayListVideoListDataSourceAvaliable] && [aPlayDetailViewController.mDataModel.uniqueId isEqualToString:aPlayListId])
                        {
                            if ([aVideoId isEqualToString:@"0"])
                            {
                                [aPlayDetailViewController setPreviousSelectedIndex:[NSIndexPath indexPathForItem:0 inSection:0]];

                                [playListNavigationStack popToViewController:aPlayDetailViewController animated:NO];

                                return;
                            }
                            NSUInteger aVideoIndex = [aPlayDetailViewController getDataSourceVideoIdIndex:aVideoId];

                            if (aVideoIndex == -1)
                            {
                                //data is not available
                                //remove this and push the play detail
                                //[playListNavigationStack popToRootViewControllerAnimated:NO];
                                [aPlayListViewController pushPlaydetailControllerWithIndex:aIndex withPlayListId:aPlayListId withVideoId:aVideoId withDelay:0.0];
                            }
                            else
                            {
                                // check the stack having more than 2 controller

                                [aPlayDetailViewController setPreviousSelectedIndex:[NSIndexPath indexPathForItem:aVideoIndex inSection:0]];

                                [playListNavigationStack popToViewController:aPlayDetailViewController animated:NO];

                                //play the selected video
                            }
                        }
                        else
                        {
                            [aPlayListViewController pushPlaydetailControllerWithIndex:aIndex withPlayListId:aPlayListId withVideoId:aVideoId withDelay:0.0];
                        }
                    }
                    else
                    {
                        [aPlayListViewController pushPlaydetailControllerWithIndex:aIndex withPlayListId:aPlayListId withVideoId:aVideoId withDelay:0.0];
                    }
                }
            }
            else
            {
                [aPlayListViewController pushPlaydetailControllerWithIndex:-1 withPlayListId:aPlayListId withVideoId:aVideoId withDelay:0.0];
            }
        }
    }
    else
    {
        [self allowDeeplinkAsGuestUser];
        // navigate as guest user
        NSMutableDictionary *aDict = [[NSMutableDictionary alloc] init];
        if (aPlayListId.length)
        {
            [aDict setObject:aPlayListId forKey:kDeepLinkPlayListIdKey];
        }
        if (aVideoId.length)
        {
            [aDict setObject:aVideoId forKey:kDeepLinkVideoIdKey];
        }
        [self performSelector:@selector(navigateToDeepLinkingPlayListWithVideoScreen:) withObject:aDict afterDelay:0.01];
    }
}

- (void)navigateToDeepLinkingPlayListWithVideoScreen:(NSDictionary *)aDict
{
    NSString *aPlayListId = [aDict objectForKey:kDeepLinkPlayListIdKey];
    NSString *aVideoId = [aDict objectForKey:kDeepLinkVideoIdKey];

    if (aPlayListId != nil)
    {
        if (aVideoId != nil)
        {
            [self navigateToPlayDetailScreenWithPlayListId:aPlayListId withVideoId:aVideoId];
        }
        else
        {
            [self navigateToPlayDetailScreenWithPlayListId:aPlayListId withVideoId:@"0"];
        }
    }
}

//isFetchPlayBackURIWithMaxBitRate

- (void)navigateToShowScreenWithChannelId:(NSString *)aChannelId withVideoId:(NSString *)aVideoId
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    PlayDetailViewController *aPlayListDetailViewController = nil;
    NSUInteger aVideoIndex = 0;
    UITabBarController *tabBarCntlr = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr;
    if (tabBarCntlr)
    {
        if (tabBarCntlr.selectedIndex != 1)
        {
            tabBarCntlr.selectedIndex = 1;
        }

        UINavigationController *GenreNavigationStack = (UINavigationController *)[tabBarCntlr.viewControllers objectAtIndex:1];

        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:GenreNavigationStack.viewControllers];

        // Find the things to remove
        NSMutableArray *toDelete = [NSMutableArray array];

        for (int aCount = 0; aCount < viewControllers.count; aCount++)
        {
            UIViewController *objVC = (UIViewController *)[viewControllers objectAtIndex:aCount];

            if (aPlayListDetailViewController == nil)
            {
                if ([objVC isKindOfClass:[PlayDetailViewController class]])
                {
                    PlayDetailViewController *aPlayDetailVC = (PlayDetailViewController *)objVC;
                    if ([aPlayDetailVC.mChannelDataModel.uniqueId isEqualToString:aChannelId] && [aPlayDetailVC isChannelVideoListDataSourceAvaliable])
                    {
                        if ([aVideoId isEqualToString:@"0"])
                        {
                            aVideoIndex = 0;
                            aPlayListDetailViewController = aPlayDetailVC;
                        }
                        else
                        {
                            NSUInteger VideoIndex = [aPlayDetailVC getDataSourceVideoIdIndex:aVideoId];
                            if (aVideoIndex != -1)
                            {
                                aVideoIndex = VideoIndex;
                                aPlayListDetailViewController = aPlayDetailVC;
                            }
                        }
                    }
                    else
                    {
                        [toDelete addObject:objVC];
                    }
                }
                else
                {
                    [toDelete addObject:objVC];
                }
            }
            else
            {
                [toDelete addObject:objVC];
            }
        }
        [viewControllers removeObjectsInArray:toDelete];

        BOOL isShowDetailScreenFound = NO;
        if (aPlayListDetailViewController == nil)
        {
            aPlayListDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PlayDetailViewController"];
            [viewControllers addObject:aPlayListDetailViewController];
        }
        else
        {
            isShowDetailScreenFound = YES;
        }

        aPlayListDetailViewController.deeplinkShowId = aChannelId;
        aPlayListDetailViewController.isFromGenre = YES;
        aPlayListDetailViewController.deeplinkVideoId = aVideoId;
        aPlayListDetailViewController.isPlayVideoForDeeplink = YES;
        aPlayListDetailViewController.isFetchPlayBackURIWithMaxBitRate = YES;

        [GenreNavigationStack setViewControllers:viewControllers animated:NO];

        if (isShowDetailScreenFound)
        {
            [aPlayListDetailViewController removeBackButtonForController];
            [aPlayListDetailViewController setPreviousSelectedIndex:[NSIndexPath indexPathForItem:aVideoIndex inSection:0]];
        }
    }
    else
    {
        [self allowDeeplinkAsGuestUser];
        // navigate as guest user
        NSMutableDictionary *aDict = [[NSMutableDictionary alloc] init];
        if (aChannelId.length)
        {
            [aDict setObject:aChannelId forKey:kDeepLinkShowIdKey];
        }
        if (aVideoId.length)
        {
            [aDict setObject:aVideoId forKey:kDeepLinkVideoIdKey];
        }
        [self performSelector:@selector(navigateToDeepLinkingShowWithVideoScreen:) withObject:aDict afterDelay:0.01];
    }
}

- (void)navigateToDeepLinkingShowWithVideoScreen:(NSDictionary *)aDict
{
    NSString *aShowId = [aDict objectForKey:kDeepLinkShowIdKey];
    NSString *aVideoId = [aDict objectForKey:kDeepLinkVideoIdKey];

    if (aShowId != nil)
    {
        if (aVideoId != nil)
        {
            [self navigateToShowScreenWithChannelId:aShowId withVideoId:aVideoId];
        }
        else
        {
            [self navigateToShowScreenWithChannelId:aShowId withVideoId:@"0"];
        }
    }
}

- (void)allowDeeplinkAsGuestUser
{
    [kSharedApplicationDelegate setTabBarForGuestUserWithTutorialOverLay:NO];
}

@end
