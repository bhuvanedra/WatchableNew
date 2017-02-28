//
//  SignUpLoginOverLayView.m
//  Watchable
//
//  Created by Valtech on 10/15/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "SignUpLoginOverLayView.h"
#import "SignUpViewController.h"
#import "LoginViewController.h"
#import "PlayDetailViewController.h"

@implementation SignUpLoginOverLayView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)addUIElements
{
    float deviceScreenHeight = [[UIScreen mainScreen] bounds].size.height;
    float deviceScreenWidth = [[UIScreen mainScreen] bounds].size.width;
    float watchableDecFontSize = 15.0;
    if (deviceScreenHeight <= 480.0)
    {
        //4s
        watchableDecFontSize = 13.0;
    }
    else if (deviceScreenHeight <= 568.0)
    {
        //5/5s
        watchableDecFontSize = 14.0;
    }

    //    if(!self.isPresentedInLandScape)
    //    {
    //
    ////        if(deviceScreenHeight<=568.0)
    ////        {
    ////            //5/5s
    ////            self.mSignUpButtonPortraitTopConstraint.constant=50.0;
    ////        }
    ////        else if(deviceScreenHeight>=667.0)
    ////        {
    ////            self.mSignUpButtonPortraitTopConstraint.constant=160.0;
    ////        }
    //    }

    if (deviceScreenHeight <= 480.0)
    {
        self.mDescTopConstraint.constant = 210 * 0.75;
    }
    else if (deviceScreenHeight <= 568.0)
    {
        //5/5s
        self.mDescTopConstraint.constant = 210 * 0.8;
    }
    else if (deviceScreenHeight <= 667.0)
    {
        self.mDescTopConstraint.constant = 210 * 0.9;
    }

    self.mLandscapeDescViewConstraint.constant = 200.0;
    if (deviceScreenWidth <= 480.0)
    {
        self.mLandscapeDescViewConstraint.constant = 200 * 0.75;
    }
    else if (deviceScreenWidth <= 568.0)
    {
        //5/5s
        self.mLandscapeDescViewConstraint.constant = 200 * 0.75;
    }
    else if (deviceScreenWidth <= 667.0)
    {
        self.mLandscapeDescViewConstraint.constant = 200 * .9;
    }

    self.mDescLbl.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:watchableDecFontSize];
    self.mDescLbl.text = @"Welcome to content, perfected\n\nSign-up to follow your favorite shows, easily access our selection of curated playlists, and wide collection of shows from the world's top creators.";
    self.mDescLbl.numberOfLines = 9;
    self.mSignUpBtn.layer.cornerRadius = 4.0;
    self.mSignUpBtn.layer.masksToBounds = YES;
}

- (IBAction)onClickingSignUpBtn
{
    [kSharedApplicationDelegate removeLoginSignInScreenForGuestUserByClickingFollow];

    AppDelegate *aSharedDel = (AppDelegate *)kSharedApplicationDelegate;
    if (((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation == UIDeviceOrientationLandscapeLeft || ((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation == UIDeviceOrientationLandscapeRight)
    {
        aSharedDel.isSignUpOverLayClicked = YES;

        NSUInteger aSelectedIndex = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.selectedIndex;
        UINavigationController *aNavigationStack = (UINavigationController *)[((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];
        PlayDetailViewController *vc = (PlayDetailViewController *)[aNavigationStack topViewController];
        [vc exitFullScreenModeForOverLayFlow];

        [self performSelector:@selector(presentSignupScreen) withObject:nil afterDelay:0.1];
    }
    else
    {
        [self presentSignupScreen];
    }
}

- (void)presentSignupScreen
{
    NSUInteger aSelectedIndex = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.selectedIndex;
    UINavigationController *aNavigationStack = (UINavigationController *)[((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SignUpViewController *aSignUpViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];
    aSignUpViewController.isPresented = YES;
    aSignUpViewController.presentedFromScreen = TabbarScreenByFollowAction;
    aSignUpViewController.isPresentedFromMyShows = self.isPresentedFromMyShows;

    CATransition *transition = [CATransition animation];
    transition.duration = 0.35;
    transition.timingFunction =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromRight;

    // NSLog(@"%s: self.view.window=%@", func, self.view.window);
    [aNavigationStack.view.window.layer addAnimation:transition forKey:nil];

    if (((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr)
    {
        [aNavigationStack presentViewController:aSignUpViewController animated:NO completion:nil];
    }
}

- (IBAction)onClickingLogInBtn
{
    [kSharedApplicationDelegate removeLoginSignInScreenForGuestUserByClickingFollow];

    AppDelegate *aSharedDel = (AppDelegate *)kSharedApplicationDelegate;
    if (((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation == UIDeviceOrientationLandscapeLeft || ((AppDelegate *)kSharedApplicationDelegate).currentDeviceOrientation == UIDeviceOrientationLandscapeRight)
    {
        aSharedDel.isSignUpOverLayClicked = YES;

        NSUInteger aSelectedIndex = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.selectedIndex;
        UINavigationController *aNavigationStack = (UINavigationController *)[((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];
        PlayDetailViewController *vc = (PlayDetailViewController *)[aNavigationStack topViewController];
        [vc exitFullScreenModeForOverLayFlow];

        [self performSelector:@selector(presentLoginInScreen) withObject:nil afterDelay:0.2];
    }
    else
    {
        [self presentLoginInScreen];
    }
}

- (void)presentLoginInScreen
{
    NSUInteger aSelectedIndex = ((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.selectedIndex;
    UINavigationController *aNavigationStack = (UINavigationController *)[((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr.viewControllers objectAtIndex:aSelectedIndex];

    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

    LoginViewController *aLoginViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:aLoginViewController];
    aNavController.navigationBarHidden = YES;

    aLoginViewController.isPresented = YES;
    aLoginViewController.presentedFromScreen = TabbarScreenByFollowAction;
    aLoginViewController.isPresentedFromMyShows = self.isPresentedFromMyShows;
    CATransition *transition = [CATransition animation];
    transition.duration = 0.35;
    transition.timingFunction =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromRight;

    // NSLog(@"%s: self.view.window=%@", func, self.view.window);
    [aNavigationStack.view.window.layer addAnimation:transition forKey:nil];
    if (((AppDelegate *)kSharedApplicationDelegate).tabBarCntlr)
    {
        [aNavigationStack presentViewController:aNavController animated:NO completion:nil];
    }
}

- (IBAction)onClickingCancelBtn
{
    [kSharedApplicationDelegate removeLoginSignInScreenForGuestUserByClickingFollow];

    [self performSelector:@selector(cancelOverLay) withObject:nil afterDelay:0.1];
}

- (void)cancelOverLay
{
    [kSharedApplicationDelegate setPreviousSelectedIndexOfTabBarWhenCancelClicked];
}

- (void)cancelSignInOverLay
{
    [kSharedApplicationDelegate removeLoginSignInScreenForGuestUserByClickingFollow];
    [kSharedApplicationDelegate setPreviousSelectedIndexOfTabBarWhenCancelClicked];
}

@end
