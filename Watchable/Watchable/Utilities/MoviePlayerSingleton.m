//
//  MoviePlayerSingleton.m
//  Watchable
//
//  Created by Raja Indirajith on 24/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "MoviePlayerSingleton.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WatchableConstants.h"
#define kMovieUrl

static AVPlayerViewController *aMoviePlayer = nil;
@implementation MoviePlayerSingleton

+ (MoviePlayerSingleton *)sharedInstance
{
    static MoviePlayerSingleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[MoviePlayerSingleton alloc] init];
      [MoviePlayerSingleton moviePlayer];

    });
    return sharedInstance;
}

+ (AVPlayerViewController *)moviePlayer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

      //[[MPMusicPlayerController applicationMusicPlayer] setVolume:0];

      aMoviePlayer = [[AVPlayerViewController alloc] init];
      aMoviePlayer.view.userInteractionEnabled = YES;
      aMoviePlayer.showsPlaybackControls = NO;
      //aMoviePlayer.useApplicationAudioSession = YES;
      [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    });
    return aMoviePlayer;
}

+ (void)setMoviePlayerFrame:(CGRect)aFrame
{
    aMoviePlayer.view.frame = aFrame;
}
+ (void)stopMoviePlayer
{
    [aMoviePlayer.player pause];
    aMoviePlayer.player = nil;
}

+ (void)playMoviePlayerWithContentURLStr:(NSString *)aStr
{
    //    [[NSNotificationCenter defaultCenter]postNotificationName:kMoviePlayerStopNotification object:nil];

    if (!aMoviePlayer)
    {
        aMoviePlayer = [MoviePlayerSingleton moviePlayer];
    }

    //    NSString *aString=   [[NSBundle mainBundle]pathForResource:@"v1.mp4" ofType:nil];
    //
    //   BOOL aSuccess= [[NSFileManager defaultManager]fileExistsAtPath:aString];
    //NSURL *aUrl=  [NSURL URLWithString:@"http://cilhlsvod-f.akamaihd.net/i/MP4/demo3/2014-09-24/654587_8042_(8042_,R23MP45000,R23MP45000,R23MP44000,R23MP44000,R23MP43000,R23MP43000,R23MP42000,R23MP42000,R23MP41500,R23MP41500,R23MP41000,R23MP41000,R23MP4500,R23MP4500,R23MP4350,R23MP4350,R22MP464,R22MP464,)_v2.mp4.csmil/1master.m3u8"];

    NSURL *aUrl = [NSURL URLWithString:aStr];
    //
    // NSURL *aUrl=  [NSURL fileURLWithPath:aString];

    [MoviePlayerSingleton stopMoviePlayer];
    aMoviePlayer.player = [AVPlayer playerWithURL:aUrl];

    [aMoviePlayer.player play];
}
+ (UIView *)getMoviePlayerView
{
    return aMoviePlayer.view;
}

+ (void)setDefaultControls
{
    // [[MPMusicPlayerController applicationMusicPlayer] setVolume:.3];
    // aMoviePlayer.useApplicationAudioSession = YES;
    // aMoviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    aMoviePlayer.showsPlaybackControls = NO;
}

+ (void)removeDefaultControls
{
    // [[MPMusicPlayerController applicationMusicPlayer] setVolume:.3];
    // aMoviePlayer.useApplicationAudioSession = YES;
    aMoviePlayer.showsPlaybackControls = NO;
}

+ (void)setFullScreen
{
    //    [aMoviePlayer.player setFullscreen:YES animated:YES];
    // aMoviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    aMoviePlayer.showsPlaybackControls = NO;
}

+ (void)setNonFullScreen
{
    //    [aMoviePlayer setFullscreen:NO animated:YES];
}

@end
