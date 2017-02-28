//
//  ParentViewController.m
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ParentViewController.h"
#import "UIColor+HexColor.h"
#import "PlayListViewController.h"
@interface ParentViewController ()
@property (nonatomic, strong) UIButton *leftBarBtnItem;
@property (nonatomic, strong) UILabel *mNavTitleLabel;
@property (nonatomic, strong) UIView *mNavBarView;
@property (nonatomic, assign) BOOL isNarBarVisible;
@property (nonatomic, strong) UIView *mNavLeftBarView;
@property (nonatomic, strong) UIView *mNavRightBarView;
@property (nonatomic, strong) UIButton *mShareButton;
@property (nonatomic, strong) UIButton *mFollowButton;
@end
#define kDeleteButtonTag 123456
@implementation ParentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollViewContentOffSet = CGPointZero;
    [self navigationSetUp];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self isKindOfClass:[PlayListViewController class]])
    {
        [kSharedApplicationDelegate showConfirmBannerinController:self];
    }
}
- (void)navigationSetUp
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationController.navigationItem.titleView.userInteractionEnabled = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.navigationBar.hidden = YES;
    //[self createNavBar];
}

- (void)createNavBarWithHidden:(BOOL)isHidden
{
    if (!self.mNavBarView)
    {
        self.mNavBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        self.mNavBarView.userInteractionEnabled = YES;
        self.mNavBarView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:kNavBarMaxAlphaValue];
        [Utilities addGradientToNavBarView:self.mNavBarView withAplha:kNavBarMaxAlphaValue];
        /* CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.mNavBarView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor], nil];
        [self.mNavBarView.layer insertSublayer:gradient atIndex:0];*/
        [self createNavLeftBarView];
        [self createNavRightBarView];
    }

    // drop shadow
    /* [self.mNavBarView.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.mNavBarView.layer setShadowOpacity:1.0];
    [self.mNavBarView.layer setShadowRadius:3.0];
    [self.mNavBarView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];*/
    self.isNarBarVisible = YES;
    [self.view addSubview:self.mNavBarView];
}

- (void)createNavLeftBarView
{
    if (!self.mNavLeftBarView)
    {
        self.mNavLeftBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 64)];
        self.mNavLeftBarView.backgroundColor = [UIColor clearColor];
        [self.mNavBarView addSubview:self.mNavLeftBarView];
    }
}

- (void)createNavRightBarView
{
    if (!self.mNavRightBarView)
    {
        self.mNavRightBarView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100, 0, 100, 64)];
        self.mNavRightBarView.backgroundColor = [UIColor clearColor];
        [self.mNavBarView addSubview:self.mNavRightBarView];
    }
}

- (void)hideNarBarWithAnimation
{
    __weak ParentViewController *weakSelf = self;
    if (weakSelf.mNavBarView && weakSelf.isNarBarVisible)
    {
        weakSelf.isNarBarVisible = NO;

        [UIView animateWithDuration:.3
                         animations:^{

                           weakSelf.mNavBarView.frame = CGRectMake(0, -weakSelf.mNavBarView.frame.size.height, weakSelf.mNavBarView.frame.size.width, weakSelf.mNavBarView.frame.size.height);
                         }
                         completion:^(BOOL finished){

                         }];
    }
}

- (void)setNavBarVisiblityWithAlpha:(float)aAlphaValue
{
    self.mNavBarView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:aAlphaValue];
    float titleLabelAlpha = aAlphaValue / kNavBarMaxAlphaValue;

    if (aAlphaValue < 0.3)
    {
        [Utilities addGradientToNavBarViewToShowStatusBar:self.mNavBarView withAplha:aAlphaValue];
    }
    else
    {
        [Utilities addGradientToNavBarView:self.mNavBarView withAplha:aAlphaValue];
    }

    if (titleLabelAlpha >= 1.0)
        self.mNavTitleLabel.alpha = titleLabelAlpha;
    else
        self.mNavTitleLabel.alpha = 0.0;

    __weak ParentViewController *weakSelf = self;
    if (weakSelf.leftBarBtnItem)
    {
        [self.view bringSubviewToFront:self.mNavBarView];
        [self.mNavBarView bringSubviewToFront:self.mNavTitleLabel];

        [weakSelf.view bringSubviewToFront:weakSelf.leftBarBtnItem];
        [weakSelf.view bringSubviewToFront:weakSelf.mShareButton];
        [weakSelf.view bringSubviewToFront:weakSelf.mFollowButton];
    }
    if (weakSelf.mFollowButton)
        [weakSelf.view bringSubviewToFront:weakSelf.mFollowButton];
}
- (void)showNavBarWithAnimation
{
    __weak ParentViewController *weakSelf = self;
    if (weakSelf.leftBarBtnItem)
    {
        [weakSelf.view bringSubviewToFront:weakSelf.leftBarBtnItem];
    }
    if (weakSelf.mNavBarView && !weakSelf.isNarBarVisible)
    {
        weakSelf.isNarBarVisible = YES;
        [UIView animateWithDuration:.3
            animations:^{

              weakSelf.mNavBarView.frame = CGRectMake(0, 0, weakSelf.mNavBarView.frame.size.width, 64);
            }
            completion:^(BOOL finished) {
              if (weakSelf.leftBarBtnItem)
              {
                  [weakSelf.view bringSubviewToFront:weakSelf.leftBarBtnItem];
                  [weakSelf.view bringSubviewToFront:weakSelf.mShareButton];
                  [weakSelf.view bringSubviewToFront:weakSelf.mFollowButton];
              }
            }];
    }
}

- (void)setBackButtonOnNavBar
{
    if (!self.leftBarBtnItem)
    {
        UIImage *backImage = [UIImage imageNamed:@"back"];
        UIButton *aBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [aBackButton setImage:backImage forState:UIControlStateNormal];
        [aBackButton addTarget:self action:@selector(popController) forControlEvents:UIControlEventTouchUpInside];
        aBackButton.frame = CGRectMake(2, 22, backImage.size.width, backImage.size.height);
        self.leftBarBtnItem = aBackButton;
        [self.mNavLeftBarView addSubview:self.leftBarBtnItem];
    }

    /*self.leftBarBtnItem = [[UIBarButtonItem alloc]initWithCustomView:aBackButton];
    self.navigationItem.leftBarButtonItem = self.leftBarBtnItem;*/
}

- (void)setSettingsHistoryButtonOnNavBar
{
    UIImage *settingsImage = [UIImage imageNamed:@"navSettings.png"];
    UIButton *aSettingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aSettingsButton setImage:settingsImage forState:UIControlStateNormal];
    [aSettingsButton addTarget:self action:@selector(onClickingSettingsButton) forControlEvents:UIControlEventTouchUpInside];
    aSettingsButton.frame = CGRectMake(2, 22, settingsImage.size.width, settingsImage.size.height);
    [self.mNavLeftBarView addSubview:aSettingsButton];

    UIImage *historyImage = [UIImage imageNamed:@"navHistory.png"];
    UIButton *aHistoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aHistoryButton setImage:historyImage forState:UIControlStateNormal];
    [aHistoryButton addTarget:self action:@selector(onClickingHistoryButton) forControlEvents:UIControlEventTouchUpInside];
    aHistoryButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - historyImage.size.width - 2, 22, historyImage.size.width, historyImage.size.height);
    [self.mNavRightBarView addSubview:aHistoryButton];
}

- (void)setBackButtonOnView
{
    if (!self.leftBarBtnItem)
    {
        UIImage *backImage = [UIImage imageNamed:@"back"];
        UIButton *aBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [aBackButton setImage:backImage forState:UIControlStateNormal];
        [aBackButton addTarget:self action:@selector(popController) forControlEvents:UIControlEventTouchUpInside];
        aBackButton.frame = CGRectMake(2, 22, backImage.size.width, backImage.size.height);
        self.leftBarBtnItem = aBackButton;
        [self.view addSubview:self.leftBarBtnItem];
    }

    /*self.leftBarBtnItem = [[UIBarButtonItem alloc]initWithCustomView:aBackButton];
     self.navigationItem.leftBarButtonItem = self.leftBarBtnItem;*/
}

- (UIButton *)getBackButtonRef
{
    return self.leftBarBtnItem;
}
- (void)setBackButtonHide
{
    if (self.leftBarBtnItem)
    {
        self.leftBarBtnItem.hidden = YES;
    }
}

- (void)setShareAddButtonOnView
{
    UIImage *addImage = [UIImage imageNamed:@"navAdd.png"];
    UIButton *aAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *checkImage = [UIImage imageNamed:@"navCheck.png"];
    aAddButton.adjustsImageWhenHighlighted = NO;
    [aAddButton setImage:addImage forState:UIControlStateNormal];
    [aAddButton setImage:checkImage forState:UIControlStateSelected];
    [aAddButton addTarget:self action:@selector(onClickingAddButton) forControlEvents:UIControlEventTouchUpInside];
    aAddButton.frame = CGRectMake(self.view.frame.size.width - 42, 22, addImage.size.width, addImage.size.height);
    [self.view addSubview:aAddButton];
    self.mFollowButton = aAddButton;

    /* UIImage *shareImage=[UIImage imageNamed:@"navShare.png"];
    UIButton *aShareButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [aShareButton setImage:shareImage forState:UIControlStateNormal];
    [aShareButton addTarget:self action:@selector(onClickingShareButton) forControlEvents:UIControlEventTouchUpInside];
    aShareButton.frame=CGRectMake(aAddButton.frame.origin.x-42,22, shareImage.size.width,shareImage.size.height);
    [self.view addSubview:aShareButton];
    self.mShareButton=aShareButton;*/
}

- (void)setShareButtonOnView
{
    UIImage *shareImage = [UIImage imageNamed:@"navShare.png"];
    UIButton *aShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aShareButton setImage:shareImage forState:UIControlStateNormal];
    [aShareButton addTarget:self action:@selector(onClickingShareButton) forControlEvents:UIControlEventTouchUpInside];
    aShareButton.frame = CGRectMake(self.view.frame.size.width - shareImage.size.width - 10, 22, shareImage.size.width, shareImage.size.height);
    [self.view addSubview:aShareButton];
    self.mShareButton = aShareButton;
}

- (void)setSearchButtonOnNarBar
{
    UIImage *searchImage = [UIImage imageNamed:@"navSearch.png"];
    UIButton *aSearchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aSearchButton setImage:searchImage forState:UIControlStateNormal];
    [aSearchButton addTarget:self action:@selector(onClickingSearchButton) forControlEvents:UIControlEventTouchUpInside];
    aSearchButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - searchImage.size.width - 2, 22, searchImage.size.width, searchImage.size.height);
    [self.mNavRightBarView addSubview:aSearchButton];
}
- (void)setNavigationBarTitle:(NSString *)aString withFont:(UIFont *)aFont withTextColor:(UIColor *)aColor
{
    if (!self.mNavTitleLabel)
    {
        float xAxis = 72.0;
        UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(xAxis, 20, self.view.frame.size.width - (2 * xAxis), 44)];
        aLabel.backgroundColor = [UIColor clearColor];
        aLabel.text = @"";
        aLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:20.0];
        aLabel.textColor = [UIColor whiteColor];
        aLabel.textAlignment = NSTextAlignmentCenter;
        aLabel.userInteractionEnabled = YES;
        aLabel.backgroundColor = [UIColor clearColor];
        self.mNavTitleLabel = aLabel;
        [self.mNavBarView addSubview:self.mNavTitleLabel];
    }
    if (aString)
        self.mNavTitleLabel.text = [aString uppercaseString];
    if (aFont)
        self.mNavTitleLabel.font = aFont;
    if (aColor)
        self.mNavTitleLabel.textColor = aColor;

    [self.view bringSubviewToFront:self.mNavBarView];
    [self.mNavBarView bringSubviewToFront:self.mNavTitleLabel];
}

- (void)setDeleteHistoryButtonOnNavBar
{
    UIImage *deleteImage = [UIImage imageNamed:@"navDelete.png"];
    UIButton *aDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //[aDeleteButton setImage:deleteImage forState:UIControlStateNormal];
    [aDeleteButton setBackgroundImage:deleteImage forState:UIControlStateNormal];
    [aDeleteButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
    [aDeleteButton setTitle:@"" forState:UIControlStateNormal];
    [aDeleteButton setTitle:@"Done" forState:UIControlStateSelected];
    aDeleteButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    [aDeleteButton addTarget:self action:@selector(onClickingHistoryDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
    aDeleteButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - deleteImage.size.width - 2, 22, deleteImage.size.width, deleteImage.size.height);
    aDeleteButton.tag = kDeleteButtonTag;
    [aDeleteButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
    [self.mNavRightBarView addSubview:aDeleteButton];
}

- (void)enableDeleteHistoryButton:(BOOL)isEnable
{
    UIButton *aButton = (UIButton *)[self.mNavRightBarView viewWithTag:kDeleteButtonTag];
    aButton.enabled = isEnable;
}

- (UIButton *)getDeleteButton
{
    UIButton *aButton = (UIButton *)[self.mNavRightBarView viewWithTag:kDeleteButtonTag];
    return aButton;
}

- (void)setSettingsDoneButtonOnNavBar
{
    UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    aDoneButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    [aDoneButton addTarget:self action:@selector(onClickingSettingsDoneButton) forControlEvents:UIControlEventTouchUpInside];
    aDoneButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - 52, 22, 50, 40);
    [self.mNavRightBarView addSubview:aDoneButton];
}

- (void)setSettingsLogOutButtonOnNavBar
{
    UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aDoneButton setTitle:@"Logout" forState:UIControlStateNormal];
    aDoneButton.titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:16.0];
    [aDoneButton addTarget:self action:@selector(onClickingSettingsLogoutButton) forControlEvents:UIControlEventTouchUpInside];
    aDoneButton.frame = CGRectMake(0, 22, 50, 40);
    [self.mNavLeftBarView addSubview:aDoneButton];
}

- (void)hideBackButton:(BOOL)isHide
{
    /* if(isHide)
        self.navigationItem.leftBarButtonItem=nil;
    else
         self.navigationItem.leftBarButtonItem=self.leftBarBtnItem;
    */

    if (isHide)
        self.leftBarBtnItem.hidden = YES;
    else
        self.leftBarBtnItem.hidden = NO;
}

- (void)ShowShareButton:(BOOL)isShow
{
    if (isShow)
    {
        self.mShareButton.hidden = NO;
    }
    else
    {
        self.mShareButton.hidden = YES;
    }
}

- (void)hideNarBarWithShareAddButton:(BOOL)isHide
{
    if (isHide)
    {
        self.leftBarBtnItem.hidden = YES;
        self.mNavBarView.hidden = YES;
        self.mFollowButton.hidden = YES;
        self.mShareButton.hidden = YES;
    }
    else
    {
        self.leftBarBtnItem.hidden = NO;
        self.mNavBarView.hidden = NO;
        self.mFollowButton.hidden = NO;
        self.mShareButton.hidden = NO;
    }
}
- (void)setEditProfileButtonsOnNavBar
{
    /* UIButton *aCancelButton=[UIButton buttonWithType:UIButtonTypeCustom];
    NSMutableAttributedString *attString_ = [[NSMutableAttributedString alloc] init];
    
    [attString_ appendAttributedString:[[NSAttributedString alloc] initWithString:@"Cancel"    attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                           [UIFont fontWithName:@"AvenirNext-Regular" size:15.0], NSFontAttributeName,
                                                                                                           [UIColor colorFromHexString:@"#FFFFFF"], NSForegroundColorAttributeName,
                                                                                                           nil]]];
    [aCancelButton setAttributedTitle:attString_ forState:UIControlStateNormal];
    
    [aCancelButton addTarget:self action:@selector(onClickingCancelButton) forControlEvents:UIControlEventTouchUpInside];
    aCancelButton.frame=CGRectMake(0, 22, 70, 35);
    [self.mNavLeftBarView addSubview:aCancelButton];
    
    attString_ = nil;*/
    self.aSaveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.aSaveButton addTarget:self action:@selector(onClickingSaveButton) forControlEvents:UIControlEventTouchUpInside];
    NSLog(@"self.mNavRightBarView=%@", self.mNavRightBarView);
    self.aSaveButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - 70, 22, 90, 35);

    NSLog(@"self.aSaveButton=%@", self.aSaveButton);
    [self.mNavRightBarView addSubview:self.aSaveButton];
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];

    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Save"
                                                                      attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                   [UIFont fontWithName:@"AvenirNext-Regular"
                                                                                                                   size:15.0],
                                                                                                   NSFontAttributeName,
                                                                                                   [UIColor colorWithRed:255
                                                                                                                   green:255
                                                                                                                    blue:255
                                                                                                                   alpha:0.5],
                                                                                                   NSForegroundColorAttributeName,
                                                                                                   nil]]];
    [self.aSaveButton setAttributedTitle:attString forState:UIControlStateNormal];
    [self.aSaveButton setAttributedTitle:attString forState:UIControlStateHighlighted];
}

- (void)enableEditProfileSaveButton:(BOOL)isEnable
{
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    if (isEnable)
    {
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Save"
                                                                          attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                       [UIFont fontWithName:@"AvenirNext-Regular"
                                                                                                                       size:15.0],
                                                                                                       NSFontAttributeName,
                                                                                                       [UIColor colorWithRed:255
                                                                                                                       green:255
                                                                                                                        blue:255
                                                                                                                       alpha:1.0],
                                                                                                       NSForegroundColorAttributeName,
                                                                                                       nil]]];
    }
    else
    {
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Save"
                                                                          attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                       [UIFont fontWithName:@"AvenirNext-Regular"
                                                                                                                       size:15.0],
                                                                                                       NSFontAttributeName,
                                                                                                       [UIColor colorWithRed:255
                                                                                                                       green:255
                                                                                                                        blue:255
                                                                                                                       alpha:0.5],
                                                                                                       NSForegroundColorAttributeName,
                                                                                                       nil]]];
    }
    [self.aSaveButton setAttributedTitle:attString forState:UIControlStateNormal];
    [self.aSaveButton setAttributedTitle:attString forState:UIControlStateHighlighted];
    self.aSaveButton.enabled = isEnable;
}

- (void)popController
{
    [self.navigationController popViewControllerAnimated:YES];
}

// Methods to Override in child class
- (void)onClickingCancelButton
{
}
- (void)onClickingSaveButton
{
}

- (void)onClickingSettingsButton
{
}

- (void)onClickingHistoryButton
{
}

- (void)onClickingHistoryDeleteButton:(UIButton *)aSender
{
}

- (void)onClickingSettingsDoneButton
{
}

- (void)onClickingAddButton
{
}

- (void)onClickingShareButton
{
}

- (void)onClickingSearchButton
{
}

- (void)onClickingSettingsLogoutButton
{
}

- (UIButton *)mFollowButton
{
    return _mFollowButton;
};

- (void)setFollowButtonSelectedMode:(BOOL)isSelected
{
    if (isSelected)
    {
        [self.mFollowButton setImage:[self.mFollowButton imageForState:UIControlStateSelected] forState:UIControlStateNormal];
    }
    else
    {
        UIImage *aFollowNormalImage = [UIImage imageNamed:@"navAdd.png"];

        [self.mFollowButton setImage:aFollowNormalImage forState:UIControlStateNormal];
    }
    self.mFollowButton.selected = isSelected;
}

//

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
}

- (NSString *)getTrackpath
{
    NSArray *aSatckViewControllers = self.navigationController.viewControllers;

    NSMutableString *aString = [[NSMutableString alloc] init];
    for (int aCount = 0; aCount < aSatckViewControllers.count; aCount++)
    {
        id<TrackingPathGenerating> parentViewController = (id<TrackingPathGenerating>)[aSatckViewControllers objectAtIndex:aCount];
        [aString appendString:[parentViewController generateTrackingPath]];
        if (aCount != aSatckViewControllers.count - 1)
        {
            [aString appendString:@"/"];
        }
    }
    return aString;
}

@end
