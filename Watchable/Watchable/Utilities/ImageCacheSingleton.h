//
//  ImageCacheSingleton.h
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCacheSingleton : NSObject

+ (ImageCacheSingleton *)sharedInstance;
- (NSCache *)cache;

@end
