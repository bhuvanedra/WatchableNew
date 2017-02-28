//
//  HistoryModel.h
//  Watchable
//
//  Created by Raja Indirajith on 29/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
@class VideoModel;
@interface HistoryModel : NSObject

@property (strong, nonatomic) NSString *mVideoId;
@property (strong, nonatomic) NSString *mShowId;
@property (strong, nonatomic) NSString *mChannelId;
@property (strong, nonatomic) NSString *mType;
@property (strong, nonatomic) NSString *mVideoDuration;
@property (strong, nonatomic) NSString *mProgressPosition;
@property (strong, nonatomic) NSNumber *mTimeStamp;
@property (strong, nonatomic) VideoModel *mVideoModel;
- (id)initWithJSONData:(NSDictionary *)aData;
@end
