//
//  GenreModel.m
//  Watchable
//
//  Created by Valtech on 3/10/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "GenreModel.h"

@implementation GenreModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }

    [self setValueForChannelsUri:[aData objectForKey:@"links"]];
    self.relatedLinks = [aData objectForKey:@"links"];
    self.genreId = [aData objectForKey:@"id"];
    self.genreTitle = [aData objectForKey:@"title"];
    self.totalChannels = [aData objectForKey:@"totalChannels"];

    return self;
}

- (void)setValueForChannelsUri:(NSDictionary *)aData
{
    self.allChannelsUri = [aData objectForKey:@"channels-all"];
}

@end
