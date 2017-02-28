//
//  GenreModel.h
//  Watchable
//
//  Created by Valtech on 3/10/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreModel : NSObject

@property (nonatomic, strong) NSString *genreId;
@property (nonatomic, strong) NSString *genreTitle;
@property (nonatomic, strong) NSString *totalChannels;
@property (nonatomic, strong) NSString *allChannelsUri;
@property (nonatomic, strong) NSDictionary *relatedLinks;

- (id)initWithJSONData:(NSDictionary *)aData;

@end
