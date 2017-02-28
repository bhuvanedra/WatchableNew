//
//  SearchResultModel.m
//  Watchable
//
//  Created by valtech on 14/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "SearchResultModel.h"
#import "ChannelModel.h"
#import "VideoModel.h"

@implementation SearchResultModel

+ (NSDictionary *)getSearchResultWithJSONData:(NSArray *)aArray
{
    NSMutableArray *channelsArray = [NSMutableArray new];
    NSMutableArray *videosArray = [NSMutableArray new];

    for (NSDictionary *aDict in aArray)
    {
        NSString *type = [aDict objectForKey:@"type"];

        if ([type caseInsensitiveCompare:@"channel"] == NSOrderedSame && type != nil)
        {
            ChannelModel *model = [[ChannelModel alloc] initWithJSONData:aDict];
            [channelsArray addObject:model];
        }
        else if ([type caseInsensitiveCompare:@"video"] == NSOrderedSame && type != nil)

        {
            VideoModel *model = [[VideoModel alloc] initVideoUnderChannelFromJsonData:aDict];
            [videosArray addObject:model];
        }
    }

    return @{ @"Channels" : channelsArray,
              @"Videos" : videosArray };
}

@end
