//
//  Video.h
//  Watchable
//
//  Created by Valtech on 22/07/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString *channelId;
@property (nonatomic, retain) NSString *channelTitle;
@property (nonatomic, retain) NSString *duration;
@property (nonatomic, retain) NSString *episode;
@property (nonatomic, retain) NSString *imageUri;
@property (nonatomic, retain) NSString *liveBroadcastTime;
@property (nonatomic, retain) NSString *longDescription;
@property (nonatomic, retain) NSString *parentalGuidance;
@property (nonatomic, retain) NSArray *playbackItems;
@property (nonatomic, retain) NSDictionary *relatedLinks;
@property (nonatomic, retain) NSString *shortDesc;
@property (nonatomic, retain) NSString *showId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *uniqueId;
@property (nonatomic, retain) Channel *channelInfo;

@end
