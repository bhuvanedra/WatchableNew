//
//  UserProfile.h
//  Watchable
//
//  Created by Raja Indirajith on 02/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HistoryAsset;

@interface UserProfile : NSManagedObject

@property (nonatomic, retain) NSString *mLastHistorySyncTime;
@property (nonatomic, retain) NSString *mUserEmail;
@property (nonatomic, retain) NSString *mUserId;
@property (nonatomic, retain) NSString *mUserName;
@property (nonatomic, retain) NSSet *mWatchHistoryList;
@end

@interface UserProfile (CoreDataGeneratedAccessors)

- (void)addMWatchHistoryListObject:(HistoryAsset *)value;
- (void)removeMWatchHistoryListObject:(HistoryAsset *)value;
- (void)addMWatchHistoryList:(NSSet *)values;
- (void)removeMWatchHistoryList:(NSSet *)values;

@end
