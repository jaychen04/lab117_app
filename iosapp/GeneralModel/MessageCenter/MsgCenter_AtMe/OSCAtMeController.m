//
//  OSCAtMeController.m
//  iosapp
//
//  Created by Graphic-one on 16/8/22.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "OSCAtMeController.h"
#import "OSCAPI.h"
#import "Config.h"
#import "Utils.h"
#import "OSCPushTypeControllerHelper.h"
#import "OSCAtMeCell.h"
#import "OSCMessageCenter.h"
#import "OSCUserHomePageController.h"
#import "UIColor+Util.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "UINavigationController+Router.h"

#import <MJRefresh.h>
#import <MJExtension.h>
#import <MBProgressHUD.h>

#define ATME_HEIGHT 150

static NSString* const OSCAtMeCellReuseIdentifier = @"OSCAtMeCell";
@interface OSCAtMeController ()<UITableViewDelegate,UITableViewDataSource,OSCAtMeCellDelegate>

@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) NSMutableArray* dataSource;
@property (nonatomic,strong) NSString* nextToken;

@end

@implementation OSCAtMeController

#pragma mark --- life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"OSCAtMeCell" bundle:nil] forCellReuseIdentifier:OSCAtMeCellReuseIdentifier];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self getDataThroughDropdown:YES];
    }];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        [self getDataThroughDropdown:NO];
    }];
    [self.tableView.mj_header beginRefreshing];
}


#pragma mark --- Networking
- (void)getDataThroughDropdown:(BOOL)dropDown{//YES:下拉  NO:上拉
    NSString *strUrl = [NSString stringWithFormat:@"%@%@?uid=%llu",OSCAPI_V2_PREFIX,OSCAPI_MESSAGES_ATME_LIST,[Config getOwnID]];
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager OSCJsonManager];
    
    NSMutableDictionary* paraMutableDic = @{}.mutableCopy;
    if (!dropDown && [self.nextToken length] > 0) {
        [paraMutableDic setObject:self.nextToken forKey:@"pageToken"];
    }
    
    MBProgressHUD* HUD = [Utils createHUD];
    
    [manager GET:strUrl
      parameters:paraMutableDic.copy
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             if([responseObject[@"code"]integerValue] == 1) {
                 NSDictionary* resultDic = responseObject[@"result"];
                 NSArray* items = resultDic[@"items"];
                 if (dropDown) {
                     [self.dataSource removeAllObjects];
                     
                     if (_didRefreshSucceed) {_didRefreshSucceed();}
                 }
                 NSArray* models = [AtMeItem mj_objectArrayWithKeyValuesArray:items];
                 [self.dataSource addObjectsFromArray:models];
                 self.nextToken = resultDic[@"nextPageToken"];
                 
             }else{
                 HUD.label.text = @"未知错误";
             }
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (dropDown) {
                     [self.tableView.mj_header endRefreshing];
                 }else{
                     [self.tableView.mj_footer endRefreshing];
                 }
                 [self.tableView reloadData];
                 [HUD hideAnimated:YES afterDelay:0.3];
             });
    }
         failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (dropDown) {
                     [self.tableView.mj_header endRefreshing];
                 }else{
                     [self.tableView.mj_footer endRefreshing];
                 }
                 HUD.label.text = @"网络异常，操作失败";
                 [HUD hideAnimated:YES afterDelay:0.3];
             });
         }];

}


#pragma mark --- UITableViewDelegate & UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}
- (UITableViewCell* )tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    OSCAtMeCell* cell = [OSCAtMeCell returnReuseAtMeCellWithTableView:tableView indexPath:indexPath identifier:OSCAtMeCellReuseIdentifier];
    cell.atMeItem = self.dataSource[indexPath.row];
    cell.delegate = self;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AtMeItem* atMeItem = self.dataSource[indexPath.row];
    [self pushController:atMeItem];
}

#pragma mark --- OSCAtMeCellDelegate
- (void)atMeCellDidClickUserPortrait:(OSCAtMeCell *)cell{
    AtMeItem* atMeItem = cell.atMeItem;
    OSCUserHomePageController *userDetailsVC = [[OSCUserHomePageController alloc] initWithUserID:atMeItem.author.id];
    [self.navigationController pushViewController:userDetailsVC animated:YES];
}
- (void) shouldInteractTextView:(UITextView* )textView
                            URL:(NSURL *)URL
                        inRange:(NSRange)characterRange
{
    NSString* nameStr = [textView.text substringWithRange:characterRange];
    if ([[nameStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"@"]) {
        nameStr = [nameStr substringFromIndex:1];
        [self.navigationController handleURL:URL name:nameStr];
    }else{
        [self.navigationController handleURL:URL name:nil];
    }
}
- (void)textViewTouchPointProcessing:(UITapGestureRecognizer *)tap{
    CGPoint point = [tap locationInView:self.tableView];
    [self tableView:self.tableView didSelectRowAtIndexPath:[self.tableView indexPathForRowAtPoint:point]];
}

#pragma mark --- push type controller
- (void)pushController:(AtMeItem* )atMeItem{
    if (atMeItem.origin.originType == OSCOriginTypeLinkNews) {
        [self.navigationController handleURL:[NSURL URLWithString:atMeItem.origin.href] name:nil];
    }
    UIViewController* pushVC = [OSCPushTypeControllerHelper pushControllerWithOriginType:atMeItem.origin];
    if (pushVC == nil) {
        [self.navigationController handleURL:[NSURL URLWithString:atMeItem.origin.href] name:nil];
    }else{
        [self.navigationController pushViewController:pushVC animated:YES];
    }
}

#pragma mark --- lazy loading
- (UITableView *)tableView {
	if(_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:(CGRect){{0,0},{self.view.bounds.size.width,self.view.bounds.size.height - 100}} style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = ATME_HEIGHT;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.tableFooterView = [UIView new];
    }
	return _tableView;
}
- (NSMutableArray *)dataSource {
	if(_dataSource == nil) {
		_dataSource = [[NSMutableArray alloc] init];
	}
	return _dataSource;
}

@end
