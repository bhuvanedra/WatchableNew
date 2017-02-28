//
//  ChannelModel.m
//  Watchable
//
//  Created by Valtech on 3/10/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ChannelModel.h"

@implementation ChannelModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }
    [self setValueForImageUri:[aData objectForKey:@"links"]];
    [self setShowDetails:aData];

    return self;
}

- (void)setValueForImageUri:(NSDictionary *)aData
{
    if (![[aData objectForKey:@"default-image"] isKindOfClass:[NSNull class]])
    {
        self.imageUri = [aData objectForKey:@"default-image"];
    }
}

- (void)setShowDetails:(NSDictionary *)aData
{
    self.channelTitle = [aData objectForKey:@"channelTitle"];
    self.showDescription = [aData objectForKey:@"description"];
    self.uniqueId = [aData objectForKey:@"id"];
    self.lastUpdateTimestamp = [aData objectForKey:@"lastUpdateTimestamp"];
    self.numOfVideos = [aData objectForKey:@"numOfVideos"];
    self.parentalGuidance = [aData objectForKey:@"parentalGuidance"];
    self.type = [aData objectForKey:@"type"];
    self.title = [aData objectForKey:@"title"];
    self.relatedLinks = [aData objectForKey:@"links"];
}

@end
