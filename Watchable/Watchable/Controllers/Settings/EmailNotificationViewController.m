//
//  EmailViewController.m
//  Watchable
//
//  Created by Abhilash on 5/18/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "EmailNotificationViewController.h"
#import "EmailNotificationTableViewCell.h"
#import "UIColor+HexColor.h"
#import "GAUtilities.h"
@interface EmailNotificationViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *emailTable;
@end

@implementation EmailNotificationViewController

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor blackColor];
    [super viewDidLoad];

    [self createNavBarWithHidden:NO];
    [self setBackButtonOnNavBar];

    [self setNavigationBarTitle:@"EMAIL" withFont:nil withTextColor:nil];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAUtilities setWatchbaleScreenName:@"NotificationsSettingScreen"];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor colorFromHexString:@"#1B1D1E"];
    self.navigationController.navigationBar.translucent = NO;
    //    self.navigationItem.title = @" ";
    self.emailTable.contentInset = UIEdgeInsetsMake(1.5, 0, 0, 0);
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    tableView.backgroundColor = [UIColor blackColor];

    UIView *view = [[UIView alloc] init];
    tableView.tableFooterView = view;
    view = nil;
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EmailNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmailCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    [self.emailTable setSeparatorColor:[UIColor blackColor]];
    cell.txtlable.text = [NSString stringWithFormat:@" Notification %ld", indexPath.row + 1];

    cell.txtlable.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    cell.backgroundColor = [UIColor colorFromHexString:@"#1B1D1E"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if (indexPath.row % 2 == 0)
    {
        [cell.cellSwitch setOn:YES];

        [cell.cellSwitch setTintColor:[UIColor greenColor]];
    }
    else
    {
        [cell.cellSwitch setOn:NO];
        [cell.cellSwitch setTintColor:[UIColor whiteColor]];
    }
    return cell;
}
- (void)switchChanged:(id)sender
{
    UISwitch *switch_ = (UISwitch *)sender;
    if (!switch_.isOn)
        switch_.tintColor = [UIColor whiteColor];
}
@end
