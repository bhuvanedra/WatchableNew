//
//  ImageCacheSingleton.m
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ImageCacheSingleton.h"

@implementation ImageCacheSingleton

+ (ImageCacheSingleton *)sharedInstance
{
    static ImageCacheSingleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[ImageCacheSingleton alloc] init];

    });
    return sharedInstance;
}

- (NSCache *)cache
{
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      cache = [[NSCache alloc] init];

    });
    return cache;
}

@end
