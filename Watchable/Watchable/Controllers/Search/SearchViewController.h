//
//  SearchViewController.h
//  Watchable
//
//  Created by Valtech on 5/12/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Watchable-Swift.h"

typedef enum _SEARCH_SCREEN_SECTION_ENUM {
    kChannelsSection,
    kVideosSection,
    kTotalSection
} SEARCH_SCREEN_SECTION_ENUM;

#import "ParentViewController.h"
@interface SearchViewController : ParentViewController <TrackingPathGenerating>
@property (nonatomic, weak) IBOutlet UITextField *mSearchBarTextField;
@property (nonatomic, weak) IBOutlet UIView *mSearchBarBGView;
@end
