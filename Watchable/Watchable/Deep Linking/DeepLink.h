//
//  DeepLink.h
//  Watchable
//
//  Created by Valtech on 1/25/16.
//  Copyright © 2016 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeepLink : NSObject

- (void)handleDeepLinkingForIncomingDict:(NSDictionary *)aDict;

@end
