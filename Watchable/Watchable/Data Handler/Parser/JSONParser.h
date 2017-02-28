//
//  JSONParser.h
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoModel;
@class PlaylistModel;
@interface JSONParser : NSObject

+ (NSArray *)parseDataForPlayList:(NSDictionary *)aDict;
+ (NSArray *)parseDataForCuratedPlayList:(NSDictionary *)aDict;
+ (NSArray *)parseDataForVideoList:(NSDictionary *)aDict;
+ (NSArray *)parseDataForChannelVideoList:(NSDictionary *)aDict;
+ (NSArray *)parseDataForGenre:(NSDictionary *)aDict;
+ (NSArray *)parseDataForChannels:(NSDictionary *)aDict;
+ (NSArray *)parseDataForProvider:(NSDictionary *)aDict;
+ (VideoModel *)parseDataForNextVideoUnderChannel:(NSDictionary *)aDict;
+ (NSArray *)parseDataForGenreForChannels:(NSDictionary *)aDict;
+ (NSDictionary *)parseDataForSearchResult:(NSDictionary *)aDict;

+ (NSArray *)parseDataForHistoryMetaData:(NSDictionary *)aDict;

+ (NSArray *)parseDataForVideoList:(NSDictionary *)aDict withPlayListModel:(PlaylistModel *)aPlayListModelPtr;

+ (NSArray *)parseDataForFeaturedChannels:(NSDictionary *)aDict withTitle:(NSString **)aTitleStr;
@end
