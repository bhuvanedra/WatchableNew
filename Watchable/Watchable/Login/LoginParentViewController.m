//
//  LoginParentViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 14/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "LoginParentViewController.h"
@interface LoginParentViewController ()
@property (nonatomic, strong) UIButton *leftBarBtnItem;
@property (nonatomic, strong) UILabel *mNavTitleLabel;
@property (nonatomic, strong) UIView *mNavBarView;
@property (nonatomic, strong) UIView *mNavLeftBarView;
@property (nonatomic, strong) UIView *mNavRightBarView;
@property (nonatomic, strong) UIButton *mSignUpDoneButton;
@property (nonatomic, strong) IBOutlet UIButton *mSignInLogInButton;
@property (nonatomic, strong) IBOutlet UIButton *mCancelButton;
@end

@implementation LoginParentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)createNavBarWithHidden:(BOOL)isHidden
{
    if (!self.mNavBarView)
    {
        self.mNavBarView = [[UIView alloc] initWithFrame:CGRectMake(0, isHidden ? -64 : 0, self.view.frame.size.width, 64)];
        // [Utilities addGradientToNavBarView:self.mNavBarView withAplha:kNavBarMaxAlphaValue];
        self.mNavBarView.userInteractionEnabled = YES;
        self.mNavBarView.backgroundColor = [UIColor colorWithRed:27.0 / 255.0 green:29.0 / 255.0 blue:30.0 / 255.0 alpha:kNavBarMaxAlphaValue];
        //
        //        CAGradientLayer *gradient = [CAGradientLayer layer];
        //        gradient.frame = self.mNavBarView.bounds;
        //        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor BAL] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:29.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor], nil];
        //        [self.mNavBarView.layer insertSublayer:gradient atIndex:0];
        [self createNavLeftBarView];
        [self createNavRightBarView];
    }

    // drop shadow
    //    [self.mNavBarView.layer setShadowColor:[UIColor grayColor].CGColor];
    //    [self.mNavBarView.layer setShadowOpacity:1.0];
    //    [self.mNavBarView.layer setShadowRadius:3.0];
    //    [self.mNavBarView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [self.view addSubview:self.mNavBarView];
}

- (void)clearNavBarColor
{
    self.mNavBarView.backgroundColor = [UIColor clearColor];
}

- (void)setNavigationBarTitle:(NSString *)aString withFont:(UIFont *)aFont withTextColor:(UIColor *)aColor
{
    if (!self.mNavTitleLabel)
    {
        float xAxis = 50.0;
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
}

/*
-(void)setLogInButtonOnNavBar
{
    //UIImage *deleteImage=[UIImage imageNamed:@"navDelete.png"];
    UIButton *aLoginButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [aLoginButton addTarget:self action:@selector(onClickingLoginButton) forControlEvents:UIControlEventTouchUpInside];
    [aLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [aLoginButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [aLoginButton setTitle:@"Log in" forState:UIControlStateNormal];
    aLoginButton.titleLabel.font=[UIFont fontWithName:@"AvenirNextCondensed-Regular" size:16.0];
    aLoginButton.frame=CGRectMake(self.mNavRightBarView.frame.size.width-50-12, 22, 50, 40);
    [self.mNavRightBarView addSubview:aLoginButton];
    self.mSignInLogInButton=aLoginButton;
    [self enableSignInLoginButton:NO];
}
*/
- (void)setSignUpDoneButtonOnNavBar
{
    //UIImage *deleteImage=[UIImage imageNamed:@"navDelete.png"];
    UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aDoneButton addTarget:self action:@selector(onClickingDoneButton) forControlEvents:UIControlEventTouchUpInside];
    [aDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    [aDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [aDoneButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    aDoneButton.titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:16.0];
    aDoneButton.frame = CGRectMake(self.mNavRightBarView.frame.size.width - 50 - 12, 22, 50, 40);
    [self.mNavRightBarView addSubview:aDoneButton];
    self.mSignUpDoneButton = aDoneButton;
    [self enableSignUpDoneButton:NO];
}

- (void)enableSignUpDoneButton:(BOOL)isEnable
{
    self.mSignUpDoneButton.enabled = isEnable;
}

- (void)enableSignInLoginButton:(BOOL)isEnable
{
    self.mSignInLogInButton.enabled = isEnable;
    if (isEnable)
    {
        //        self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:1.0];
        self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];
    }
    else
    {
        //        self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:151.0/255.0 green:151.0/255.0 blue:151.0/255.0 alpha:1.0];
        //        self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:0.2];
        //Previous color before implementing Android design
        // self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:144.0/255.0 blue:226.0/255.0 alpha:0.2];
        //Light Gray as Android design
        self.mSignInLogInButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15f];
        ;
    }

    //Disabled 151
    //Enabled 62,175,177
}

- (void)setLoginButtonBGColorForSelectedState
{
    //    self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:175.0/255.0 blue:177.0/255.0 alpha:1.0];
    self.mSignInLogInButton.backgroundColor = [UIColor colorWithRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];
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

- (void)createCancelButtonOnNavBar
{
    UIImage *backImage = [UIImage imageNamed:@"back"];
    UIButton *aCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aCancelButton addTarget:self action:@selector(onClickingCancelButton) forControlEvents:UIControlEventTouchUpInside];

    //[aCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [aCancelButton setImage:backImage forState:UIControlStateNormal];
    // [aCancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    // aCancelButton.titleLabel.font=[UIFont fontWithName:@"AvenirNextCondensed-Regular" size:16.0];
    aCancelButton.frame = CGRectMake(2, 22, backImage.size.width, backImage.size.height);
    [self.mNavLeftBarView addSubview:aCancelButton];
    self.mCancelButton = aCancelButton;
}
- (void)onClickingCancelButton
{
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

- (void)enableBackButton:(BOOL)isEnable
{
    self.leftBarBtnItem.enabled = isEnable;
    self.mCancelButton.enabled = isEnable;
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

- (void)popController
{
    [self.navigationController popViewControllerAnimated:YES];
}

//override in child controller
- (void)onClickingLoginButton
{
}

- (void)onClickingDoneButton
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
