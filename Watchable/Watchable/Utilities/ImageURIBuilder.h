//
//  ImageURIBuilder.h
//  Watchable
//
//  Created by Raja Indirajith on 21/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "WatchableConstants.h"

@interface ImageURIBuilder : NSObject

+ (NSString *)buildURLWithString:(NSString *)imageUrl withSize:(CGSize)size;
+ (NSString *)buildProviderImageURLWithString:(NSString *)imageUrl withSize:(CGSize)size;
+ (NSString *)buildImageUrlWithString:(NSString *)imageUrl ForImageType:(ImageType)imageType withSize:(CGSize)size;
+ (NSString *)build2XImageUrlWithString:(NSString *)imageUrl ForImageType:(ImageType)imageType withSize:(CGSize)size;
@end
