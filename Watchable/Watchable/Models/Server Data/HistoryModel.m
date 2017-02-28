//
//  HistoryModel.m
//  Watchable
//
//  Created by Raja Indirajith on 29/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "HistoryModel.h"

@implementation HistoryModel

- (id)initWithJSONData:(NSDictionary *)aDict
{
    if (self == nil)
    {
        self = [super init];
    }
    self.mVideoId = [aDict objectForKey:@"id"];
    self.mChannelId = [aDict objectForKey:@"channelId"];
    self.mShowId = [aDict objectForKey:@"showId"];
    self.mType = [aDict objectForKey:@"type"];
    self.mVideoDuration = [aDict objectForKey:@"duration"];
    self.mProgressPosition = [aDict objectForKey:@"progressPosition"];
    NSNumber *aLastUpdateTimeString = [aDict objectForKey:@"lastUpdateTime"];
    if (aLastUpdateTimeString)
        self.mTimeStamp = aLastUpdateTimeString;

    return self;
}

@end
