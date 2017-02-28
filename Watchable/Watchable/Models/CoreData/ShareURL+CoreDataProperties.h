//
//  ShareURL+CoreDataProperties.h
//  Watchable
//
//  Created by Gudkesh Yaduvanshi on 3/23/16.
//  Copyright © 2016 comcast. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ShareURL.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShareURL (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *uniqueId;
@property (nullable, nonatomic, retain) NSString *longUrl;
@property (nullable, nonatomic, retain) NSString *shortUrl;

@end

NS_ASSUME_NONNULL_END
