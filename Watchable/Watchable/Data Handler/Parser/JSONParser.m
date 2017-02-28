//
//  JSONParser.m
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "JSONParser.h"
#import "ShowModel.h"
#import "VideoModel.h"
#import "WatchableConstants.h"
#import "GenreModel.h"
#import "ChannelModel.h"
#import "ProviderModel.h"
#import "PlaylistModel.h"
#import "SearchResultModel.h"
#import "HistoryModel.h"
@implementation JSONParser

+ (NSArray *)parseDataForHistoryMetaData:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        NSArray *aArray = [aDict objectForKey:@"items"];

        aResponseArray = [[NSMutableArray alloc] init];
        for (NSDictionary *aDict in aArray)
        {
            HistoryModel *aModel = [[HistoryModel alloc] initWithJSONData:aDict];
            [aResponseArray addObject:aModel];
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForPlayList:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kCuratedItemsKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                ShowModel *aModel = [[ShowModel alloc] initWithJSONData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
        else if ([responseData isKindOfClass:[NSDictionary class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];

            ShowModel *aModel = [[ShowModel alloc] initWithJSONData:(NSDictionary *)responseData];
            [aResponseArray addObject:aModel];
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForCuratedPlayList:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kCuratedItemsKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                PlaylistModel *aModel = [[PlaylistModel alloc] initWithJSONData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
        else if ([responseData isKindOfClass:[NSDictionary class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];

            PlaylistModel *aModel = [[PlaylistModel alloc] initWithJSONData:(NSDictionary *)responseData];
            [aResponseArray addObject:aModel];
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForChannels:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kItemKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                ChannelModel *aModel = [[ChannelModel alloc] initWithJSONData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
        else if ([responseData isKindOfClass:[NSDictionary class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];

            ChannelModel *aModel = [[ChannelModel alloc] initWithJSONData:(NSDictionary *)responseData];
            [aResponseArray addObject:aModel];
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForFeaturedChannels:(NSDictionary *)aDict withTitle:(NSString **)aTitleStr
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        NSString *aStr = [aDict objectForKey:@"title"];
        *aTitleStr = aStr;
        id responseData = [aDict objectForKey:kCuratedItemsKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                NSDictionary *aChannelDict = [aDict objectForKey:@"channel"];
                if (aChannelDict)
                {
                    ChannelModel *aModel = [[ChannelModel alloc] initWithJSONData:aChannelDict];
                    [aResponseArray addObject:aModel];
                }
            }
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForProvider:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = aDict;
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                ProviderModel *aModel = [[ProviderModel alloc] initWithJSONData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
        else if ([responseData isKindOfClass:[NSDictionary class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];

            ProviderModel *aModel = [[ProviderModel alloc] initWithJSONData:aDict];
            [aResponseArray addObject:aModel];
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForVideoList:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kCuratedItemsKey];
        NSString *playListShareLink = nil;
        if ([aDict objectForKey:@"links"])
        {
            NSDictionary *aLinkDict = [aDict objectForKey:@"links"];
            if ([aLinkDict objectForKey:@"sharelink"])
            {
                playListShareLink = [aLinkDict objectForKey:@"sharelink"];
            }
        }
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                VideoModel *aModel = [[VideoModel alloc] initWithJSONData:aDict];
                aModel.playListSharingUrl = playListShareLink;
                [aResponseArray addObject:aModel];
            }
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForVideoList:(NSDictionary *)aDict withPlayListModel:(PlaylistModel *)aPlayListModelPtr
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        PlaylistModel *aPlayListModel = aPlayListModelPtr;

        aPlayListModel.genreTitle = [aDict objectForKey:@"genre"];
        aPlayListModel.shortDescription = [aDict objectForKey:@"description"];
        aPlayListModel.title = [aDict objectForKey:@"title"];
        aPlayListModel.totalVideos = [aDict objectForKey:@"totalVideos"];
        aPlayListModel.totalVideoDuration = [aDict objectForKey:@"totalVideoDuration"];
        aPlayListModel.relatedLinks = [aDict objectForKey:@"links"];

        if (![[aPlayListModel.relatedLinks objectForKey:@"imageUri"] isKindOfClass:[NSNull class]])
        {
            aPlayListModel.imageUri = [aPlayListModel.relatedLinks objectForKey:@"imageUri"];
        }

        aPlayListModel.videoListUrl = [aPlayListModel.relatedLinks objectForKey:@"self"];

        if (!(aPlayListModel.genreTitle || aPlayListModel.shortDescription || aPlayListModel.title || aPlayListModel.totalVideos || aPlayListModel.totalVideoDuration || aPlayListModel.relatedLinks || aPlayListModel.videoListUrl))
        {
            aPlayListModel.uniqueId = nil;
        }

        id responseData = [aDict objectForKey:kCuratedItemsKey];
        NSString *playListShareLink = nil;
        if ([aDict objectForKey:@"links"])
        {
            NSDictionary *aLinkDict = [aDict objectForKey:@"links"];
            if ([aLinkDict objectForKey:@"sharelink"])
            {
                playListShareLink = [aLinkDict objectForKey:@"sharelink"];
            }
        }
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                VideoModel *aModel = [[VideoModel alloc] initWithJSONData:aDict];
                aModel.playListSharingUrl = playListShareLink;
                [aResponseArray addObject:aModel];
            }
        }
    }
    else
    {
        PlaylistModel *aPlayListModel = aPlayListModelPtr;
        aPlayListModel.uniqueId = nil;
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForChannelVideoList:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kItemKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                VideoModel *aModel = [[VideoModel alloc] initVideoUnderChannelFromJsonData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
    }
    return aResponseArray;
}

+ (VideoModel *)parseDataForNextVideoUnderChannel:(NSDictionary *)aDict
{
    VideoModel *aModel = [[VideoModel alloc] initNextVideoUnderChannelFromJsonData:aDict];
    return aModel;
}

+ (NSArray *)parseDataForGenre:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = nil;
    if (aDict)
    {
        id responseData = [aDict objectForKey:kItemKey];
        if ([responseData isKindOfClass:[NSArray class]])
        {
            aResponseArray = [[NSMutableArray alloc] init];
            for (NSDictionary *aDict in responseData)
            {
                GenreModel *aModel = [[GenreModel alloc] initWithJSONData:aDict];
                [aResponseArray addObject:aModel];
            }
        }
    }
    return aResponseArray;
}

+ (NSArray *)parseDataForGenreForChannels:(NSDictionary *)aDict
{
    NSMutableArray *aResponseArray = [[NSMutableArray alloc] init];
    if (aDict)
    {
        GenreModel *aModel = [[GenreModel alloc] initWithJSONData:aDict];
        [aResponseArray addObject:aModel];
    }
    return aResponseArray;
}

// Method to parse data for search result

+ (NSDictionary *)parseDataForSearchResult:(NSDictionary *)aDict
{
    id responseData = [aDict objectForKey:kItemKey];
    NSDictionary *dictionary = [SearchResultModel getSearchResultWithJSONData:responseData];
    return dictionary;
}

@end
