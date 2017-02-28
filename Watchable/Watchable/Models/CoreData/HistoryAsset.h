//
//  HistoryAsset.h
//  Watchable
//
//  Created by Raja Indirajith on 04/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserProfile, Video;

@interface HistoryAsset : NSManagedObject

@property (nonatomic, retain) NSString *mChannelId;
@property (nonatomic, retain) NSString *mProgressPosition;
@property (nonatomic, retain) NSString *mShowId;
@property (nonatomic, retain) NSNumber *mTimeStamp;
@property (nonatomic, retain) NSString *mType;
@property (nonatomic, retain) NSString *mVideoDuration;
@property (nonatomic, retain) NSString *mVideoId;
@property (nonatomic, retain) UserProfile *mUserProfile;
@property (nonatomic, retain) Video *mVideoModel;

@end
