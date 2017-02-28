//
//  PlayListModel.m
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ShowModel.h"

@implementation ShowModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }
    [self setValueForImageUri:[aData objectForKey:@"links"]];
    [self setShowDetails:[aData objectForKey:@"show"]];

    return self;
}

- (void)setValueForImageUri:(NSDictionary *)aData
{
    if (![[aData objectForKey:@"imageUri"] isKindOfClass:[NSNull class]])
    {
        self.imageUri = [aData objectForKey:@"imageUri"];
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
