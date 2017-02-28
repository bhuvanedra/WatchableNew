//
//  TutorialOverLayView.h
//  Watchable
//
//  Created by Valtech on 10/7/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialOverLayView : UIView
@property (weak, nonatomic) IBOutlet UIButton *mGetWatchingBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startWatchingButtonBottomConsttaint;

- (void)addUIElements;
- (void)modifyUIForLoggedInUser;
@end
