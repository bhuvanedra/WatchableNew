//
//  ViewController.h
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"
#import "Watchable-Swift.h"

@interface PlayListViewController : ParentViewController <TrackingPathGenerating>

- (void)getUserProfileFromServer;
- (void)addConfirmEmailBannerVisibility;

- (BOOL)isPlayListDataSourceAvaliable;
- (NSUInteger)getDataSourcePlayListIdIndex:(NSString *)aPlayListId;
- (void)pushPlaydetailControllerWithIndex:(NSUInteger)aIndex withPlayListId:(NSString *)aPlayListId withVideoId:(NSString *)aVideoId withDelay:(float)aDelay;

@end
