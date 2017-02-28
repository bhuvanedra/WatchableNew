//
//  MoviePlayerSingleton.h
//  Watchable
//
//  Created by Raja Indirajith on 24/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
@class AVPlayerViewController;
@interface MoviePlayerSingleton : NSObject

+ (MoviePlayerSingleton *)sharedInstance;
+ (AVPlayerViewController *)moviePlayer;
+ (void)setMoviePlayerFrame:(CGRect)aFrame;
+ (UIView *)getMoviePlayerView;
+ (void)stopMoviePlayer;
+ (void)playMoviePlayerWithContentURLStr:(NSString *)aStr;
+ (void)setDefaultControls;
+ (void)removeDefaultControls;
+ (void)setFullScreen;
+ (void)setNonFullScreen;
@end
