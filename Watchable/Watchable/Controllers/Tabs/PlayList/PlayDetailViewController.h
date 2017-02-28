//
//  PlayDetailViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 03/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"
#import "Watchable-Swift.h"

@class ShowModel;
@class ChannelModel;
@class PlaylistModel;
@class GenreModel;
@class VideoModel;
@class ProviderModel;
@interface PlayDetailViewController : ParentViewController <TrackingPathGenerating>
//@property(nonatomic,strong)ShowModel *mDataModel;
@property (nonatomic, strong) PlaylistModel *mDataModel;
@property (nonatomic, strong) ChannelModel *mChannelDataModel;
@property (nonatomic, strong) GenreModel *mGenreDataModel;
@property (nonatomic, strong) ProviderModel *mProviderModal;

@property (nonatomic, assign) BOOL isDetailViewOverLayVisible;
@property (nonatomic) BOOL isFromPlayList;
@property (nonatomic) BOOL isFromGenre;
@property (nonatomic) BOOL isFromProvider;
@property (nonatomic, assign) BOOL isMoviePlaying;
@property (nonatomic, assign) BOOL isPlayLatestVideo;
@property (nonatomic, assign) BOOL isFromShowBottomPlayDetailScreen;
//@property (nonatomic,assign) BOOL isEpisodeOrLogoClicked;
@property (nonatomic, assign) BOOL isEpisodeClicked;
@property (nonatomic, assign) BOOL isLogoClicked;
@property (nonatomic, assign) BOOL isFromSearch;
@property (nonatomic, assign) BOOL isEpisodeOrLogoClicked;
@property (nonatomic, assign) BOOL isFromHistoryScreen;
@property (nonatomic, strong) VideoModel *mVideoModel;

//For deeplinking-Properties-Start
@property (nonatomic, strong) NSString *deeplinkShowId;
@property (nonatomic, strong) NSString *deeplinkVideoId;
@property (nonatomic, strong) NSString *deeplinkPlayListId;
@property (nonatomic, assign) BOOL isPlayVideoForDeeplink;
@property (nonatomic, assign) BOOL isFetchPlayBackURIWithMaxBitRate;
@property (nonatomic, assign) BOOL shouldNotCallViewDidAppear;
//For deeplinking-Properties-End

- (BOOL)isFullScreenMovieViewPresented;
- (BOOL)canChangeToLandScapeMode;

- (void)handlePauseOfPlayerWhenOverlayPresented;
- (void)exitFullScreenModeForOverLayFlow;

//Deeplinking Methods Starting
- (BOOL)isPlayListVideoListDataSourceAvaliable;
- (NSUInteger)getDataSourceVideoIdIndex:(NSString *)aVideoId;
- (void)setPreviousSelectedIndex:(NSIndexPath *)aIndex;

- (void)getVideoListForCuratedPlaylist;

- (BOOL)isChannelVideoListDataSourceAvaliable;

- (void)removeBackButtonForController;
//Deeplinking Methods Ending
- (void)rotateToPotraitMode;
- (void)setSelectedIndexToPreviouslyPlayedVideoId;
- (void)setSelectedIndex:(NSIndexPath *)aIndex;

@end
