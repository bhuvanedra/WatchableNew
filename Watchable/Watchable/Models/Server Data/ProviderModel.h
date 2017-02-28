//
//  ProviderModel.h
//  Watchable
//
//  Created by Valtech on 3/16/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProviderModel : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *uniqueId;
@property (nonatomic, strong) NSDictionary *linksDict;

- (id)initWithJSONData:(NSDictionary *)aData;

@end
