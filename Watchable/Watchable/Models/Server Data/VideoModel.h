//
//  VideoModel.h
//  Watchable
//
//  Created by Raja Indirajith on 21/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ChannelModel;

@interface VideoModel : NSObject
@property (nonatomic, strong) NSString *uniqueId;
@property (nonatomic, strong) NSString *imageUri;
@property (nonatomic, strong) NSString *channelId;
@property (nonatomic, strong) NSString *channelTitle;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *episode;
@property (nonatomic, strong) NSString *liveBroadcastTime;
@property (nonatomic, strong) NSString *longDescription;
@property (nonatomic, strong) NSString *parentalGuidance;
@property (nonatomic, strong) NSArray *playbackItems;
@property (nonatomic, strong) NSString *shortDescription;
@property (nonatomic, strong) NSString *showId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSDictionary *relatedLinks;
@property (nonatomic, assign) BOOL isVideoFollowing;
@property (nonatomic, strong) NSString *playbackURI;
@property (nonatomic, strong) NSString *playListSharingUrl;
@property (nonatomic, strong) ChannelModel *channelInfo;
@property (nonatomic, strong) NSDictionary *logData;
- (id)initWithJSONData:(NSDictionary *)aData;
- (id)initNextVideoUnderChannelFromJsonData:(NSDictionary *)aData;
- (id)initVideoUnderChannelFromJsonData:(NSDictionary *)aData;

@end
