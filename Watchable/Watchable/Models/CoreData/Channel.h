//
//  Channel.h
//  Watchable
//
//  Created by Valtech on 22/07/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface Channel : NSManagedObject

@property (nonatomic, retain) NSString *uniqueId;
@property (nonatomic, retain) NSString *imageUri;
@property (nonatomic, retain) NSString *numOfVideos;
@property (nonatomic, retain) NSString *parentalGuidance;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *channelTitle;
@property (nonatomic, retain) NSString *showDescription;
@property (nonatomic, retain) NSString *lastUpdateTimestamp;
@property (nonatomic, retain) NSDictionary *relatedLinks;
@property (nonatomic, retain) NSNumber *isChannelFollowing;
@property (nonatomic, retain) NSSet *videos;
@end

@interface Channel (CoreDataGeneratedAccessors)

- (void)addVideosObject:(Video *)value;
- (void)removeVideosObject:(Video *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
