//
//  CustomActivityItemProviderForSharing.h
//  Watchable
//
//  Created by Valtech on 04/08/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ePlayList,
    eVideo,
} ShareContentType;

@interface CustomActivityItemProviderForSharing : UIActivityItemProvider
{
}
- (id)initWithText:(NSString *)text urlText:(NSURL *)url withShareType:(ShareContentType)aShareContentType title:(NSString *)aTitle;
- (id)initWithImage:(UIImage *)aImage withShareType:(ShareContentType)aShareContentType;
- (id)initWithImageURL:(NSURL *)imageUrl withShareType:(ShareContentType)aShareContentType;
@end
