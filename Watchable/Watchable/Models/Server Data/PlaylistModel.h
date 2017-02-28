//
//  PlaylistModel.h
//  Watchable
//
//  Created by Gudkesh on 21/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaylistModel : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *totalVideos;
@property (strong, nonatomic) NSString *uniqueId;
@property (strong, nonatomic) NSString *genreTitle;
@property (strong, nonatomic) NSString *shortDescription;
@property (strong, nonatomic) NSString *imageUri;
@property (strong, nonatomic) NSString *videoListUrl;
@property (strong, nonatomic) NSNumber *totalVideoDuration;
@property (strong, nonatomic) NSDictionary *relatedLinks;
@property (strong, nonatomic) NSString *shareLink;

- (id)initWithJSONData:(NSDictionary *)aData;
@end
