//
//  DataConverter.h
//  Watchable
//
//  Created by Raja Indirajith on 03/06/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataConverter : NSObject

- (NSArray *)convertHistoryAssetListToHistoryModelArray:(NSArray *)aHistoryAssetList;

@end
