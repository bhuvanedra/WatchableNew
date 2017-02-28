//
//  PlaylistModel.m
//  Watchable
//
//  Created by Gudkesh on 21/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PlaylistModel.h"

@implementation PlaylistModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }
    [self setValueForUrls:[aData objectForKey:@"links"]];
    self.genreTitle = [aData objectForKey:@"genre"];
    self.shortDescription = [aData objectForKey:@"description"];
    self.title = [aData objectForKey:@"title"];
    self.uniqueId = [aData objectForKey:@"id"];
    self.totalVideos = [aData objectForKey:@"totalVideos"];
    self.totalVideoDuration = [aData objectForKey:@"totalVideoDuration"];
    self.relatedLinks = [aData objectForKey:@"links"];

    return self;
}

- (void)setValueForUrls:(NSDictionary *)aData
{
    if (![[aData objectForKey:@"imageUri"] isKindOfClass:[NSNull class]])
    {
        self.imageUri = [aData objectForKey:@"imageUri"];
    }

    self.videoListUrl = [aData objectForKey:@"self"];
}

@end
