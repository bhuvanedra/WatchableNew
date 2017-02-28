//
//  ChannelModel.h
//  Watchable
//
//  Created by Valtech on 3/10/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoModel.h"

@interface ChannelModel : NSObject

@property (nonatomic, strong) NSString *uniqueId;
@property (nonatomic, strong) NSString *imageUri;
@property (nonatomic, strong) NSString *numOfVideos;
@property (nonatomic, strong) NSString *parentalGuidance;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *channelTitle;
@property (nonatomic, strong) NSString *showDescription;
@property (nonatomic, strong) NSString *lastUpdateTimestamp;
@property (nonatomic, strong) NSDictionary *relatedLinks;
@property (nonatomic, assign) BOOL isChannelFollowing;
@property (nonatomic, strong) VideoModel *nextVideoUnderchannel;
- (id)initWithJSONData:(NSDictionary *)aData;

@end
