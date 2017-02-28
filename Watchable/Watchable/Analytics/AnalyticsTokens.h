//
//  AnalyticsTokens.h
//  Watchable
//
//  Created by valtech on 17/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsTokens : NSObject

- (void)analyticsSessionTrackingIdShouldFetchFromServer:(BOOL)fetchFromserver;
- (void)analyticsDeviceId;
- (void)analyticsSubSessionId;
- (void)analyticsEventSessionTokenShouldFetchFromServer:(BOOL)fetchFromServer;
- (BOOL)isSessionTrackingIdValid;
- (void)getAnalyticsTokens;

@end
