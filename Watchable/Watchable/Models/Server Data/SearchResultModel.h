//
//  SearchResultModel.h
//  Watchable
//
//  Created by valtech on 14/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResultModel : NSObject

+ (NSDictionary *)getSearchResultWithJSONData:(NSArray *)aArray;

@end
