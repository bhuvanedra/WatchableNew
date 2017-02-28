//
//  ProviderModel.m
//  Watchable
//
//  Created by Valtech on 3/16/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ProviderModel.h"

@implementation ProviderModel

- (id)initWithJSONData:(NSDictionary *)aData
{
    if (self == nil)
    {
        self = [super init];
    }

    [self setPublisherDetails:aData];

    return self;
}

- (void)setPublisherDetails:(NSDictionary *)aData
{
    self.title = [aData objectForKey:@"name"];
    self.uniqueId = [aData objectForKey:@"id"];
    self.linksDict = [aData objectForKey:@"links"];
}

@end
