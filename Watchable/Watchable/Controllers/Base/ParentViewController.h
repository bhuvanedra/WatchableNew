//
//  ParentViewController.h
//  Watchable
//
//  Created by valtech on 19/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//
#import "WatchableConstants.h"
@interface ParentViewController : UIViewController
{
}
@property (nonatomic, assign) CGPoint scrollViewContentOffSet;
@property (nonatomic, strong) UIButton *aSaveButton;
@property (nonatomic, strong) UIView *mErrorView;
@property (nonatomic) eErrorType mErrorType;
- (void)createNavBarWithHidden:(BOOL)isHidden;
- (void)setBackButtonOnNavBar;
- (void)setBackButtonOnView;
- (void)hideBackButton:(BOOL)isHide;
- (void)hideNarBarWithShareAddButton:(BOOL)isHide;
- (void)setNavigationBarTitle:(NSString *)aString withFont:(UIFont *)aFont withTextColor:(UIColor *)aColor;
- (void)hideNarBarWithAnimation;
- (void)showNavBarWithAnimation;
- (void)setSettingsHistoryButtonOnNavBar;
- (void)setDeleteHistoryButtonOnNavBar;
- (void)setSettingsDoneButtonOnNavBar;
- (void)setShareAddButtonOnView;
- (void)setShareButtonOnView;
- (void)setSearchButtonOnNarBar;
- (void)setSettingsLogOutButtonOnNavBar;
- (void)setEditProfileButtonsOnNavBar;
- (UIButton *)mFollowButton;
- (void)enableDeleteHistoryButton:(BOOL)isEnable;
- (UIButton *)getDeleteButton;
- (void)enableEditProfileSaveButton:(BOOL)isEnable;
- (void)ShowShareButton:(BOOL)isShow;
- (void)setNavBarVisiblityWithAlpha:(float)aAlphaValue;
- (void)setFollowButtonSelectedMode:(BOOL)isSelected;
- (void)setBackButtonHide;
- (NSString *)getTrackpath;
- (UIButton *)getBackButtonRef;
@end
