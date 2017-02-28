//
//  DataConverter.m
//  Watchable
//
//  Created by Raja Indirajith on 03/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "DataConverter.h"
#import "HistoryAsset.h"
#import "HistoryModel.h"
#import "Video.h"
#import "VideoModel.h"
#import "Channel.h"
#import "ChannelModel.h"
@implementation DataConverter

- (NSArray *)convertHistoryAssetListToHistoryModelArray:(NSArray *)aHistoryAssetList
{
    NSMutableArray *aHistoryModelArray = [[NSMutableArray alloc] init];
    for (HistoryAsset *aHistoryAsset in aHistoryAssetList)
    {
        HistoryModel *aHistoryModel = [[HistoryModel alloc] init];

        aHistoryModel.mChannelId = aHistoryAsset.mChannelId;
        aHistoryModel.mProgressPosition = aHistoryAsset.mProgressPosition;
        aHistoryModel.mShowId = aHistoryAsset.mShowId;
        aHistoryModel.mType = aHistoryAsset.mType;
        aHistoryModel.mVideoId = aHistoryAsset.mVideoId;
        aHistoryModel.mVideoDuration = aHistoryAsset.mVideoDuration;
        aHistoryModel.mTimeStamp = aHistoryAsset.mTimeStamp;

        if (aHistoryAsset.mVideoModel)
        {
            aHistoryModel.mVideoModel = [self convertVideoToVideoModel:aHistoryAsset.mVideoModel];
        }
        [aHistoryModelArray addObject:aHistoryModel];
    }
    return aHistoryModelArray;
}

- (VideoModel *)convertVideoToVideoModel:(Video *)aVideoEntity
{
    VideoModel *aVideoModel = [[VideoModel alloc] init];

    aVideoModel.relatedLinks = aVideoEntity.relatedLinks;
    aVideoModel.uniqueId = aVideoEntity.uniqueId;
    aVideoModel.imageUri = aVideoEntity.imageUri;
    aVideoModel.channelId = aVideoEntity.channelId;
    aVideoModel.channelTitle = aVideoEntity.channelTitle;
    aVideoModel.duration = aVideoEntity.duration;
    aVideoModel.episode = aVideoEntity.episode;
    aVideoModel.liveBroadcastTime = aVideoEntity.liveBroadcastTime;
    aVideoModel.longDescription = aVideoEntity.longDescription;
    aVideoModel.parentalGuidance = aVideoEntity.parentalGuidance;
    aVideoModel.playbackItems = aVideoEntity.playbackItems;
    aVideoModel.shortDescription = aVideoEntity.shortDesc;
    aVideoModel.showId = aVideoEntity.showId;
    aVideoModel.title = aVideoEntity.title;
    aVideoModel.type = aVideoEntity.type;
    if (aVideoEntity.channelInfo)
    {
        aVideoModel.channelInfo = [self convertChannelToChannelModel:aVideoEntity.channelInfo];
    }
    return aVideoModel;
}

- (ChannelModel *)convertChannelToChannelModel:(Channel *)aChannelEntity
{
    ChannelModel *aChannelModel = [[ChannelModel alloc] init];

    aChannelModel.uniqueId = aChannelEntity.uniqueId;
    aChannelModel.imageUri = aChannelEntity.imageUri;
    aChannelModel.numOfVideos = aChannelEntity.numOfVideos;
    aChannelModel.parentalGuidance = aChannelEntity.parentalGuidance;
    aChannelModel.title = aChannelEntity.title;
    aChannelModel.type = aChannelEntity.type;
    aChannelModel.channelTitle = aChannelEntity.channelTitle;
    aChannelModel.showDescription = aChannelEntity.showDescription;
    aChannelModel.lastUpdateTimestamp = aChannelEntity.lastUpdateTimestamp;
    aChannelModel.isChannelFollowing = aChannelEntity.isChannelFollowing.boolValue;
    aChannelModel.relatedLinks = aChannelEntity.relatedLinks;
    return aChannelModel;
}
@end
