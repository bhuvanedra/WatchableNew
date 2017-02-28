//
//  LaunchViewController.h
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LaunchViewController : UIViewController
@property (strong, nonatomic) UIButton *mLoginButton;
@property (strong, nonatomic) UIButton *mSignUpButton;
@property (weak, nonatomic) IBOutlet UILabel *mVersionLabel;

- (void)pauseMoviePlayer;
- (void)playMoviePlayer;
@end
