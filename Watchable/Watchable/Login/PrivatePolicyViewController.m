//
//  PrivatePolicyViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 04/05/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "PrivatePolicyViewController.h"

@interface PrivatePolicyViewController () <UIWebViewDelegate>

@property BOOL allowLoad;
@end

@implementation PrivatePolicyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initalizeUISetup];
    // Do any additional setup after loading the view.
}

- (void)initalizeUISetup
{
    //self.view.backgroundColor=[UIColor greenColor];
    _allowLoad = YES;
    [self createNavBarWithHidden:NO];
    if (self.isFromSettings)
    {
        [self setBackButtonOnNavBar];
        [self hideBackButton:NO];
    }
    else
    {
        [self setSignUpDoneButtonOnNavBar];
        [self enableSignUpDoneButton:YES];
    }

    [self setNavigationBarTitle:@"Privacy Policy" withFont:nil withTextColor:nil];
    _mPrivatePolicyWebView.delegate = self;
    NSURL *localHTMLURL = [NSURL URLWithString:kPrivatePolicyWebLink];

    NSURLRequest *request = [NSURLRequest requestWithURL:localHTMLURL
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:60];
    [self.mPrivatePolicyWebView loadRequest:request];
    [self.mPrivatePolicyWebView setDataDetectorTypes:UIDataDetectorTypeNone];
    [Utilities setAppBackgroundcolorForView:self.view];
    [Utilities addGradientToView:self.view withStartGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.0] withEndGradientColor:[UIColor colorWithRed:189.0 / 255.0 green:195.0 / 255.0 blue:199.0 / 255.0 alpha:0.2]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return _allowLoad;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    _allowLoad = NO;
}

- (void)onClickingDoneButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
