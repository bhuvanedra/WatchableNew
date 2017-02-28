//
//  LaunchViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "LaunchViewController.h"
#import "Utilities.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "SignUpViewController.h"
#import "LoginViewController.h"
#import "SwrveUtility.h"
#import "GAUtilities.h"

typedef enum {
    eAnimationNone = 0,
    eSwipRight = 1,
    eSwipLeft,

} eSwipAnimationType;

#define kAnimationDuration 0.36
#define kTabIconOnVideoTag 11111

@interface LaunchViewController () <CAAnimationDelegate>

@property (nonatomic, strong) UIView *mMovieBGView;
@property (nonatomic, strong) UIView *mSignupAndLoginButtonBGView;
@property (nonatomic, strong) UIImageView *mLandingImageView;
@property (nonatomic, strong) UIPageControl *mPageControl;
@property (nonatomic, strong) AVPlayer *mFirstMoviePlayer;
@property (nonatomic, assign) UIView *mCurrentShowingView;

@end

@implementation LaunchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // [self initialUISetup];
    [self intializeUIElements];
    //[self addSwipGesturesForPaging];
    //[self addLandingScreenImageViewSwipeAnimation:eAnimationNone];
    [self addSignUpAndLoginButton];
    [self addMoviePlayer];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"LandingScreen"];
}

- (void)pauseMoviePlayer
{
    if (self.mFirstMoviePlayer)
    {
        [self.mFirstMoviePlayer pause];
    }
}

- (void)playMoviePlayer
{
    if (self.mFirstMoviePlayer)
    {
        [self.mFirstMoviePlayer play];
    }
}
- (void)didPlayToEndTime
{
    [self.mFirstMoviePlayer seekToTime:CMTimeMakeWithSeconds(0, 1)];
    [self.mFirstMoviePlayer play];
}
- (void)addMoviePlayer
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    NSString *aString = [[NSBundle mainBundle] pathForResource:@"MyShowsTutorial" ofType:@"mp4"];
    NSURL *aUrl = [NSURL fileURLWithPath:aString];
    self.mFirstMoviePlayer = [AVPlayer playerWithURL:aUrl];
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    playerController.view.backgroundColor = [UIColor clearColor];
    playerController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerController.showsPlaybackControls = NO;
    playerController.player = self.mFirstMoviePlayer;
    [playerController.view setFrame:self.view.bounds];
    [self.mFirstMoviePlayer play];
    self.view.userInteractionEnabled = YES;
    playerController.view.frame = self.view.frame;
    [self.view insertSubview:playerController.view atIndex:0];

    UIImage *aLoginLogoImg = [UIImage imageNamed:@"watchableLogo_login"];
    UIImageView *aLoginLogo = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - aLoginLogoImg.size.width) / 2, (self.view.frame.size.height / 2) - aLoginLogoImg.size.height, aLoginLogoImg.size.width, aLoginLogoImg.size.height)];
    aLoginLogo.image = aLoginLogoImg;
    [self.view addSubview:aLoginLogo];
}

- (void)intializeUIElements
{
    self.mMovieBGView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.mMovieBGView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.mMovieBGView];

    float aGradientHeight = self.view.frame.size.height * 50.00 / 100.0;
    self.mSignupAndLoginButtonBGView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - aGradientHeight, self.view.frame.size.width, aGradientHeight)];
    self.mSignupAndLoginButtonBGView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.mSignupAndLoginButtonBGView];
}

- (void)addSignUpAndLoginButton
{
    self.mSignUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.mSignUpButton.frame = CGRectMake(25, self.mSignupAndLoginButtonBGView.frame.size.height - 64, (self.view.frame.size.width / 2) - 31, 44);
    self.mSignUpButton.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];

    self.mSignUpButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
    [self.mSignUpButton setTitle:@"Sign up" forState:UIControlStateNormal];
    [self.mSignUpButton setTitleColor:[UIColor colorWithRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.mSignUpButton addTarget:self action:@selector(onClickingSignUpButton:) forControlEvents:UIControlEventTouchUpInside];

    self.mSignUpButton.layer.cornerRadius = 4.0;
    self.mSignUpButton.hidden = YES;
    self.mSignUpButton.alpha = 0;
    [self.mSignupAndLoginButtonBGView addSubview:self.mSignUpButton];

    self.mLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.mLoginButton.frame = CGRectMake(self.mSignUpButton.frame.size.width + self.mSignUpButton.frame.origin.x + 12, self.mSignUpButton.frame.origin.y, self.mSignUpButton.frame.size.width, self.mSignUpButton.frame.size.height);
    self.mLoginButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
    [self.mLoginButton setTitle:@"Log in" forState:UIControlStateNormal];
    [self.mLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.mLoginButton addTarget:self action:@selector(onClickingLoginButton:) forControlEvents:UIControlEventTouchUpInside];

    self.mLoginButton.layer.borderWidth = 2.0;
    self.mLoginButton.layer.cornerRadius = 4.0;
    self.mLoginButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.mLoginButton.hidden = YES;
    self.mLoginButton.alpha = 0;
    [self.mSignupAndLoginButtonBGView addSubview:self.mLoginButton];

    self.mLoginButton.hidden = NO;
    self.mSignUpButton.hidden = NO;
    self.mLoginButton.alpha = 1.0;
    self.mSignUpButton.alpha = 1.0;

    self.mSignUpButton.frame = CGRectMake(25, self.mSignupAndLoginButtonBGView.frame.size.height * 44.00 / 100.0, (self.view.frame.size.width / 2) - 31, 44);
    self.mLoginButton.frame = CGRectMake(self.mSignUpButton.frame.size.width + self.mSignUpButton.frame.origin.x + 12, self.mSignUpButton.frame.origin.y, self.mSignUpButton.frame.size.width, self.mSignUpButton.frame.size.height);

    [Utilities addGradientToView:self.mSignupAndLoginButtonBGView withStartGradientColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.0] withEndGradientColor:[UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:0.8]];

    float aGuestUserButtonWidth = 200;
    UIButton *aGuestUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    aGuestUserButton.frame = CGRectMake((self.view.frame.size.width - aGuestUserButtonWidth) / 2, self.mSignUpButton.frame.size.height + self.mSignUpButton.frame.origin.y + 25, aGuestUserButtonWidth, 30);
    NSString *str = @"Try without an account";

    UIFont *aFont = [UIFont fontWithName:@"AvenirNext-Medium" size:15.0];
    NSLog(@"aFont=%f", aFont.pointSize);
    NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:aFont, NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];

    // Add attribute NSUnderlineStyleAttributeName
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:fontAttributes];
    [aGuestUserButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [aGuestUserButton setAttributedTitle:attributedString forState:UIControlStateHighlighted];
    [aGuestUserButton addTarget:self action:@selector(onClickingGuestUserBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.mSignupAndLoginButtonBGView addSubview:aGuestUserButton];
}

- (void)onClickingGuestUserBtn
{
    NSLog(@"onClickingGuestUserBtn");

    [[SwrveUtility sharedInstance] postSwrveEvent:kSwrveregisterTry_without_account];

    [kSharedApplicationDelegate setTabBarForGuestUserWithTutorialOverLay:YES];
}

- (IBAction)onClickingSignUpButton:(UIButton *)sender
{
    NSLog(@"onClickingSignUpButton");
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SignUpViewController *aSignUpViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionFromLeft;
    [transition setType:kCATransitionPush];
    transition.subtype = kCATransitionFromLeft;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];

    // self.navigationController.navigationBarHidden = NO;

    [self.navigationController pushViewController:aSignUpViewController animated:NO];
}
- (IBAction)onClickingLoginButton:(UIButton *)sender
{
    NSLog(@"onClickingLoginButton");
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    LoginViewController *aLoginViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionFromRight;
    [transition setType:kCATransitionPush];
    transition.subtype = kCATransitionFromRight;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];

    [self.navigationController pushViewController:aLoginViewController animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //[self addLandingScreenImageViewSwipeAnimation:eAnimationNone];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.mFirstMoviePlayer pause];
    self.mFirstMoviePlayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:AVPlayerItemDidPlayToEndTimeNotification];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
