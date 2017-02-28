//
//  TutorialOverLayView.m
//  Watchable
//
//  Created by Valtech on 10/7/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "TutorialOverLayView.h"
#import "DBHandler.h"
@interface TutorialOverLayView ()
@property (nonatomic, strong) UIButton *mNotReadyToSignUpBtn;
@end
@implementation TutorialOverLayView
- (IBAction)onClickingGetWatchingBtn:(id)sender
{
    NSLog(@"onClickingGetWatchingBtn");
    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [aAppDelegate removeTutorialOverlayView];

    if (!aAppDelegate.isGuestUser)
    {
        [aAppDelegate showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial];
    }
    //    else
    //    {
    //        [[DBHandler sharedInstance] deleteUserProfileFromDB];
    //        [aAppDelegate showEmailConfirmToastForLoggedInUserOnStartWatchFromTutorial];
    //    }
}

- (void)modifyUIForLoggedInUser
{
    self.mNotReadyToSignUpBtn.hidden = YES;
    //self.startWatchingButtonBottomConsttaint.constant=44;
    [self.mGetWatchingBtn setTitle:@"Start Watching" forState:UIControlStateNormal];
}
- (void)onClickingNotReadyToSignUpBtn
{
    AppDelegate *aAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [aAppDelegate removeTutorialOverlayView];
}

- (void)addUIElements
{
    //AppDelegate *aAppDelegate= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    //    if(aAppDelegate.isGuestUser)
    //    {
    //        self.startWatchingButtonBottomConsttaint.constant=62;
    //        [self.mGetWatchingBtn setTitle:@"Sign up" forState:UIControlStateNormal];
    //
    //        UIButton *notReadyToSignUpBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    //        self.mNotReadyToSignUpBtn=notReadyToSignUpBtn;
    //        float aNotReadyButtonWidth=200;
    //        float aViewWidth=[[UIScreen mainScreen]bounds].size.width;
    //         float aViewHeight=[[UIScreen mainScreen]bounds].size.height;
    //        notReadyToSignUpBtn.frame=CGRectMake((aViewWidth-aNotReadyButtonWidth)/2,aViewHeight-47,aNotReadyButtonWidth,30);
    //        NSString *str = @"I'm not ready to signup";
    //
    //        UIFont *aFont = [UIFont fontWithName:@"AvenirNext-Medium" size:15.0];
    //        NSLog(@"aFont=%f",aFont.pointSize);
    //        NSDictionary * fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:aFont, NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName,[NSNumber numberWithInt:NSUnderlineStyleSingle],NSUnderlineStyleAttributeName,nil];
    //
    //        // Add attribute NSUnderlineStyleAttributeName
    //        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:fontAttributes];
    //        [notReadyToSignUpBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
    //        [notReadyToSignUpBtn setAttributedTitle:attributedString forState:UIControlStateHighlighted];
    //        [notReadyToSignUpBtn addTarget:self action:@selector(onClickingNotReadyToSignUpBtn) forControlEvents:UIControlEventTouchUpInside];
    //        [self addSubview:notReadyToSignUpBtn];
    //    }
    //    else

    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9];
    float deviceScreenWidth = [[UIScreen mainScreen] bounds].size.width;
    float deviceScreenHeight = [[UIScreen mainScreen] bounds].size.height;

    float avaliableHeightForUIElements = deviceScreenHeight - 37 - 90;

    float aTitleFontSize = 18.0;
    float aDescFontSize = 12.0;

    float watchableFontSize = 17.0;
    float watchableDecFontSize = 15.0;
    if (deviceScreenHeight <= 480.0)
    {
        //4s
        aTitleFontSize = 16.0;
        aDescFontSize = 10.0;

        watchableFontSize = 15.0;
        watchableDecFontSize = 13.0;
    }
    else if (deviceScreenHeight <= 568.0)
    {
        //5/5s
        aTitleFontSize = 17.0;
        aDescFontSize = 11.0;

        watchableFontSize = 16.0;
        watchableDecFontSize = 14.0;
    }
    //    else if(deviceScreenHeight<=667.0)
    //    {
    //        //6/6s;
    //        aTitleFontSize=18.0;
    //        aDescFontSize=12.0;
    //    }

    UIScrollView *aScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40 + 90, deviceScreenWidth, avaliableHeightForUIElements)];
    //aScrollView.backgroundColor=[UIColor redColor];

    UIFont *font1 = [UIFont fontWithName:@"AvenirNext-DemiBold" size:watchableFontSize];
    NSDictionary *attr = @{NSFontAttributeName : font1, NSForegroundColorAttributeName : [UIColor whiteColor]};

    NSString *aStr = [NSString stringWithFormat:@"Watchable"];
    NSMutableAttributedString *aAttributedString = [[NSMutableAttributedString alloc] initWithString:aStr attributes:attr];

    UIFont *font2 = [UIFont fontWithName:@"AvenirNext-DemiBold" size:watchableDecFontSize];
    NSDictionary *attr2 = @{NSFontAttributeName : font2, NSForegroundColorAttributeName : [UIColor whiteColor]};

    NSString *aDescStr = [NSString stringWithFormat:@" is a new way to watch the best online videos."];
    NSAttributedString *aAttributedString2 = [[NSAttributedString alloc] initWithString:aDescStr attributes:attr2];
    [aAttributedString appendAttributedString:aAttributedString2];

    UILabel *aWatchableDescLable = [[UILabel alloc] initWithFrame:CGRectMake(36, 35, aScrollView.frame.size.width - (2 * 36), 46)];
    aWatchableDescLable.numberOfLines = 2;
    aWatchableDescLable.attributedText = aAttributedString;
    [aScrollView addSubview:aWatchableDescLable];
    //74,144,226

    UIButton *aStartWatchingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aStartWatchingButton setTitle:@"Dive in!" forState:UIControlStateNormal];
    aStartWatchingButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
    [aStartWatchingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [aStartWatchingButton setBackgroundColor:[UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0]];

    [aStartWatchingButton addTarget:self action:@selector(onClickingGetWatchingBtn:) forControlEvents:UIControlEventTouchUpInside];
    aStartWatchingButton.layer.cornerRadius = 4.0;
    aStartWatchingButton.layer.masksToBounds = YES;
    [aScrollView addSubview:aStartWatchingButton];

    UIImageView *aDiscoverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    aDiscoverImageView.image = [UIImage imageNamed:@"discoverIcon.png"];
    [aScrollView addSubview:aDiscoverImageView];

    UIImageView *aBrowseImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    aBrowseImageView.image = [UIImage imageNamed:@"browseIcon.png"];
    [aScrollView addSubview:aBrowseImageView];

    UIImageView *aPersonalizeImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    aPersonalizeImageView.image = [UIImage imageNamed:@"personalizeIcon.png"];
    [aScrollView addSubview:aPersonalizeImageView];

    UILabel *aDiscoverLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aDiscoverLbl.text = @"DISCOVER";
    aDiscoverLbl.textColor = [UIColor whiteColor];
    aDiscoverLbl.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:aTitleFontSize];
    [aScrollView addSubview:aDiscoverLbl];

    UILabel *aDiscoverDescLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aDiscoverDescLbl.numberOfLines = 3;
    aDiscoverDescLbl.textColor = [UIColor whiteColor];
    aDiscoverDescLbl.text = @"Let our selection of curated playlists guide you through the best new videos";
    aDiscoverDescLbl.font = [UIFont fontWithName:@"AvenirNext-Medium" size:aDescFontSize];
    [aScrollView addSubview:aDiscoverDescLbl];

    UILabel *aBrowesLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aBrowesLbl.text = @"BROWSE SHOWS";
    aBrowesLbl.textColor = [UIColor whiteColor];
    aBrowesLbl.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:aTitleFontSize];
    [aScrollView addSubview:aBrowesLbl];

    UILabel *aBrowesDescLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aBrowesDescLbl.numberOfLines = 3;
    aBrowesDescLbl.textColor = [UIColor whiteColor];
    aBrowesDescLbl.text = @"Our collection of shows from the world's top creators have something for everyone";
    aBrowesDescLbl.font = [UIFont fontWithName:@"AvenirNext-Medium" size:aDescFontSize];
    [aScrollView addSubview:aBrowesDescLbl];

    UILabel *aPersonalizeLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aPersonalizeLbl.text = @"PERSONALIZE";
    aPersonalizeLbl.textColor = [UIColor whiteColor];
    aPersonalizeLbl.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:aTitleFontSize];
    [aScrollView addSubview:aPersonalizeLbl];

    UILabel *aPersonalizeDescLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    aPersonalizeDescLbl.numberOfLines = 3;
    aPersonalizeDescLbl.textColor = [UIColor whiteColor];
    aPersonalizeDescLbl.text = @"Follow your favorite shows and easily access them";
    aPersonalizeDescLbl.font = [UIFont fontWithName:@"AvenirNext-Medium" size:aDescFontSize];
    [aScrollView addSubview:aPersonalizeDescLbl];

    [self addSubview:aScrollView];

    if (deviceScreenHeight <= 480.0)
    {
        //4s

        float differ = 18.0;

        aWatchableDescLable.frame = CGRectMake(36, 20, aScrollView.frame.size.width - (2 * 36), 40);

        aDiscoverImageView.frame = CGRectMake(36, aWatchableDescLable.frame.size.height + aWatchableDescLable.frame.origin.y + 20, aDiscoverImageView.image.size.width, aDiscoverImageView.image.size.height);
        aDiscoverLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aDiscoverDescSize = [aDiscoverDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 66)];
        aDiscoverDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverLbl.frame.origin.y + aDiscoverLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aDiscoverDescSize.height);

        aBrowseImageView.frame = CGRectMake(36, aDiscoverDescLbl.frame.size.height + aDiscoverDescLbl.frame.origin.y + differ, aBrowseImageView.image.size.width, aBrowseImageView.image.size.height);
        aBrowseImageView.center = CGPointMake(aDiscoverImageView.center.x, aBrowseImageView.frame.origin.y + (aBrowseImageView.image.size.height) / 2);
        aBrowesLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowseImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aBrowesDescLblSize = [aBrowesDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 66)];

        aBrowesDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowesLbl.frame.origin.y + aBrowesLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aBrowesDescLblSize.height);

        aPersonalizeImageView.frame = CGRectMake(36, aBrowesDescLbl.frame.size.height + aBrowesDescLbl.frame.origin.y + differ, aPersonalizeImageView.image.size.width, aPersonalizeImageView.image.size.height);
        aPersonalizeImageView.center = CGPointMake(aDiscoverImageView.center.x, aPersonalizeImageView.frame.origin.y + (aPersonalizeImageView.image.size.height) / 2);
        aPersonalizeLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aPersonalizeDescLblSize = [aPersonalizeDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 80)];

        aPersonalizeDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeLbl.frame.origin.y + aPersonalizeLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aPersonalizeDescLblSize.height);

        aStartWatchingButton.frame = CGRectMake(47, aPersonalizeDescLbl.frame.origin.y + aPersonalizeDescLbl.frame.size.height + 25, aScrollView.frame.size.width - (2 * 47), 44);
    }
    else if (deviceScreenHeight <= 568.0)
    {
        //5/5s
        float differ = 20.0;

        aWatchableDescLable.frame = CGRectMake(36, 30, aScrollView.frame.size.width - (2 * 36), 46);

        aDiscoverImageView.frame = CGRectMake(36, aWatchableDescLable.frame.size.height + aWatchableDescLable.frame.origin.y + differ, aDiscoverImageView.image.size.width, aDiscoverImageView.image.size.height);
        aDiscoverLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aDiscoverDescSize = [aDiscoverDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 66)];
        aDiscoverDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverLbl.frame.origin.y + aDiscoverLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aDiscoverDescSize.height);

        aBrowseImageView.frame = CGRectMake(36, aDiscoverDescLbl.frame.size.height + aDiscoverDescLbl.frame.origin.y + differ, aBrowseImageView.image.size.width, aBrowseImageView.image.size.height);
        aBrowseImageView.center = CGPointMake(aDiscoverImageView.center.x, aBrowseImageView.frame.origin.y + (aBrowseImageView.image.size.height) / 2);
        aBrowesLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowseImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aBrowesDescLblSize = [aBrowesDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 66)];

        aBrowesDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowesLbl.frame.origin.y + aBrowesLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aBrowesDescLblSize.height);

        aPersonalizeImageView.frame = CGRectMake(36, aBrowesDescLbl.frame.size.height + aBrowesDescLbl.frame.origin.y + differ, aPersonalizeImageView.image.size.width, aPersonalizeImageView.image.size.height);
        aPersonalizeImageView.center = CGPointMake(aDiscoverImageView.center.x, aPersonalizeImageView.frame.origin.y + (aPersonalizeImageView.image.size.height) / 2);
        aPersonalizeLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aPersonalizeDescLblSize = [aPersonalizeDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 80)];

        aPersonalizeDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeLbl.frame.origin.y + aPersonalizeLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aPersonalizeDescLblSize.height);

        aStartWatchingButton.frame = CGRectMake(47, aPersonalizeDescLbl.frame.origin.y + aPersonalizeDescLbl.frame.size.height + 36 + 15, aScrollView.frame.size.width - (2 * 47), 44);
    }
    else
    {
        //6

        aWatchableDescLable.frame = CGRectMake(36, 35, aScrollView.frame.size.width - (2 * 36), 46);

        aDiscoverImageView.frame = CGRectMake(36, aWatchableDescLable.frame.size.height + aWatchableDescLable.frame.origin.y + 30, aDiscoverImageView.image.size.width, aDiscoverImageView.image.size.height);
        aDiscoverLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aDiscoverDescSize = [aDiscoverDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 80)];
        aDiscoverDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aDiscoverLbl.frame.origin.y + aDiscoverLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aDiscoverDescSize.height);

        aBrowseImageView.frame = CGRectMake(36, aDiscoverDescLbl.frame.size.height + aDiscoverDescLbl.frame.origin.y + 27, aBrowseImageView.image.size.width, aBrowseImageView.image.size.height);
        aBrowseImageView.center = CGPointMake(aDiscoverImageView.center.x, aBrowseImageView.frame.origin.y + (aBrowseImageView.image.size.height) / 2);
        aBrowesLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowseImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aBrowesDescLblSize = [aBrowesDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 80)];

        aBrowesDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aBrowesLbl.frame.origin.y + aBrowesLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aBrowesDescLblSize.height);

        aPersonalizeImageView.frame = CGRectMake(36, aBrowesDescLbl.frame.size.height + aBrowesDescLbl.frame.origin.y + 27, aPersonalizeImageView.image.size.width, aPersonalizeImageView.image.size.height);
        aPersonalizeImageView.center = CGPointMake(aDiscoverImageView.center.x, aPersonalizeImageView.frame.origin.y + (aPersonalizeImageView.image.size.height) / 2);
        aPersonalizeLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeImageView.frame.origin.y - 6, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), 28);

        CGSize aPersonalizeDescLblSize = [aPersonalizeDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 5 + 47), 80)];

        aPersonalizeDescLbl.frame = CGRectMake(aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 10, aPersonalizeLbl.frame.origin.y + aPersonalizeLbl.frame.size.height, deviceScreenWidth - (aDiscoverImageView.frame.origin.x + aDiscoverImageView.frame.size.width + 1 + 47), aPersonalizeDescLblSize.height);

        aStartWatchingButton.frame = CGRectMake(47, aScrollView.frame.size.height - (44 + 60), aScrollView.frame.size.width - (2 * 47), 44);
    }
    /* else if(deviceScreenHeight<=736.0)
    {
        aDiscoverImageView.frame=CGRectMake(36, 30+20, aDiscoverImageView.image.size.width, aDiscoverImageView.image.size.height);
        aDiscoverLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aDiscoverImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aDiscoverDescSize= [aDiscoverDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        aDiscoverDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aDiscoverLbl.frame.origin.y+aDiscoverLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aDiscoverDescSize.height);
        
        
        aBrowseImageView.frame=CGRectMake(36, aDiscoverDescLbl.frame.size.height+aDiscoverDescLbl.frame.origin.y+60, aBrowseImageView.image.size.width, aBrowseImageView.image.size.height);
        aBrowseImageView.center=CGPointMake(aDiscoverImageView.center.x,aBrowseImageView.frame.origin.y+(aBrowseImageView.image.size.height)/2 );
        aBrowesLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aBrowseImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aBrowesDescLblSize= [aBrowesDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        
        aBrowesDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aBrowesLbl.frame.origin.y+aBrowesLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aBrowesDescLblSize.height);
        
        aPersonalizeImageView.frame=CGRectMake(36, aBrowesDescLbl.frame.size.height+aBrowesDescLbl.frame.origin.y+60, aPersonalizeImageView.image.size.width, aPersonalizeImageView.image.size.height);
        aPersonalizeImageView.center=CGPointMake(aDiscoverImageView.center.x,aPersonalizeImageView.frame.origin.y+(aPersonalizeImageView.image.size.height)/2 );
        aPersonalizeLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aPersonalizeImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aPersonalizeDescLblSize= [aPersonalizeDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        
        aPersonalizeDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aPersonalizeLbl.frame.origin.y+aPersonalizeLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aPersonalizeDescLblSize.height);
        
        
        //6+/6s+
    }
    else
    {
        
        aDiscoverImageView.frame=CGRectMake(36, 4, aDiscoverImageView.image.size.width, aDiscoverImageView.image.size.height);
        aDiscoverLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aDiscoverImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aDiscoverDescSize= [aDiscoverDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        aDiscoverDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aDiscoverLbl.frame.origin.y+aDiscoverLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aDiscoverDescSize.height);
        
        
        aBrowseImageView.frame=CGRectMake(36, aDiscoverDescLbl.frame.size.height+aDiscoverDescLbl.frame.origin.y+50, aBrowseImageView.image.size.width, aBrowseImageView.image.size.height);
        aBrowseImageView.center=CGPointMake(aDiscoverImageView.center.x,aBrowseImageView.frame.origin.y+(aBrowseImageView.image.size.height)/2 );
        aBrowesLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aBrowseImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aBrowesDescLblSize= [aBrowesDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        
        aBrowesDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aBrowesLbl.frame.origin.y+aBrowesLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aBrowesDescLblSize.height);
        
        aPersonalizeImageView.frame=CGRectMake(36, aBrowesDescLbl.frame.size.height+aBrowesDescLbl.frame.origin.y+50, aPersonalizeImageView.image.size.width, aPersonalizeImageView.image.size.height);
        aPersonalizeImageView.center=CGPointMake(aDiscoverImageView.center.x,aPersonalizeImageView.frame.origin.y+(aPersonalizeImageView.image.size.height)/2 );
        aPersonalizeLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aPersonalizeImageView.frame.origin.y-4, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), 28);
        
        CGSize aPersonalizeDescLblSize= [aPersonalizeDescLbl sizeThatFits:CGSizeMake(deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+5+47), 80)];
        
        aPersonalizeDescLbl.frame=CGRectMake(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+10, aPersonalizeLbl.frame.origin.y+aPersonalizeLbl.frame.size.height, deviceScreenWidth-(aDiscoverImageView.frame.origin.x+aDiscoverImageView.frame.size.width+1+47), aPersonalizeDescLblSize.height);
        
    }*/
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
