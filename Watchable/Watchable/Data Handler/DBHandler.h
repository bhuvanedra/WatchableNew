//
//  DBHandler.h
//  Watchable
//
//  Created by Raja Indirajith on 29/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
@class VideoModel;
@class UserProfile;
@interface DBHandler : NSObject

+ (DBHandler *)sharedInstance;
- (void)createUserProfileEntityInDB:(NSDictionary *)aUserProfileDict;
- (void)setVideoModelForHistoryAsset:(VideoModel *)aVideoModel;
- (void)createHistoryEntityForLoggedInUser:(NSArray *)aHistoryModelList;
- (BOOL)canRefreshHistory;

- (void)deleteHistoryAssestForId:(NSString *)aVideoId;
- (void)deleteAllHistoryAssestsForCurrentLoggedInUser;
- (NSArray *)getAllHistoryModelsForLoggedInUser;
- (NSDate *)getLastHistorySyncedDate;
- (void)updateLoginUserProfileWithUsername:(NSString *)aUserName andWithEmailId:(NSString *)aEmailId;
- (void)updateOrInsertHistoryAsset:(VideoModel *)aVideoModel withVideoProgressTime:(NSString *)aString withUpdatedTimeStamp:(NSNumber *)aTimeStamp;
- (UserProfile *)getCurrentLoggedInUserProfile;
- (void)deleteUserProfileFromDB;
- (NSString *)getShortShareUrlForKey:(NSString *)aKey withLongUrl:(NSString *)aLongUrl;
- (void)setShortShareUrlForKey:(NSString *)aKey withLongUrl:(NSString *)aLongUrl withValue:(NSString *)aShortUrl;
//+(NSManagedObjectContext*)getCurrentManagedObjectContext;
@end
