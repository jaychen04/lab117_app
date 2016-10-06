//
//  DiscoverViewController.m
//  iosapp
//
//  Created by AeternChan on 7/16/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "DiscoverViewController.h"
#import "UIColor+Util.h"
#import "EventsViewController.h"
#import "PersonSearchViewController.h"
#import "ScanViewController.h"
#import "ShakingViewController.h"
#import "SearchViewController.h"
#import "ActivitiesViewController.h"
#import "Config.h"

#import "SwipableViewController.h"
#import "SoftwareCatalogVC.h"
#import "SoftwareListVC.h"

@interface DiscoverViewController ()

@property (nonatomic, strong) UIImageView * imageView;

@end

@implementation DiscoverViewController

- (void)dawnAndNightMode
{
    self.tableView.backgroundColor = [UIColor themeColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _imageView.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHex:0xF5F5F5];
    self.tableView.backgroundColor = [UIColor themeColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    
    _imageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 23;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    
    cell.backgroundColor = [UIColor cellsColor];
    cell.textLabel.textColor = [UIColor titleColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = @"开源软件";
            cell.imageView.image = [UIImage imageNamed:@"ic_discover_softwares"];
            break;
        case 1:
            cell.textLabel.text = @"找人";
            cell.imageView.image = [UIImage imageNamed:@"ic_discover_find"];
            
//            cell.textLabel.text = @[@"找人", @"活动"][indexPath.row];
//            cell.imageView.image = [UIImage imageNamed:@[@"discover-search", @"discover-activities"][indexPath.row]];
            break;
        case 2:
            cell.textLabel.text = @[@"扫一扫", @"摇一摇"][indexPath.row];
            cell.imageView.image = [UIImage imageNamed:@[@"ic_discover_scan", @"ic_discover_shake"][indexPath.row]];
            break;
        default: break;
    }
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:
        {
//            EventsViewController *eventsViewCtl = [EventsViewController new];
//            eventsViewCtl.needCache = YES;
//            [self.navigationController pushViewController:eventsViewCtl animated:YES];
            
            SwipableViewController *softwaresSVC = [[SwipableViewController alloc] initWithTitle:@"开源软件"
                                                                                    andSubTitles:@[@"分类", @"推荐", @"最新", @"热门", @"国产"]
                                                                                  andControllers:@[
                                                                                                   [[SoftwareCatalogVC alloc] initWithTag:0],
                                                                                                   [[SoftwareListVC alloc] initWithSoftwaresType:SoftwaresTypeRecommended],
                                                                                                   [[SoftwareListVC alloc] initWithSoftwaresType:SoftwaresTypeNewest],
                                                                                                   [[SoftwareListVC alloc] initWithSoftwaresType:SoftwaresTypeHottest],
                                                                                                   [[SoftwareListVC alloc] initWithSoftwaresType:SoftwaresTypeCN]                            ]];
            softwaresSVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:softwaresSVC animated:YES];
            break;
        }
        case 1:
            if (indexPath.row == 0) {
                PersonSearchViewController *personSearchVC = [PersonSearchViewController new];
                personSearchVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:personSearchVC animated:YES];
                break;
            }
            else if (indexPath.row == 1) {
                SwipableViewController *activitySVC = [[SwipableViewController alloc] initWithTitle:@"活动"
                                                                                       andSubTitles:@[@"近期活动", @"我的活动"]
                                                                                     andControllers:@[
                                                                                                      [[ActivitiesViewController alloc] initWithUID:0],
                                                                                                      [[ActivitiesViewController alloc] initWithUID:[Config getOwnID]
                                                                                                       ]]];
                activitySVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:activitySVC animated:YES];
                break;
            }
        case 2:
            if (indexPath.row == 0) {
                ScanViewController *scanVC = [ScanViewController new];
                UINavigationController *scanNav = [[UINavigationController alloc] initWithRootViewController:scanVC];
                [self.navigationController presentViewController:scanNav animated:NO completion:nil];
                break;
            }
            else if (indexPath.row == 1) {
                [self.navigationController pushViewController:[ShakingViewController new] animated:YES];
            }
            
        default:
            break;
    }
}

@end
