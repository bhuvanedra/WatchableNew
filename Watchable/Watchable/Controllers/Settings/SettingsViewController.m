//
//  SettingsViewController.m
//  Watchable
//
//  Created by Raja Indirajith on 30/03/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "SettingsViewController.h"

#import "AnalyticsEventBodyConstructer.h"
#import "AnalyticsEventsHandler.h"
#import "ChangePasswordViewController.h"
#import "DBHandler.h"
#import "EditProfileViewController.h"
#import "EmailNotificationViewController.h"
#import "GAUtilities.h"
#import "MemoryManagement.h"
#import "PrivatePolicyViewController.h"
#import "ServerConnectionSingleton.h"
#import "SwrveUtility.h"
#import "TermsOfServiceViewController.h"
#import "UIColor+HexColor.h"
#import "UserProfile.h"
#import "Watchable-Swift.h"

@import MessageUI;

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, EditProfileViewControllerDelegate>
@property (nonatomic, strong) NSArray *mSettingsDataSource;
@property (weak, nonatomic) IBOutlet UITableView *settingsTable;
@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.isPushedForConfirmEmail)
    {
        [self pushEditProfileForEmailWithEmailConfirmation:YES];
        self.isPushedForConfirmEmail = NO;
    }
    [self initialSetUp];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"SettingsScreen"];
}

- (void)initialSetUp
{
    self.view.backgroundColor = [UIColor colorFromHexString:@"#1B1D1E"];
    [self createNavBarWithHidden:NO];
    [self setBackButtonOnNavBar];
    //[self setSettingsDoneButtonOnNavBar];
    [self setNavigationBarTitle:kNavTitleSettings withFont:nil withTextColor:nil];

    // NSDictionary *aAccountDict=[NSDictionary dictionaryWithObjectsAndKeys:@[@"Edit Profile",@"Change Password"],@"ACCOUNT",nil];

    NSDictionary *aAccountDict = [NSDictionary dictionaryWithObjectsAndKeys:@[ @"Username", @"Email", @"Change Password" ], @"ACCOUNT", nil];

    // NSDictionary *aNotificationDict=[NSDictionary dictionaryWithObjectsAndKeys:@[@"Email",@"Push"],@"NOTIFICATIONS",nil];

    NSDictionary *aSupportDict = [NSDictionary dictionaryWithObjectsAndKeys:@[ @"Terms of Service", @"Privacy Policy", @"Feedback", @"AdChoices", @"Version" ], @"SUPPORT", nil];

    //NSDictionary *aPreferences= @{@"PREFERENCES":@[@"AdChoices"]};

    self.mSettingsDataSource = [NSArray arrayWithObjects:aAccountDict, aSupportDict, nil];
    [self.settingsTable setTintColor:[UIColor colorFromHexString:@"#6A6E71"]];
    _settingsTable.backgroundColor = [UIColor colorFromHexString:@"#1B1D1E"];
    _settingsTable.scrollEnabled = YES;

    //Set Copyright Text
    CGRect footerRect = CGRectMake(0, 0, 320, 40);
    UILabel *tableFooter = [[UILabel alloc] initWithFrame:footerRect];
    tableFooter.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
    tableFooter.textAlignment = NSTextAlignmentCenter;
    tableFooter.textColor = [UIColor colorFromHexString:@"#6A6E71"];
    tableFooter.backgroundColor = [self.settingsTable backgroundColor];
    tableFooter.opaque = YES;
    tableFooter.text = @"© 2016 Comcast. All rights reserved.";
    self.settingsTable.tableFooterView = tableFooter;
}

- (void)onClickingSettingsDoneButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickingSettingsLogoutButton
{
    WATCHABLE_WEAK_SELF;

    UIAlertController *alert = [AlertFactory logoutWithLogoutButtonTappedHandler:^(UIAlertAction *logoutAction) {
      WATCHABLE_STRONG_SELF_OR_RETURN;

      [strongSelf onClickingLogoutButton];
    }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onClickingLogoutButton
{
    __weak SettingsViewController *weakSelf = self;
    [[ServerConnectionSingleton sharedInstance] sendRequestToLogOutwithResponseBlock:^(NSDictionary *responseDict) {
      NSNumber *aStatus = [responseDict objectForKey:@"isLogoutSuccess"];

      if (aStatus.boolValue)
      {
          [SwrveUtility updateSwrveUserProperty:NO];
          [[AnalyticsEventsHandler sharedInstance] postAnalyticsGeneralForEventType:kEventTypeUserAction eventName:kEventNameSignOut andUserId:[Utilities getCurrentUserId]];
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self performSelector:@selector(setLoginAsRootViewController) withObject:nil afterDelay:0.0];
          }];
      }

    }
        errorBlock:^(NSError *error) {

          [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            //            NSString *aErrorMsg=error.localizedDescription;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.text=aErrorMsg;
            //            weakSelf.mErrorMsgLabel.hidden=NO;
            if (weakSelf)
            {
                if (error.code == kErrorCodeNotReachable)
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:InternetFailureWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                else /*if(error.code==kServerErrorCode)*/
                {
                    [kSharedApplicationDelegate createErrorViewForController:weakSelf withErrorType:ServiceErrorWithTryAgainMessage withTryAgainSelector:nil withInputParameters:nil];
                }
                /*  else
                 {
                 NSString *aErrorMsg=error.localizedDescription;
                 weakSelf.mErrorMsgLabel.text=aErrorMsg;
                 weakSelf.mErrorMsgLabel.text=aErrorMsg;
                 weakSelf.mErrorMsgLabel.hidden=NO;
                 }*/
            }
          }];

          NSLog(@"error block=%@,%@", error.localizedDescription, error.localizedFailureReason);
        }];
}

- (void)setLoginAsRootViewController
{
    [kSharedApplicationDelegate setLoginNavControllerAsRootViewController];
}

#pragma mark -
#pragma mark UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.mSettingsDataSource.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *keys = [[[self.mSettingsDataSource objectAtIndex:section] allKeys] objectAtIndex:0];
    return [[[self.mSettingsDataSource objectAtIndex:section] objectForKey:keys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *aCellIdentifier = nil;
    aCellIdentifier = @"settingsCell";

    if (indexPath.section == 1 && indexPath.row == 4)
        aCellIdentifier = @"settingsCellForVersion";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:aCellIdentifier];

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:aCellIdentifier];
        if (indexPath.section == 1 && indexPath.row == 4)
        {
            UILabel *version = [[UILabel alloc] init];
            CGFloat width = [UIScreen mainScreen].bounds.size.width;

            version.frame = CGRectMake(width - 100, 7, 80, 45);

            version.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
            version.textColor = [UIColor colorFromHexString:@"#6A6E71"];
            version.text = [Utilities getVersionOfApplicationFromPlist];
            version.textAlignment = NSTextAlignmentRight;
            [cell.contentView addSubview:version];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self.settingsTable setSeparatorColor:[UIColor blackColor]];
    cell.backgroundColor = [UIColor colorFromHexString:@"#1B1D1E"];
    cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    NSString *keys = [[[self.mSettingsDataSource objectAtIndex:indexPath.section] allKeys] objectAtIndex:0];
    cell.textLabel.text = [[[self.mSettingsDataSource objectAtIndex:indexPath.section] objectForKey:keys] objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor colorFromHexString:@"#F1F1F1"];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.tintColor = [UIColor colorFromHexString:@"#6A6E71"];

    UserProfile *aUserProfile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];

    cell.detailTextLabel.text = @"";

    if (indexPath.section == 0 && indexPath.row == 0)
    {
        cell.detailTextLabel.text = aUserProfile.mUserName;
        cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    }

    if (indexPath.section == 0 && indexPath.row == 1)
    {
        cell.detailTextLabel.text = aUserProfile.mUserEmail;
        cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    }

    if (indexPath.section == 1 && indexPath.row == 3)
    {
        //cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (indexPath.section == 1 && indexPath.row == 4)
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerText = [[UILabel alloc] init];
    headerText.frame = CGRectMake(16, 10, self.view.frame.size.width, 20);
    headerText.font = [UIFont fontWithName:@"AvenirnextCondensed-DemiBold" size:16];
    headerText.textColor = [UIColor colorFromHexString:@"#6A6E71"];
    headerText.text = [[[self.mSettingsDataSource objectAtIndex:section] allKeys] objectAtIndex:0];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];

    headerView.backgroundColor = [UIColor colorFromHexString:@"#000000"];
    [headerView addSubview:headerText];

    return headerView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section)
    {
        case 0:
            switch (indexPath.row)
            {
                case 0:
                {
                    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                    EditProfileViewController *editDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"EditProfileViewController"];
                    editDetailViewController.isEditUserName = YES;
                    editDetailViewController.mDelegate = self;
                    [self.navigationController pushViewController:editDetailViewController animated:YES];
                }
                break;

                case 1:
                {
                    [self pushEditProfileForEmailWithEmailConfirmation:NO];
                }
                break;

                case 2:
                {
                    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

                    ChangePasswordViewController *changePasswordViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"ChangePasswordViewController"];
                    [self.navigationController pushViewController:changePasswordViewController animated:YES];
                }
                break;

                default:
                    break;
            }
            break;

        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

                    TermsOfServiceViewController *aTermsOfServiceViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"TermsOfServiceViewController"];
                    aTermsOfServiceViewController.isFromSettings = YES;
                    [self.navigationController pushViewController:aTermsOfServiceViewController animated:YES];
                }
                break;
                case 2:
                {
                    if ([MFMailComposeViewController canSendMail])
                    {
                        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
                        mail.mailComposeDelegate = self;
                        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
                        NSString *appVersion = [Utilities getVersionOfApplicationFromPlist];

                        NSString *appDeviceName = [[AnalyticsEventBodyConstructer sharedInstance] platformNiceString];
                        NSString *appDeviceOS = [[UIDevice currentDevice] systemVersion];
                        NSString *appMemoryFree = [NSByteCountFormatter stringFromByteCount:[self getFreeDiskspace] countStyle:NSByteCountFormatterCountStyleFile];
                        NSString *appMemoryTotal = [NSByteCountFormatter stringFromByteCount:[self getTotalDiskspace] countStyle:NSByteCountFormatterCountStyleFile];

                        UserProfile *aUserProfile = [[DBHandler sharedInstance] getCurrentLoggedInUserProfile];
                        NSString *appAccountEmailID = aUserProfile.mUserEmail;

                        NSString *appDeviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];

                        NSString *mailbody = [NSString stringWithFormat:@"Please take a moment to share your thoughts or experiences with us \n\n\n\n%@\n%@\n\n%@,iOS %@\n%@ free,%@ total\n\nAccount: %@\nDevice Id: %@", appName, appVersion, appDeviceName, appDeviceOS, appMemoryFree, appMemoryTotal, appAccountEmailID, appDeviceId];
                        [mail setSubject:@"iPhone"];
                        [mail setMessageBody:mailbody isHTML:NO];
                        [mail setToRecipients:@[ kFeedBackEmailId ]];
                        // [mail setCcRecipients:@[kFeedBackEmailCc]];

                        [self presentViewController:mail animated:YES completion:NULL];
                    }
                    else
                    {
                        [self presentViewController:[AlertFactory emailNotSetUp] animated:YES completion:nil];
                    }
                }
                break;

                case 3:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.aboutads.info/appchoices"]];
                    break;
                case 1:
                {
                    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];

                    PrivatePolicyViewController *aPrivatePolicyViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"PrivatePolicyViewController"];

                    aPrivatePolicyViewController.isFromSettings = YES;
                    [self.navigationController pushViewController:aPrivatePolicyViewController animated:YES];
                }
                break;

                default:
                    break;
            }
        }
        break;
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.aboutads.info/appchoices"]];
                    break;

                default:
                    break;
            }
        }
        break;
        default:
            break;
    }
    //    if (indexPath.section == 0 && indexPath.row == 0) {
    //
    //        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //        EditProfileViewController *editDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"EditProfileViewController"];
    //        [self.navigationController pushViewController:editDetailViewController animated:YES];
    //    }else if (indexPath.section == 1&& indexPath.row ==0){
    //
    //
    //        UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //
    //        EmailNotificationViewController *emailDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"EmailViewController"];
    //        [self.navigationController pushViewController:emailDetailViewController animated:YES];
    //
    //    }else if (indexPath.section == 2){
    //
    //
    //
    //    }
}

- (void)pushEditProfileForEmailWithEmailConfirmation:(BOOL)isConfirmEmail
{
    UIStoryboard *aStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    EditProfileViewController *editDetailViewController = [aStoryboard instantiateViewControllerWithIdentifier:@"EditProfileViewController"];
    editDetailViewController.isEditUserName = NO;
    editDetailViewController.mDelegate = self;
    editDetailViewController.isFromConfirmEmail = isConfirmEmail;
    [self.navigationController pushViewController:editDetailViewController animated:!isConfirmEmail];
}

- (uint64_t)getFreeDiskspace
{
    // uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];

    if (dictionary)
    {
        //  NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        //   totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        // NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    }
    else
    {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }

    return totalFreeSpace;
}

- (uint64_t)getTotalDiskspace
{
    uint64_t totalSpace = 0;
    //uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];

    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
        //NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        //totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        // NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    }
    else
    {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }

    return totalSpace;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
    {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)profileUpdated
{
    [self performSelectorOnMainThread:@selector(updateEditedProfile) withObject:nil waitUntilDone:NO];
}

- (void)updateEditedProfile
{
    [self.settingsTable reloadData];
}

- (void)dealloc
{
    self.settingsTable.delegate = nil;
    self.settingsTable.dataSource = nil;
    self.mSettingsDataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Tracking protocal

- (NSString *)generateTrackingPath
{
    return @"Settings";
}

@end
