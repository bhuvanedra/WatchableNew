//
//  DBHandler.m
//  Watchable
//
//  Created by Raja Indirajith on 29/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "DBHandler.h"
#import "AppDelegate.h"
#import "HistoryAsset.h"
#import "UserProfile.h"
#import "VideoModel.h"
#import "Video.h"
#import "HistoryModel.h"
#import "DataConverter.h"
#import "Channel.h"
#import "ChannelModel.h"
#import "ShareURL+CoreDataProperties.h"
@implementation DBHandler

+ (DBHandler *)sharedInstance
{
    static DBHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[DBHandler alloc] init];

    });
    return sharedInstance;
}

- (void)createUserProfileEntityInDB:(NSDictionary *)aUserProfileDict
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"UserProfile" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    BOOL isUserFound = NO;
    if (theUserItemObjects.count > 0)
    {
        for (UserProfile *theLoginUsr in theUserItemObjects)
        {
            if ([theLoginUsr.mUserId isEqualToString:[aUserProfileDict objectForKey:@"userId"]])
            {
                isUserFound = YES;
                theLoginUsr.mUserEmail = [aUserProfileDict objectForKey:@"email"];
                theLoginUsr.mUserId = [aUserProfileDict objectForKey:@"userId"];
                theLoginUsr.mUserName = [aUserProfileDict objectForKey:@"userName"];
                [Utilities setValueForKeyInUserDefaults:theLoginUsr.mUserId key:kUserId];
            }
            else
            {
                [aCurrentManagedObjectContext deleteObject:theLoginUsr];
            }
        }
    }

    if (!isUserFound)
    {
        UserProfile *aUserProfile = [NSEntityDescription
            insertNewObjectForEntityForName:@"UserProfile"
                     inManagedObjectContext:[self getCurrentManagedObjectContext]];
        aUserProfile.mUserEmail = [aUserProfileDict objectForKey:@"email"];
        aUserProfile.mUserId = [aUserProfileDict objectForKey:@"userId"];
        aUserProfile.mUserName = [aUserProfileDict objectForKey:@"userName"];
        [Utilities setValueForKeyInUserDefaults:aUserProfile.mUserId key:kUserId];
    }

    [aCurrentManagedObjectContext save:&theError];
}

- (void)deleteUserProfileFromDB
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"UserProfile" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    if (theUserItemObjects.count)
    {
        for (UserProfile *user in theUserItemObjects)
        {
            [aCurrentManagedObjectContext deleteObject:user];
        }
        [aCurrentManagedObjectContext save:&theError];
    }
}

- (UserProfile *)getCurrentLoggedInUserProfile
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"UserProfile" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    UserProfile *aUserProfile = nil;
    if (theUserItemObjects.count)
        aUserProfile = [theUserItemObjects objectAtIndex:0];
    return aUserProfile;
}

- (void)updateLoginUserProfileWithUsername:(NSString *)aUserName andWithEmailId:(NSString *)aEmailId
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"UserProfile" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    UserProfile *aUserProfile = [theUserItemObjects objectAtIndex:0];
    if (aUserProfile)
    {
        if (aUserName.length)
        {
            aUserProfile.mUserName = aUserName;
        }
        if (aEmailId.length)
        {
            aUserProfile.mUserEmail = aEmailId;
        }
        [aCurrentManagedObjectContext save:&theError];
    }
}

- (void)deleteUnAvaliableHistoryAssets:(NSArray *)aHistoryModelList
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];

    @synchronized(aCurrentManagedObjectContext)
    {
        // Define our table/entity to use
        NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
        // Setup the fetch request
        NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
        [theFetchRequest setEntity:theEventEntity];

        NSError *theError = nil;
        NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
        NSArray *aVideoIds = [theUserItemObjects valueForKey:@"mVideoId"];
        NSArray *aHistoryModelListVideoIds = [aHistoryModelList valueForKey:@"mVideoId"];
        NSMutableSet *aVideoIdsSet = [NSMutableSet setWithArray:aVideoIds];
        NSMutableSet *aHistoryModelListVideoIdsSet = [NSMutableSet setWithArray:aHistoryModelListVideoIds];
        [aVideoIdsSet minusSet:aHistoryModelListVideoIdsSet];

        NSMutableArray *HistoryAssestToDelete = [[theUserItemObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(mVideoId IN %@)", aVideoIdsSet.allObjects]] mutableCopy];

        for (HistoryAsset *aHistoryAsset in HistoryAssestToDelete)
        {
            [aCurrentManagedObjectContext deleteObject:aHistoryAsset];
        }
        [aCurrentManagedObjectContext save:&theError];
    }
}
- (void)createHistoryEntityForLoggedInUser:(NSArray *)aHistoryModelList
{
    [self deleteUnAvaliableHistoryAssets:aHistoryModelList];
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    @synchronized(aCurrentManagedObjectContext)
    {
        NSError *aError = nil;
        UserProfile *aCurrentLoggedInUserProfile = [self getCurrentLoggedInUserProfile];
        for (HistoryModel *aHistoryModel in aHistoryModelList)
        {
            NSString *aVideoId = aHistoryModel.mVideoId;

            // Define our table/entity to use
            NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
            // Setup the fetch request
            NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
            [theFetchRequest setEntity:theEventEntity];
            [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mVideoId == %@", aVideoId]];

            NSError *theError = nil;
            NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
            if (theUserItemObjects.count)
            {
                HistoryAsset *aHistoryAsset = [theUserItemObjects objectAtIndex:0];
                [self assignHistoryAssetParameterForHistoryEntity:aHistoryAsset withHistoryModel:aHistoryModel];

                //update history entity
            }
            else
            {
                HistoryAsset *aHistoryAsset = [self createHistoryModelEntity];
                //insert new history entity
                [self assignHistoryAssetParameterForHistoryEntity:aHistoryAsset withHistoryModel:aHistoryModel];

                [aCurrentLoggedInUserProfile addMWatchHistoryListObject:aHistoryAsset];
            }
        }
        NSDate *aDate = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:kYearToSecondsDataFormate];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        NSString *formattedDateString = [dateFormatter stringFromDate:aDate];
        aCurrentLoggedInUserProfile.mLastHistorySyncTime = formattedDateString;

        [aCurrentManagedObjectContext save:&aError];
    }
}

- (NSArray *)getAllHistoryModelsForLoggedInUser
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];

    NSSortDescriptor *sortByTimeStamp = [[NSSortDescriptor alloc] initWithKey:@"mTimeStamp" ascending:NO];
    [theFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByTimeStamp]];
    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
    NSArray *aHistoryModelArray = nil;
    if (theUserItemObjects.count)
    {
        DataConverter *aDataConverter = [[DataConverter alloc] init];
        aHistoryModelArray = [aDataConverter convertHistoryAssetListToHistoryModelArray:theUserItemObjects];
    }
    return aHistoryModelArray;
}

- (HistoryAsset *)createHistoryModelEntity
{
    HistoryAsset *aHistoryAsset = [NSEntityDescription
        insertNewObjectForEntityForName:@"HistoryAsset"
                 inManagedObjectContext:[self getCurrentManagedObjectContext]];

    return aHistoryAsset;
}

- (void)setVideoModelForHistoryAsset:(VideoModel *)aVideoModel
{
    @synchronized(self)
    {
        NSString *aVideoId = aVideoModel.uniqueId;
        NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
        // Define our table/entity to use
        NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
        // Setup the fetch request
        NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
        [theFetchRequest setEntity:theEventEntity];
        [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mVideoId == %@", aVideoId]];

        NSError *theError = nil;
        NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
        if (theUserItemObjects.count)
        {
            HistoryAsset *aHistoryAsset = [theUserItemObjects objectAtIndex:0];
            if (aHistoryAsset.mVideoModel)
            {
                [self assignVideoParameterForVideoEntity:aHistoryAsset.mVideoModel withVideoModel:aVideoModel];
            }
            else
            {
                aHistoryAsset.mVideoModel = [self createVideoModelEntity:aVideoModel];
            }
            [aCurrentManagedObjectContext save:&theError];
        }
    }
}

- (void)updateOrInsertHistoryAsset:(VideoModel *)aVideoModel withVideoProgressTime:(NSString *)aString withUpdatedTimeStamp:(NSNumber *)aTimeStamp
{
    UserProfile *aCurrentLoggedInUserProfile = [self getCurrentLoggedInUserProfile];
    if (!aCurrentLoggedInUserProfile)
    {
        return;
    }
    NSString *aVideoId = aVideoModel.uniqueId;
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];
    [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mVideoId == %@", aVideoId]];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
    if (theUserItemObjects.count)
    {
        HistoryAsset *aHistoryAsset = [theUserItemObjects objectAtIndex:0];
        if (aHistoryAsset.mVideoModel)
        {
            [self assignVideoParameterForVideoEntity:aHistoryAsset.mVideoModel withVideoModel:aVideoModel];
        }
        else
        {
            aHistoryAsset.mVideoModel = [self createVideoModelEntity:aVideoModel];
        }
        aHistoryAsset.mTimeStamp = aTimeStamp;
        aHistoryAsset.mProgressPosition = aString;
    }
    else
    {
        HistoryAsset *aHistoryAsset = [self createHistoryModelEntity];
        aHistoryAsset.mTimeStamp = aTimeStamp;
        aHistoryAsset.mProgressPosition = aString;
        aHistoryAsset.mVideoId = aVideoModel.uniqueId;
        aHistoryAsset.mShowId = aVideoModel.showId;
        aHistoryAsset.mChannelId = aVideoModel.channelId;
        aHistoryAsset.mVideoDuration = aVideoModel.duration;
        aHistoryAsset.mType = aVideoModel.type;
        aHistoryAsset.mVideoModel = [self createVideoModelEntity:aVideoModel];

        UserProfile *aCurrentLoggedInUserProfile = [self getCurrentLoggedInUserProfile];
        [aCurrentLoggedInUserProfile addMWatchHistoryListObject:aHistoryAsset];
    }
    [aCurrentManagedObjectContext save:&theError];
}

- (Video *)createVideoModelEntity:(VideoModel *)aVideoModel
{
    Video *aVideo = [NSEntityDescription
        insertNewObjectForEntityForName:@"Video"
                 inManagedObjectContext:[self getCurrentManagedObjectContext]];
    [self assignVideoParameterForVideoEntity:aVideo withVideoModel:aVideoModel];

    return aVideo;
}

- (Channel *)createChannelModelEntity:(ChannelModel *)aChannelModel
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"Channel" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];
    [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uniqueId == %@", aChannelModel.uniqueId]];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    Channel *aChannel = nil;
    if (theUserItemObjects.count)
    {
        aChannel = [theUserItemObjects objectAtIndex:0];
    }
    if (!aChannel)
    {
        aChannel = [NSEntityDescription
            insertNewObjectForEntityForName:@"Channel"
                     inManagedObjectContext:[self getCurrentManagedObjectContext]];
        [self assignChannelParameterForChannelEntity:aChannel withChannelModel:aChannelModel];
    }
    return aChannel;
}

- (void)assignChannelParameterForChannelEntity:(Channel *)aChannelEntity withChannelModel:(ChannelModel *)aChannelModel
{
    aChannelEntity.uniqueId = aChannelModel.uniqueId;
    aChannelEntity.imageUri = aChannelModel.imageUri;
    aChannelEntity.numOfVideos = aChannelModel.numOfVideos;
    aChannelEntity.parentalGuidance = aChannelModel.parentalGuidance;
    aChannelEntity.title = aChannelModel.title;
    aChannelEntity.type = aChannelModel.type;
    aChannelEntity.channelTitle = aChannelModel.channelTitle;
    aChannelEntity.showDescription = aChannelModel.showDescription;
    aChannelEntity.lastUpdateTimestamp = aChannelModel.lastUpdateTimestamp;
    aChannelEntity.isChannelFollowing = [NSNumber numberWithBool:aChannelModel.isChannelFollowing];
    aChannelEntity.relatedLinks = aChannelModel.relatedLinks;
}
- (void)assignHistoryAssetParameterForHistoryEntity:(HistoryAsset *)aHistoryAsset withHistoryModel:(HistoryModel *)aHistoryModel
{
    aHistoryAsset.mChannelId = aHistoryModel.mChannelId;
    aHistoryAsset.mProgressPosition = aHistoryModel.mProgressPosition;
    aHistoryAsset.mShowId = aHistoryModel.mShowId;
    aHistoryAsset.mType = aHistoryModel.mType;
    aHistoryAsset.mVideoId = aHistoryModel.mVideoId;
    aHistoryAsset.mVideoDuration = aHistoryModel.mVideoDuration;
    aHistoryAsset.mTimeStamp = aHistoryModel.mTimeStamp;
}

- (void)assignVideoParameterForVideoEntity:(Video *)aVideoEntity withVideoModel:(VideoModel *)aVideoModel
{
    aVideoEntity.relatedLinks = aVideoModel.relatedLinks;
    aVideoEntity.uniqueId = aVideoModel.uniqueId;
    aVideoEntity.imageUri = aVideoModel.imageUri;
    aVideoEntity.channelId = aVideoModel.channelId;
    aVideoEntity.channelTitle = aVideoModel.channelTitle;
    aVideoEntity.duration = aVideoModel.duration;
    aVideoEntity.episode = aVideoModel.episode;
    aVideoEntity.liveBroadcastTime = aVideoModel.liveBroadcastTime;
    aVideoEntity.longDescription = aVideoModel.longDescription;
    aVideoEntity.parentalGuidance = aVideoModel.parentalGuidance;
    aVideoEntity.playbackItems = aVideoModel.playbackItems;
    aVideoEntity.shortDesc = aVideoModel.shortDescription;
    aVideoEntity.showId = aVideoModel.showId;
    aVideoEntity.title = aVideoModel.title;
    aVideoEntity.type = aVideoModel.type;

    if (aVideoModel.channelInfo)
    {
        Channel *aChannelEntity = [self createChannelModelEntity:aVideoModel.channelInfo];
        aVideoEntity.channelInfo = aChannelEntity;
    }
}

- (void)deleteHistoryAssestForId:(NSString *)aVideoId
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"HistoryAsset" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];
    [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"mVideoId == %@", aVideoId]];

    NSError *theError = nil;
    NSArray *theUserItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];
    if (theUserItemObjects.count)
    {
        HistoryAsset *aHistoryAsset = [theUserItemObjects objectAtIndex:0];
        [aCurrentManagedObjectContext deleteObject:aHistoryAsset];
        [aCurrentManagedObjectContext save:&theError];
    }
}

- (void)deleteAllHistoryAssestsForCurrentLoggedInUser
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    NSError *theError = nil;
    UserProfile *aCurrentLoggedInUserProfile = [self getCurrentLoggedInUserProfile];
    NSSet *aWatctHistoryList = aCurrentLoggedInUserProfile.mWatchHistoryList;
    for (HistoryAsset *aHistoryAsset in aWatctHistoryList)
    {
        [aCurrentManagedObjectContext deleteObject:aHistoryAsset];
    }
    [aCurrentManagedObjectContext save:&theError];
    //    [aCurrentLoggedInUserProfile removeMWatchHistoryList:aWatctHistoryList];
    //   BOOL isSaved= [aCurrentManagedObjectContext save:&theError];
}

- (NSManagedObjectContext *)getCurrentManagedObjectContext
{
    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return aAppDelegate.managedObjectContext;
}

- (NSDate *)getLastHistorySyncedDate
{
    NSDate *aLastSyncedDate = nil;
    UserProfile *aUserProfile = [self getCurrentLoggedInUserProfile];
    if (aUserProfile.mLastHistorySyncTime)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:kYearToSecondsDataFormate];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        aLastSyncedDate = [dateFormatter dateFromString:aUserProfile.mLastHistorySyncTime];
    }
    return aLastSyncedDate;
}
- (BOOL)canRefreshHistory
{
    BOOL canRefresh = YES;
    UserProfile *aUserProfile = [self getCurrentLoggedInUserProfile];
    if (aUserProfile.mLastHistorySyncTime)
    {
        NSDate *aCurrentDate = [NSDate date];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:kYearToSecondsDataFormate];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        NSDate *aLastSyncedDate = [dateFormatter dateFromString:aUserProfile.mLastHistorySyncTime];

        NSTimeInterval aTimeDifference = [aCurrentDate timeIntervalSinceDate:aLastSyncedDate];
        if (aTimeDifference < kHistoryPullToRefreshTimeInterval)
        {
            canRefresh = NO;
        }
    }
    return canRefresh;
}

#pragma mark Sharing methods

- (NSString *)getShortShareUrlForKey:(NSString *)aKey withLongUrl:(NSString *)aLongUrl
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    // Define our table/entity to use
    NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"ShareURL" inManagedObjectContext:aCurrentManagedObjectContext];
    // Setup the fetch request
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    [theFetchRequest setEntity:theEventEntity];
    [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uniqueId == %@ AND longUrl == %@ ", aKey, aLongUrl]];

    NSError *theError = nil;
    NSArray *theShareURLItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

    NSString *aShortUrl = nil;
    if (theShareURLItemObjects.count)
    {
        ShareURL *aShareURLModel = (ShareURL *)[theShareURLItemObjects objectAtIndex:0];
        aShortUrl = aShareURLModel.shortUrl;
    }
    return aShortUrl;
}

- (void)setShortShareUrlForKey:(NSString *)aKey withLongUrl:(NSString *)aLongUrl withValue:(NSString *)aShortUrl
{
    NSManagedObjectContext *aCurrentManagedObjectContext = [self getCurrentManagedObjectContext];
    @synchronized(aCurrentManagedObjectContext)
    {
        // Define our table/entity to use
        NSEntityDescription *theEventEntity = [NSEntityDescription entityForName:@"ShareURL" inManagedObjectContext:aCurrentManagedObjectContext];
        // Setup the fetch request
        NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
        [theFetchRequest setEntity:theEventEntity];
        [theFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uniqueId == %@ AND longUrl == %@ ", aKey, aLongUrl]];

        NSError *theError = nil;
        NSArray *theShareURLItemObjects = [aCurrentManagedObjectContext executeFetchRequest:theFetchRequest error:&theError];

        ShareURL *aShareURLModel = nil;
        if (theShareURLItemObjects.count)
        {
            aShareURLModel = (ShareURL *)[theShareURLItemObjects objectAtIndex:0];
        }
        else
        {
            aShareURLModel = [NSEntityDescription
                insertNewObjectForEntityForName:@"ShareURL"
                         inManagedObjectContext:[self getCurrentManagedObjectContext]];
        }
        aShareURLModel.shortUrl = aShortUrl;
        aShareURLModel.uniqueId = aKey;
        aShareURLModel.longUrl = aLongUrl;

        [aCurrentManagedObjectContext save:&theError];
    }
}

@end
