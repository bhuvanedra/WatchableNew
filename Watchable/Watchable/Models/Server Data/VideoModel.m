//
//  VideoModel.m
//  Watchable
//
//  Created by Raja Indirajith on 21/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "VideoModel.h"

@implementation VideoModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }
    [self setValueForImageUri:[aData objectForKey:@"links"] fromKey:@"imageUri"];
    [self setVideoDetails:[aData objectForKey:@"video"]];
    [self setSharingUrlForPlayList:aData];
    return self;
}

- (void)setValueForImageUri:(NSDictionary *)aData fromKey:(NSString *)key
{
    if (![[aData objectForKey:key] isKindOfClass:[NSNull class]])
    {
        self.imageUri = [aData objectForKey:key];
    }
}

- (void)setSharingUrlForPlayList:(NSDictionary *)aData
{
}

- (void)setVideoDetails:(NSDictionary *)aData
{
    self.relatedLinks = [aData objectForKey:@"links"];
    [self setValueForImageUri:[aData objectForKey:@"links"] fromKey:@"default-image"];
    self.uniqueId = [aData objectForKey:@"id"];
    self.channelId = [aData objectForKey:@"channelId"];
    self.channelTitle = [aData objectForKey:@"channelTitle"];
    self.duration = [aData objectForKey:@"duration"];
    self.episode = [aData objectForKey:@"episode"];
    self.liveBroadcastTime = [aData objectForKey:@"liveBroadcastTime"];
    self.longDescription = [aData objectForKey:@"longDescription"];
    self.parentalGuidance = [aData objectForKey:@"parentalGuidance"];
    self.playbackItems = [aData objectForKey:@"playbackItems"];
    self.shortDescription = [aData objectForKey:@"shortDescription"];
    self.showId = [aData objectForKey:@"showId"];
    self.title = [aData objectForKey:@"title"];
    self.type = [aData objectForKey:@"type"];
}

- (id)initNextVideoUnderChannelFromJsonData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }

    [self setVideoDetails:aData];

    return self;
}

- (id)initVideoUnderChannelFromJsonData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }
    [self setValueForImageUri:[aData objectForKey:@"links"] fromKey:@"default-image"];
    [self setVideoDetails:aData];

    return self;
}

@end
