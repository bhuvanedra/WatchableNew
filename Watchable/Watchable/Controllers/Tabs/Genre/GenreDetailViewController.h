//
//  GenreDetailViewController.h
//  Watchable
//
//  Created by Valtech on 3/9/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentViewController.h"
#import "Watchable-Swift.h"

@class GenreModel;

@interface GenreDetailViewController : ParentViewController <TrackingPathGenerating>

@property (nonatomic, strong) UIImage *genreSignatureImage;
@property (nonatomic, strong) NSString *genreTitleString;
@property (nonatomic, weak) GenreModel *genreModel;

@end
