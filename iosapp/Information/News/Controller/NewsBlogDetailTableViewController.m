//
//  NewsBlogDetailTableViewController.m
//  iosapp
//
//  Created by 巴拉提 on 16/5/30.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "NewsBlogDetailTableViewController.h"
#import "FollowAuthorTableViewCell.h"
#import "TitleInfoTableViewCell.h"
#import "webAndAbsTableViewCell.h"
#import "RecommandBlogTableViewCell.h"
#import "ContentWKWebViewCell.h"
#import "NewCommentCell.h"
#import "RelatedSoftWareCell.h"
#import "UIColor+Util.h"
#import "OSCAPI.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "OSCBlogDetail.h"
#import "Utils.h"
#import "Config.h"
#import "OSCBlog.h"
#import "OSCSoftware.h"
#import "DetailsViewController.h"
#import "OSCNewHotBlogDetails.h"
#import "OSCInformationDetails.h"
#import "ActivityDetailViewController.h"
#import "TranslationViewController.h"
#import "QuesAnsDetailViewController.h"
#import "CommentsBottomBarViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "NewCommentListViewController.h"//新评论列表
#import "SoftWareViewController.h"      //软件详情
#import "OSCUserHomePageController.h"
#import "UIDevice+SystemInfo.h"

#import "IMYWebView.h"
#import <MJExtension.h>
#import <MBProgressHUD.h>
#import <AFNetworking.h>
#import <UITableView+FDTemplateLayoutCell.h>
#import "UMSocial.h"


static NSString *followAuthorReuseIdentifier = @"FollowAuthorTableViewCell";
static NSString *titleInfoReuseIdentifier = @"TitleInfoTableViewCell";
static NSString *recommandBlogReuseIdentifier = @"RecommandBlogTableViewCell";
static NSString *abstractReuseIdentifier = @"abstractTableViewCell";
static NSString *contentWKWebReuseIdentifier = @"ContentWKWebViewCell";
static NSString *newCommentReuseIdentifier = @"NewCommentCell";
static NSString *relatedSoftWareReuseIdentifier = @"RelatedSoftWareCell";

#define Large_Frame  (CGRect){{0,0},{40,25}}
#define Medium_Frame (CGRect){{0,0},{30,25}}
#define Small_Frame  (CGRect){{0,0},{25,25}}


@interface NewsBlogDetailTableViewController () < UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate,UITextViewDelegate,IMYWebViewDelegate>

@property (nonatomic)int64_t blogId;
@property (nonatomic, strong) OSCBlogDetail *blogDetails;
@property (nonatomic, strong) NSMutableArray *blogDetailComments;
@property (nonatomic, strong) NSMutableArray *blogDetailRecommends;

@property (nonatomic)int64_t newsId;
@property (nonatomic, strong) OSCInformationDetails *newsDetails;
@property (nonatomic, strong) NSMutableArray *newsDetailRecommends;
@property (nonatomic, strong) NSMutableArray *newsDetailComments;
@property (nonatomic) BOOL isExistRelatedSoftware;      //存在相关软件的信息

//被评论的某条评论的信息
@property (nonatomic) NSInteger beRepliedCommentAuthorId;
@property (nonatomic) NSInteger beRepliedCommentId;

@property (nonatomic, assign) CGFloat webViewHeight;
@property (nonatomic, strong) MBProgressHUD *hud;

//软键盘size
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic,strong) OSCNewHotBlogDetails *detail;
@property (nonatomic, copy) NSString *mURL;
@property (nonatomic, assign) BOOL isReply;
@property (nonatomic, assign) NSInteger selectIndexPath;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@property (nonatomic, strong) UIButton *rightBarBtn;

@property (nonatomic,assign) CGPoint readingOffest;
@property (nonatomic,assign) BOOL isReboundTop;
@end




@implementation NewsBlogDetailTableViewController{
    BOOL _isFinshDisplayH5;
    ContentWKWebViewCell* _WKWebViewCell;
}

-(instancetype) initWithObjectId:(NSInteger)objectId
                    isBlogDetail:(BOOL)isBlogDetail {
    if(self) {
        if (isBlogDetail) {
            self.blogId = objectId;
            _blogDetailRecommends = [NSMutableArray new];
            _blogDetailComments = [NSMutableArray new];
        }else {
            self.newsId = objectId;
            _newsDetailRecommends = [NSMutableArray new];
            _newsDetailComments = [NSMutableArray new];
        }
        self.isBlogDetail = isBlogDetail;
    }
    return self;
}

- (void)showHubView {
    UIView *coverView = [[UIView alloc]initWithFrame:self.view.bounds];
    coverView.backgroundColor = [UIColor whiteColor];
    coverView.tag = 10;
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    _hud = [[MBProgressHUD alloc] initWithView:window];
    _hud.detailsLabel.font = [UIFont boldSystemFontOfSize:16];
    [window addSubview:_hud];
    [self.view addSubview:coverView];
    [_hud showAnimated:YES];
    _hud.removeFromSuperViewOnHide = YES;
    _hud.userInteractionEnabled = NO;
}
- (void)hideHubView {
    [_hud hideAnimated:YES];
    [[self.view viewWithTag:10] removeFromSuperview];
}
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _isFinshDisplayH5 = NO;
    
    self.title = _isBlogDetail?@"博文":@"资讯";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.commentTextField.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FollowAuthorTableViewCell" bundle:nil] forCellReuseIdentifier:followAuthorReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"TitleInfoTableViewCell" bundle:nil] forCellReuseIdentifier:titleInfoReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommandBlogTableViewCell" bundle:nil] forCellReuseIdentifier:recommandBlogReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"webAndAbsTableViewCell" bundle:nil] forCellReuseIdentifier:abstractReuseIdentifier];
    [self.tableView registerClass:[ContentWKWebViewCell class] forCellReuseIdentifier:contentWKWebReuseIdentifier];
    [self.tableView registerClass:[NewCommentCell class] forCellReuseIdentifier:newCommentReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"RelatedSoftWareCell" bundle:nil] forCellReuseIdentifier:relatedSoftWareReuseIdentifier];
    self.tableView.estimatedRowHeight = 250;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorColor = [UIColor separatorColor];
    
    
    _rightBarBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightBarBtn.userInteractionEnabled = YES;
//    _rightBarBtn.frame  = CGRectMake(0, 0, 27, 20);
    _rightBarBtn.hidden = YES;
    _rightBarBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_rightBarBtn addTarget:self action:@selector(rightBarButtonScrollToCommitSection) forControlEvents:UIControlEventTouchUpInside];
    [_rightBarBtn setTitle:@"" forState:UIControlStateNormal];
    _rightBarBtn.titleEdgeInsets = UIEdgeInsetsMake(-4, 0, 0, 0);
    [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_appbar"] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightBarBtn];
//    self.navigationItem.rightBarButtonItem.target = self;
//    self.navigationItem.rightBarButtonItem.action = @selector(rightBarButtonClicked);

//    _rightBarBtn.hidden = NO;
    
    // 添加等待动画
    [self showHubView];
    
    if (_isBlogDetail) {
        [self getBlogData];
    }else {
        [self getNewsData];
        [self getNewsComments];
    }
    
    //软键盘
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self hideHubView];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 右导航栏按钮
- (void)rightBarButtonScrollToCommitSection
{
    if (self.isReboundTop == NO) {
        self.readingOffest = self.tableView.contentOffset;
//        NSUInteger commentCount = _isBlogDetail ? _blogDetails.commentCount : _newsDetails.commentCount;
//        if (commentCount > 0) {
            NSIndexPath* lastSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.tableView.numberOfSections - 1)];
            [self.tableView scrollToRowAtIndexPath:lastSectionIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
//        }
    }else{
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
//        跳转到reading位置
//        [self.tableView setContentOffset:self.readingOffest animated:YES];
    }
    
    self.isReboundTop = !self.isReboundTop;
    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"举报"
//                                                        message:[NSString stringWithFormat:@"链接地址：%@", _blogDetails.href]
//                                                       delegate:self
//                                              cancelButtonTitle:@"取消"
//                                              otherButtonTitles:@"确定", nil];
//    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//    [alertView textFieldAtIndex:0].placeholder = @"举报原因";
//    if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode)
//    {
//        [alertView textFieldAtIndex:0].keyboardAppearance = UIKeyboardAppearanceDark;
//    }
//    [alertView show];
}

#pragma mark -- 获取评论cell的高度
- (NSInteger)getCommentCellHeightWithComment:(OSCNewComment*)comment {
    return UITableViewAutomaticDimension;
}
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
        
        [manager POST:@"http://www.oschina.net/action/communityManage/report"
           parameters:@{
                        @"memo":        [alertView textFieldAtIndex:0].text.length == 0? @"其他原因": [alertView textFieldAtIndex:0].text,
                        @"obj_id":      @(_blogDetails.id),
                        @"obj_type":    @"2",
                        @"reason":      @"4",
                        @"url":         _blogDetails.href
                        }
              success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.label.text = @"举报成功";
                  
                  [HUD hideAnimated:YES afterDelay:1];
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
//                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.label.text = @"网络异常，操作失败";
                  
                  [HUD hideAnimated:YES afterDelay:1];
              }];
    }
}

#pragma mark - 软键盘隐藏
- (void)keyBoardHiden:(UITapGestureRecognizer *)tap
{
    [_commentTextField resignFirstResponder];
    [self.view removeGestureRecognizer:_tap];
}

#pragma mark - 获取博客详情
-(void)getBlogData{
    
    NSString *blogDetailUrlStr = [NSString stringWithFormat:@"%@blog?id=%lld", OSCAPI_V2_PREFIX, self.blogId];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:blogDetailUrlStr
     parameters:nil
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            if ([responseObject[@"code"]integerValue] == 1) {
                _blogDetails = [OSCBlogDetail mj_objectWithKeyValues:responseObject[@"result"]];
                _blogDetailRecommends = [OSCBlogDetailRecommend mj_objectArrayWithKeyValuesArray:_blogDetails.abouts];
                _blogDetailComments = [OSCNewComment mj_objectArrayWithKeyValuesArray:_blogDetails.comments];
                
                NSDictionary *data = @{@"content":  _blogDetails.body};
                _blogDetails.body = [Utils HTMLWithData:data
                                          usingTemplate:@"blog"];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFavButtonWithIsCollected:_blogDetails.favorite];
                [self updateRightButton:_blogDetails.commentCount isNewsDetail:NO];
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}

#pragma mark - 获取资讯详情
-(void)getNewsData{
    //    74510
    NSString *newsDetailUrlStr = [NSString stringWithFormat:@"%@news?id=%lld", OSCAPI_V2_PREFIX, self.newsId];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:newsDetailUrlStr
     parameters:nil
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if ([responseObject[@"code"]integerValue] == 1) {
                _newsDetails = [OSCInformationDetails mj_objectWithKeyValues:responseObject[@"result"]];
                _newsDetailRecommends= [OSCBlogDetailRecommend mj_objectArrayWithKeyValuesArray:_newsDetails.abouts];
                NSDictionary *data = @{@"content":  _newsDetails.body?:@""};
                _newsDetails.body = [Utils HTMLWithData:data
                                          usingTemplate:@"blog"];
                
                _isExistRelatedSoftware = _newsDetails.software.allKeys.count > 0;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFavButtonWithIsCollected:_newsDetails.favorite];
                [self updateRightButton:_newsDetails.commentCount isNewsDetail:YES];
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}

#pragma mark - 获取资讯详情评论
-(void)getNewsComments{
    NSString *newsDetailUrlStr = [NSString stringWithFormat:@"%@comment", OSCAPI_V2_PREFIX];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:newsDetailUrlStr
     parameters:@{@"pageToken":@"",
                  @"sourceId":@(self.newsId),
                  @"type":@(6),
                  @"parts":@"refer,reply",
                  }
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if ([responseObject[@"code"]integerValue] == 1) {
                _newsDetailComments = [OSCNewComment mj_objectArrayWithKeyValuesArray:responseObject[@"result"][@"items"]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}


#pragma mark -- DIY_headerView
- (UIView*)headerViewWithSectionTitle:(NSString*)title {
    
        UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen]bounds]), 32)];
        headerView.backgroundColor = [UIColor colorWithHex:0xf9f9f9];
        
        UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen]bounds]), 0.5)];
        topLineView.backgroundColor = [UIColor separatorColor];
        [headerView addSubview:topLineView];
        
        UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 31, CGRectGetWidth([[UIScreen mainScreen]bounds]), 0.5)];
        bottomLineView.backgroundColor = [UIColor separatorColor];
        [headerView addSubview:bottomLineView];
        
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(16, 0, 100, 16)];
        titleLabel.center = CGPointMake(titleLabel.center.x, headerView.center.y);
        titleLabel.tag = 8;
        titleLabel.textColor = [UIColor colorWithHex:0x6a6a6a];
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.text = title;
        [headerView addSubview:titleLabel];

    return headerView;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionNumber = 1;
    if (_isBlogDetail) {    //博客详情
        if (_blogDetailComments.count > 0) {
            sectionNumber += 1;
        }
        if (_blogDetailRecommends.count > 0) {
            sectionNumber += 1;
        }
    }else {     //资讯详情
        if (_isExistRelatedSoftware) {
            sectionNumber += 1;
        }
        if (_newsDetails.abouts.count > 0) {
            sectionNumber += 1;
        }
        if (_newsDetailComments.count > 0) {
            sectionNumber += 1;
        }
    }
    
    return sectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isBlogDetail) {        //博客详情
        switch (section) {
            case 0:
            {
                return _blogDetails.abstract.length?4:3;
                break;
            }
            case 1://相关文章
            {
                if (_blogDetailRecommends.count > 0) {
                    return _blogDetailRecommends.count;
                }else {
                    return _blogDetailComments.count;
                }
                break;
            }
            case 2://评论
            {
                return _blogDetailComments.count+1;
                break;
            }
            default:
                break;
        }
    }else {     //资讯详情
        switch (section) {
            case 0:
            {
                return 2;
                break;
            }
            case 1://与资讯有关的软件信息
            {
                NSInteger rows = 0;
                if (_isExistRelatedSoftware) {
                    return rows = 1;
                }else if (_newsDetails.abouts.count > 0){
                    return rows = _newsDetails.abouts.count;
                }else if (_newsDetailComments.count > 0) {
                    return _newsDetailComments.count+1;
                }
                break;
            }
            case 2://相关资讯
            {
                return _isExistRelatedSoftware && _newsDetails.abouts.count > 0?_newsDetails.abouts.count:_newsDetailComments.count+1;
                break;
            }
            case 3://评论
            {
                return _newsDetailComments.count+1;
                break;
            }
            default:
                break;
        }
    }
    return 0;
}


- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_isBlogDetail) {    //博客详情
        if (section == 1) {
            if (_blogDetailRecommends.count > 0) {
                return [self headerViewWithSectionTitle:@"相关文章"];
            }else {
                return [self headerViewWithSectionTitle:@"评论"];
            }
            
        }else if (section == 2) {
            if (_blogDetailComments.count > 0) {
                return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"评论(%lu)", (unsigned long)_blogDetailComments.count]];
            }
            return [self headerViewWithSectionTitle:@"评论"];
        }
    }else {     //资讯详情
        if (section == 1) {
            if (_isExistRelatedSoftware) {
                return [self headerViewWithSectionTitle:@"相关软件"];
            }else if (_newsDetails.abouts.count > 0){
                return [self headerViewWithSectionTitle:@"相关资讯"];
            }else if (_newsDetailComments.count > 0) {
                return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"评论(%lu)", (unsigned long)_newsDetails.commentCount]];
            }
        }else if (section == 2) {
            if (_isExistRelatedSoftware && _newsDetails.abouts.count > 0) {
                return [self headerViewWithSectionTitle:@"相关资讯"];
            }else {
                if (_newsDetails.commentCount > 0) {
                    return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"评论(%lu)", (unsigned long)_newsDetails.commentCount]];
                }
                return [self headerViewWithSectionTitle:@"评论"];
            }
            
        }else if (section == 3) {
            if (_newsDetails.commentCount > 0) {
                return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"评论(%lu)", (unsigned long)_newsDetails.commentCount]];
            }
            return [self headerViewWithSectionTitle:@"评论"];
        }
    }
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isBlogDetail) {        //博客详情
        switch (indexPath.section) {
            case 0:
            {
                switch (indexPath.row) {
                    case 0:
                        return [tableView fd_heightForCellWithIdentifier:followAuthorReuseIdentifier configuration:^(FollowAuthorTableViewCell *cell) {
                            cell.blogDetail = _blogDetails;
                        }];
                        break;
                    case 1:
                        return [tableView fd_heightForCellWithIdentifier:titleInfoReuseIdentifier configuration:^(TitleInfoTableViewCell *cell) {
                            cell.blogDetail = _blogDetails;
                            
                        }];
                        break;
                    case 2:
                    {
                        if (_blogDetails.abstract.length > 0) {
                            return [tableView fd_heightForCellWithIdentifier:abstractReuseIdentifier configuration:^(webAndAbsTableViewCell *cell) {
                                [cell setAbstractText:_blogDetails.abstract];
                            }];
                        } else if (_blogDetails.abstract.length == 0) {
                            return _webViewHeight+30;
                        }
                        break;
                    }
                    case 3:
                        return _webViewHeight+30;
                        break;
                    default:
                        break;
                }
                break;
            }
            case 1:
            {
                if (_blogDetailRecommends.count > 0) {
                    return indexPath.row == _blogDetailRecommends.count-1 ? 72 : 60;
                }else {
                    if (_blogDetailComments.count > 0) {
                        if (indexPath.row == _blogDetailComments.count) {
                            return 44;
                        } else {
                            return [self getCommentCellHeightWithComment:_blogDetailComments[indexPath.row]];
                        }
                    }
                }
                break;
            }
            case 2:
            {
                if (_blogDetailComments.count > 0) {
                    if (indexPath.row == _blogDetailComments.count) {
                        return 44;
                    } else {
                        return [self getCommentCellHeightWithComment:_blogDetailComments[indexPath.row]];
                    }
                }
                return 44;
                break;
            }
            default:
                break;
        }
    }else {     //资讯详情
        switch (indexPath.section) {
            case 0:
            {
                switch (indexPath.row) {
                    case 0:
                        return [tableView fd_heightForCellWithIdentifier:titleInfoReuseIdentifier configuration:^(TitleInfoTableViewCell *cell) {
                            cell.newsDetail = _newsDetails;
                            
                        }];
                        break;
                    case 1:
                        return _webViewHeight+30;
                        break;
                    default:
                        break;
                }
                break;
            }
            case 1:
            {
                if (_isExistRelatedSoftware) {
                    return 45;
                }else if (_newsDetails.abouts.count > 0){
                    return indexPath.row == _newsDetails.abouts.count-1 ? 72 : 60;
                }else if (_newsDetailComments.count > 0) {
                    if (_newsDetailComments.count > 0) {
                        if (indexPath.row == _newsDetailComments.count) {
                            return 44;
                        } else {
                            return [self getCommentCellHeightWithComment:_newsDetailComments[indexPath.row]];
                        }
                    }
                }
                
                break;
            }
            case 2:
            {
                if (_isExistRelatedSoftware && _newsDetails.abouts.count > 0) {
                    return indexPath.row == _newsDetails.abouts.count-1 ? 72 : 60;
                }else {
                    if (_newsDetailComments.count > 0) {
                        if (indexPath.row == _newsDetailComments.count) {
                            return 44;
                        } else {
                            return [self getCommentCellHeightWithComment:_newsDetailComments[indexPath.row]];
                        }
                    }
                }
                
                break;
            }
            case 3: {
                if (_newsDetailComments.count > 0) {
                    if (indexPath.row == _newsDetailComments.count) {
                        return 44;
                    } else {
                        return [self getCommentCellHeightWithComment:_newsDetailComments[indexPath.row]];
                    }
                }
            }
            default:
                break;
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section != 0 ? 32 : 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isBlogDetail) {
        switch (indexPath.section) {
            case 0: {
                if (indexPath.row==0) {
                    FollowAuthorTableViewCell *followAuthorCell = [tableView dequeueReusableCellWithIdentifier:followAuthorReuseIdentifier forIndexPath:indexPath];
                    followAuthorCell.blogDetail = _blogDetails;
                    
                    followAuthorCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [followAuthorCell.followBtn addTarget:self action:@selector(favSelected) forControlEvents:UIControlEventTouchUpInside];
                    
                    return followAuthorCell;
                } else if (indexPath.row==1) {
                    TitleInfoTableViewCell *titleInfoCell = [tableView dequeueReusableCellWithIdentifier:titleInfoReuseIdentifier forIndexPath:indexPath];
                    titleInfoCell.blogDetail = _blogDetails;
                    
                    titleInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return titleInfoCell;
                } else if (indexPath.row == 2) {
                    if (_blogDetails.abstract.length > 0) {
                        webAndAbsTableViewCell *abstractCell = [tableView dequeueReusableCellWithIdentifier:abstractReuseIdentifier forIndexPath:indexPath];
//                        abstractCell.abstractLabel.text = _blogDetails.abstract;
                        [abstractCell setAbstractText:_blogDetails.abstract];
                        abstractCell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        return abstractCell;
                        
                    } else {
                        ContentWKWebViewCell *webViewCell = [tableView dequeueReusableCellWithIdentifier:contentWKWebReuseIdentifier forIndexPath:indexPath];
                        _WKWebViewCell = webViewCell;
                        webViewCell.contentWebView.delegate = self;
                            if (_blogDetails.body.length > 0 ) {
                                [webViewCell.contentWebView loadHTMLString:_blogDetails.body baseURL:[NSBundle mainBundle].resourceURL];
                            }
                        webViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        return webViewCell;
                    }
                } else if (indexPath.row == 3) {
                    ContentWKWebViewCell *webViewCell = [tableView dequeueReusableCellWithIdentifier:contentWKWebReuseIdentifier forIndexPath:indexPath];
                    _WKWebViewCell = webViewCell;
                    webViewCell.contentWebView.delegate = self;
                    [webViewCell.contentWebView loadHTMLString:_blogDetails.body baseURL:[NSBundle mainBundle].resourceURL];
                    webViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return webViewCell;
                }
                
            }
                break;
            case 1: {
                if (_blogDetailRecommends.count > 0) {
                    RecommandBlogTableViewCell *recommandBlogCell = [tableView dequeueReusableCellWithIdentifier:recommandBlogReuseIdentifier forIndexPath:indexPath];
                    
                    if (_blogDetailRecommends.count > 0) {
                        OSCBlogDetailRecommend *about = _blogDetailRecommends[indexPath.row];
                        recommandBlogCell.abouts = about;
                        recommandBlogCell.hiddenLine = _blogDetailRecommends.count - 1 == indexPath.row ? YES : NO;
                    }
                    
                    recommandBlogCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    
                    return recommandBlogCell;
                }else {
                    if (_blogDetailComments.count > 0) {
                        if (indexPath.row == _blogDetailComments.count) {
                            UITableViewCell *cell = [UITableViewCell new];
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                            cell.textLabel.text = @"更多评论";
                            cell.textLabel.textAlignment = NSTextAlignmentCenter;
                            cell.textLabel.font = [UIFont systemFontOfSize:14];
                            cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                            
                            return cell;
                        } else {
                            NewCommentCell *commentBlogCell = [NewCommentCell new];
                            commentBlogCell.selectionStyle = UITableViewCellSelectionStyleNone;
                            
                            OSCNewComment *detailComment = _blogDetailComments[indexPath.row];
                            commentBlogCell.comment = detailComment;
                            
                            if (detailComment.refer.author.length > 0) {
                                commentBlogCell.referCommentView.hidden = NO;
                            } else {
                                commentBlogCell.referCommentView.hidden = YES;
                            }
                            
                            
                            commentBlogCell.commentButton.tag = indexPath.row;
                            [commentBlogCell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
                            
                            return commentBlogCell;
                        }
                        
                    } else {
                        UITableViewCell *cell = [UITableViewCell new];
                        cell.textLabel.text = @"还没有评论";
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.textLabel.font = [UIFont systemFontOfSize:14];
                        cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        return cell;
                    }
                }
                
            }
                break;
            case 2: {
                if (_blogDetailComments.count > 0) {
                    if (indexPath.row == _blogDetailComments.count) {
                        UITableViewCell *cell = [UITableViewCell new];
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        cell.textLabel.text = @"更多评论";
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.textLabel.font = [UIFont systemFontOfSize:14];
                        cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                        
                        return cell;
                    } else {
                        NewCommentCell *commentBlogCell = [NewCommentCell new];
                        commentBlogCell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        OSCNewComment *detailComment = _blogDetailComments[indexPath.row];
                        commentBlogCell.comment = detailComment;
                        
                        if (detailComment.refer.author.length > 0) {
                            commentBlogCell.referCommentView.hidden = NO;
                        } else {
                            commentBlogCell.referCommentView.hidden = YES;
                        }
                        
                        
                        commentBlogCell.commentButton.tag = indexPath.row;
                        [commentBlogCell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
                        
                        return commentBlogCell;
                    }
                    
                } else {
                    UITableViewCell *cell = [UITableViewCell new];
                    cell.textLabel.text = @"还没有评论";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.font = [UIFont systemFontOfSize:14];
                    cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return cell;
                }
                
            }
                break;
            default:
                break;
        }
    }else {     //资讯详情
        switch (indexPath.section) {
            case 0: {
                if (indexPath.row==0) {
                    TitleInfoTableViewCell *titleInfoCell = [tableView dequeueReusableCellWithIdentifier:titleInfoReuseIdentifier forIndexPath:indexPath];
                    titleInfoCell.newsDetail = _newsDetails;
                    [titleInfoCell.authorLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(authorInfo)]];
                    titleInfoCell.authorLabel.userInteractionEnabled = YES;
                    
                    titleInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return titleInfoCell;
                } else if (indexPath.row==1) {
                    ContentWKWebViewCell* webViewCell = [tableView dequeueReusableCellWithIdentifier:contentWKWebReuseIdentifier forIndexPath:indexPath];
                    _WKWebViewCell = webViewCell;
                    webViewCell.contentWebView.delegate = self;
                    if (_newsDetails.body.length > 0 ) {
                        [webViewCell.contentWebView loadHTMLString:_newsDetails.body baseURL:[NSBundle mainBundle].resourceURL];
                    }
                    webViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return webViewCell;
                }
                
            }
                break;
            case 1: {
                if (_isExistRelatedSoftware) {
                    RelatedSoftWareCell *softWareCell = [tableView dequeueReusableCellWithIdentifier:relatedSoftWareReuseIdentifier forIndexPath:indexPath];
                    softWareCell.titleLabel.text = _newsDetails.software?[_newsDetails.software objectForKey:@"name"]:@"";
                    softWareCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    return softWareCell;
                }else if (_newsDetails.abouts.count > 0){
                    RecommandBlogTableViewCell *recommandNewsCell = [tableView dequeueReusableCellWithIdentifier:recommandBlogReuseIdentifier forIndexPath:indexPath];
                    if (_newsDetailRecommends.count > 0) {
                        OSCBlogDetailRecommend *about = _newsDetailRecommends[indexPath.row];
                        recommandNewsCell.abouts = about;
                        recommandNewsCell.hiddenLine = _newsDetailRecommends.count - 1 == indexPath.row ? YES : NO;
                    }
                    recommandNewsCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    return recommandNewsCell;
                }else if (_newsDetailComments.count > 0) {
                    if (_newsDetailComments.count > 0) {
                        if (indexPath.row == _newsDetailComments.count) {
                            UITableViewCell *cell = [UITableViewCell new];
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                            cell.textLabel.text = @"更多评论";
                            cell.textLabel.textAlignment = NSTextAlignmentCenter;
                            cell.textLabel.font = [UIFont systemFontOfSize:14];
                            cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                            
                            return cell;
                        } else {
                            NewCommentCell *commentNewsCell = [NewCommentCell new];
                            commentNewsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                            
                            if (!commentNewsCell.contentTextView.delegate) {
                                commentNewsCell.contentTextView.delegate = self;
                            }
                            
//                            OSCBlogDetailComment *detailComment = _newsDetailComments[indexPath.row];
                            OSCNewComment *detailComment = _newsDetailComments[indexPath.row];
                            commentNewsCell.comment = detailComment;
                            
                            if (detailComment.refer.author.length > 0) {
                                commentNewsCell.referCommentView.hidden = NO;
                            } else {
                                commentNewsCell.referCommentView.hidden = YES;
                            }
                            commentNewsCell.commentButton.tag = indexPath.row;
                            [commentNewsCell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
                            
                            return commentNewsCell;
                        }
                        
                    } else {
                        UITableViewCell *cell = [UITableViewCell new];
                        cell.textLabel.text = @"还没有评论";
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.textLabel.font = [UIFont systemFontOfSize:14];
                        cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        return cell;
                    }
                }
            }
                break;
            case 2: {
                if (_isExistRelatedSoftware && _newsDetails.abouts.count > 0) {
                    RecommandBlogTableViewCell *recommandNewsCell = [tableView dequeueReusableCellWithIdentifier:recommandBlogReuseIdentifier forIndexPath:indexPath];
                    if (indexPath.row < _newsDetailRecommends.count) {
                        OSCBlogDetailRecommend *about = _newsDetailRecommends[indexPath.row];
                        recommandNewsCell.abouts = about;
                        recommandNewsCell.hiddenLine = _newsDetailRecommends.count - 1 == indexPath.row ? YES : NO;

                    }
                    recommandNewsCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    return recommandNewsCell;
                }else {
                    if (_newsDetailComments.count > 0) {
                        if (indexPath.row == _newsDetailComments.count) {
                            UITableViewCell *cell = [UITableViewCell new];
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                            cell.textLabel.text = @"更多评论";
                            cell.textLabel.textAlignment = NSTextAlignmentCenter;
                            cell.textLabel.font = [UIFont systemFontOfSize:14];
                            cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                            
                            return cell;
                        } else {
                            NewCommentCell *commentNewsCell = [NewCommentCell new];
                            commentNewsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                            
                            if (!commentNewsCell.contentTextView.delegate) {
                                commentNewsCell.contentTextView.delegate = self;
                            }
                            
//                            OSCBlogDetailComment *detailComment = _newsDetailComments[indexPath.row];
                            OSCNewComment *detailComment = _newsDetailComments[indexPath.row];
                            commentNewsCell.comment = detailComment;
                            
                            if (detailComment.refer.author.length > 0) {
                                commentNewsCell.referCommentView.hidden = NO;
                            } else {
                                commentNewsCell.referCommentView.hidden = YES;
                            }
                            commentNewsCell.commentButton.tag = indexPath.row;
                            [commentNewsCell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
                            
                            return commentNewsCell;
                        }
                        
                    } else {
                        UITableViewCell *cell = [UITableViewCell new];
                        cell.textLabel.text = @"还没有评论";
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.textLabel.font = [UIFont systemFontOfSize:14];
                        cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        return cell;
                    }
                }
                
            }
                break;
            case 3: {
                if (_newsDetailComments.count > 0) {
                    if (indexPath.row == _newsDetailComments.count) {
                        UITableViewCell *cell = [UITableViewCell new];
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        cell.textLabel.text = @"更多评论";
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.textLabel.font = [UIFont systemFontOfSize:14];
                        cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                        
                        return cell;
                    } else {
                        NewCommentCell *commentNewsCell = [NewCommentCell new];
                        commentNewsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                        if (!commentNewsCell.contentTextView.delegate) {
                            commentNewsCell.contentTextView.delegate = self;
                        }
                        
                        OSCNewComment *detailComment = _newsDetailComments[indexPath.row];
                        commentNewsCell.comment = detailComment;
                        
                        if (detailComment.refer.author.length > 0) {
                            commentNewsCell.referCommentView.hidden = NO;
                        } else {
                            commentNewsCell.referCommentView.hidden = YES;
                        }
                        commentNewsCell.commentButton.tag = indexPath.row;
                        [commentNewsCell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
                        
                        return commentNewsCell;
                    }
                    
                } else {
                    UITableViewCell *cell = [UITableViewCell new];
                    cell.textLabel.text = @"还没有评论";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.font = [UIFont systemFontOfSize:14];
                    cell.textLabel.textColor = [UIColor colorWithHex:0x24cf5f];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return cell;
                }
                
            }
                break;
            default:
                break;
        }
    }
    
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_isBlogDetail) {        //博客详情
        if (indexPath.section == 1) {
            if (_blogDetailRecommends.count > 0) {
                OSCBlogDetailRecommend *detailRecommend = _blogDetailRecommends[indexPath.row];
                [self pushDetailsVcWithDetailModel:detailRecommend];
                
//                NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailRecommend.id
//                                                                                                                    isBlogDetail:YES];
//                [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
            } else {
                if (_blogDetailComments.count > 0) {
                    if (indexPath.row == _blogDetailComments.count) {
                        //新评论列表
                        NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForBlog sourceID:_blogDetails.id];
                        
                        [self.navigationController pushViewController:newCommentVC animated:YES];
                    }
                }
            }
        } else if (indexPath.section == 2) {
            if (_blogDetailComments.count > 0) {
                if (indexPath.row == _blogDetailComments.count) {
                    //新评论列表
                    NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForBlog sourceID:_blogDetails.id];
                    
                    [self.navigationController pushViewController:newCommentVC animated:YES];
                }
            }
        }
    } else {     //资讯详情
        if (indexPath.section == 1) {
            
            if (_isExistRelatedSoftware) {      //相关的软件详情
                SoftWareViewController* detailsViewController = [[SoftWareViewController alloc]initWithSoftWareID:[_newsDetails.software[@"id"] integerValue]];
                [detailsViewController setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:detailsViewController animated:YES];
                
//                OSCSoftware* softWare = [OSCSoftware new];
//                softWare.name = _newsDetails.software[@"name"];
//                softWare.url = [NSURL URLWithString:_newsDetails.software[@"href"]?:@""];
//                softWare.softId = [_newsDetails.software[@"id"] integerValue];
//                DetailsViewController *detailsViewController = [[DetailsViewController alloc] initWithV2Software:softWare];
//                [self.navigationController pushViewController:detailsViewController animated:YES];
                
            } else if (_newsDetails.abouts.count > 0) {     //相关推荐的资讯详情
                OSCBlogDetailRecommend *detailRecommend = _newsDetailRecommends[indexPath.row];
                [self pushDetailsVcWithDetailModel:detailRecommend];
                
//                NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailRecommend.id
//                                                                                                                    isBlogDetail:NO];
//                [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
            } else if (_newsDetailComments.count > 0) {
                //资讯评论列表
                if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                    CommentsBottomBarViewController *commentsBVC = [[CommentsBottomBarViewController alloc] initWithCommentType:1 andObjectID:_newsDetails.id];
                    [self.navigationController pushViewController:commentsBVC animated:YES];
                }
            }
        } else if (indexPath.section == 2) {
            if (_isExistRelatedSoftware && _newsDetails.abouts.count > 0) {
                OSCBlogDetailRecommend *detailRecommend = _newsDetailRecommends[indexPath.row];
                [self pushDetailsVcWithDetailModel:detailRecommend];
                
//                NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailRecommend.id
//                                                                                                                    isBlogDetail:NO];
//                [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
            } else {
                //资讯评论列表
                if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                    
                    //新评论列表
                    NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForNews sourceID:_newsDetails.id];
                    
                    [self.navigationController pushViewController:newCommentVC animated:YES];
                    
//                    CommentsBottomBarViewController *commentsBVC = [[CommentsBottomBarViewController alloc] initWithCommentType:1 andObjectID:_newsDetails.id];
//                    [self.navigationController pushViewController:commentsBVC animated:YES];
                }
            }
        } else if (indexPath.section == 3) {
            if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                
                //新评论列表
                NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForNews sourceID:_newsDetails.id];
                [self.navigationController pushViewController:newCommentVC animated:YES];
                //资讯评论列表
//                CommentsBottomBarViewController *commentsBVC = [[CommentsBottomBarViewController alloc] initWithCommentType:1 andObjectID:_newsDetails.id];
//                [self.navigationController pushViewController:commentsBVC animated:YES];
            }
        }
    }
    
}

#pragma mark --- scrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([UIDevice currentSystemVersion] == Version_iOS10) {
        if (_isBlogDetail) {
            if (_blogDetails.body.length > 0 ) {
                [_WKWebViewCell.contentWebView loadHTMLString:_blogDetails.body baseURL:[NSBundle mainBundle].resourceURL];
            }
        }else{
            if (_newsDetails.body.length > 0 ) {
                [_WKWebViewCell.contentWebView loadHTMLString:_newsDetails.body baseURL:[NSBundle mainBundle].resourceURL];
            }
        }
    }
}

#pragma mark - 资讯作者信息
- (void)authorInfo
{
    OSCUserHomePageController *userDetailsVC = [[OSCUserHomePageController alloc] initWithUserID:_newsDetails.authorId];
    [self.navigationController pushViewController:userDetailsVC animated:YES];
}

#pragma  mark -- 相关推荐跳转
-(void)pushDetailsVcWithDetailModel:(OSCBlogDetailRecommend*)detailModel {

    NSInteger pushType = detailModel.type;
    if (pushType == 0) {
        pushType = _isBlogDetail ? 3 : 6;
    }
    switch (pushType) {
        case 1:{        //软件详情
            SoftWareViewController* detailsViewController = [[SoftWareViewController alloc]initWithSoftWareID:detailModel.id];
            [detailsViewController setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:detailsViewController animated:YES];
        }
            break;
        case 2:{
            //问答
            QuesAnsDetailViewController *detailVC = [QuesAnsDetailViewController new];
            detailVC.hidesBottomBarWhenPushed = YES;
            detailVC.questionID = detailModel.id;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
            break;
        case 3:{        //博客详情
            NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailModel.id
                                                                                                                isBlogDetail:YES];
            [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
        }
            break;
        case 4:{
            //翻译
            TranslationViewController *translationVc = [TranslationViewController new];
            translationVc.hidesBottomBarWhenPushed = YES;
            translationVc.translationId = detailModel.id;
            [self.navigationController pushViewController:translationVc animated:YES];
        }
            break;
        case 5:{
            //新活动详情页面
            ActivityDetailViewController *activityDetailCtl = [[ActivityDetailViewController alloc] initWithActivityID:detailModel.id];
            activityDetailCtl.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:activityDetailCtl animated:YES];
        }
            break;
        case 6:{        //资讯详情
            NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailModel.id
                                                                                                                isBlogDetail:NO];
            [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(IMYWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType{
    if ([request.URL.absoluteString hasPrefix:@"file"]) {return YES;}
    
    [self.navigationController handleURL:request.URL name:nil];
    return [request.URL.absoluteString isEqualToString:@"about:blank"];
}

-(void)webViewDidFinishLoad:(IMYWebView*)webView{
    if (_isFinshDisplayH5) { return; }
    
    [webView evaluateJavaScript:@"document.body.offsetHeight" completionHandler:^(NSNumber* result, NSError *err) {
        CGFloat webViewHeight = [result floatValue];
//        if (_webViewHeight == webViewHeight) return ;
        _webViewHeight = webViewHeight;
        dispatch_async(dispatch_get_main_queue(), ^{
            _isFinshDisplayH5 = YES;
            [self.tableView reloadData];
            [self hideHubView];
        });
    }];
}
- (void)webView:(IMYWebView*)webView didFailLoadWithError:(NSError*)error{
    NSLog(@"%@",error);
}

#pragma mark - fav关注
- (void)favSelected
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        
        NSString *blogDetailUrlStr = [NSString stringWithFormat:@"%@user_relation_reverse", OSCAPI_V2_PREFIX];
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        [manger POST:blogDetailUrlStr
          parameters:@{
                       @"id"  : @(_blogDetails.authorId),
                       }
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 if ([responseObject[@"code"] integerValue]== 1) {
                     _blogDetails.authorRelation = [responseObject[@"result"][@"relation"] integerValue];
                 }
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                           withRowAnimation:UITableViewRowAnimationNone];
                 });
             } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                 NSLog(@"%@",error);
             }];
    }
    
}

#pragma mark - 回复某条评论
- (void)selectedToComment:(UIButton *)button
{
    OSCNewComment *comment = _isBlogDetail ? _blogDetailComments[button.tag] : _newsDetailComments[button.tag];
    
    if (_selectIndexPath == button.tag) {
        _isReply = !_isReply;
    } else {
        _isReply = YES;
    }
    _selectIndexPath = button.tag;
    
    if (_isReply) {
        if (comment.authorId > 0) {
            _commentTextField.placeholder = [NSString stringWithFormat:@"@%@", comment.author];
            _beRepliedCommentId = comment.id;
            _beRepliedCommentAuthorId = comment.authorId;
        } else {
            MBProgressHUD *hud = [Utils createHUD];
            hud.mode = MBProgressHUDModeCustomView;
            hud.label.text = @"该用户不存在，不可引用回复";
            [hud hideAnimated:YES afterDelay:1];
        }

    } else {
        _commentTextField.placeholder = @"发表评论";
    }
    
    [_commentTextField becomeFirstResponder];
}

#pragma mark - 发评论
- (void)sendComment
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        
        MBProgressHUD *HUD = [Utils createHUD];
        [HUD showAnimated:YES];
        //新 发评论
        NSInteger sourceId = _isBlogDetail ? _blogDetails.id : _newsDetails.id;
        NSInteger type = _isBlogDetail ? 3 : 6;
        NSMutableDictionary *paraDic = [NSMutableDictionary dictionaryWithDictionary:
                                        @{
                                          @"sourceId":@(sourceId),
                                          @"type":@(type),
                                          @"content":_commentTextField.text,
                                          @"reAuthorId": @(_beRepliedCommentAuthorId),
                                          @"replyId": @(_beRepliedCommentId)
                                          }
                                        ];
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        [manger POST:[NSString stringWithFormat:@"%@%@", OSCAPI_V2_PREFIX,OSCAPI_COMMENT_PUB]
          parameters:paraDic
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 
                 HUD.mode = MBProgressHUDModeCustomView;
                 
                 if ([responseObject[@"code"]integerValue] == 1) {
                     HUD.mode = MBProgressHUDModeCustomView;
                     HUD.label.text = @"评论成功";
                     
                     OSCNewComment *postedComment = [OSCNewComment mj_objectWithKeyValues:responseObject[@"result"]];
                     if(_isBlogDetail) {
                         [_blogDetailComments insertObject:postedComment atIndex:0];
                     }else {
                         [_newsDetailComments insertObject:postedComment atIndex:0];
                     }
                     [HUD hideAnimated:YES afterDelay:1];
                     _commentTextField.text = @"";
                     _commentTextField.placeholder = @"";
                 }else {
                     HUD.label.text = [NSString stringWithFormat:@"错误：%@", responseObject[@"message"]];
                 }
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     [self.tableView reloadData];
                 });
             }
             failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.label.text = @"网络异常，评论发送失败";
                 [HUD hideAnimated:YES afterDelay:1];
             }];
    }
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendComment];

    [textField resignFirstResponder];
    
    return YES;
}

- (void)keyboardDidShow:(NSNotification *)nsNotification {
    
    //获取键盘的高度
    
    NSDictionary *userInfo = [nsNotification userInfo];
    
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardRect = [aValue CGRectValue];
    
    _keyboardHeight = keyboardRect.size.height;
    
    _bottmTextFiled.constant = _keyboardHeight;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyBoardHiden:)];
    [self.view addGestureRecognizer:_tap];
    
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    _bottmTextFiled.constant = 0;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - collect 收藏

- (void)updateFavButtonWithIsCollected:(BOOL)isCollected {
    if (isCollected) {
        [_favButton setImage:[UIImage imageNamed:@"ic_faved_pressed"] forState:UIControlStateNormal];
    }else {
        [_favButton setImage:[UIImage imageNamed:@"ic_fav_pressed"] forState:UIControlStateNormal];
    }
}
- (IBAction)collected:(UIButton *)sender {
    //    NSLog(@"collect");
    
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        NSDictionary *parameterDic = _isBlogDetail? @{@"id"   : @(_blogDetails.id),
                                                      @"type" : @(3)}
        :
        @{@"id"  : @(_newsDetails.id),
          @"type": @(6)};
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        
        [manger POST:[NSString stringWithFormat:@"%@/favorite_reverse", OSCAPI_V2_PREFIX]
          parameters:parameterDic
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 
                 BOOL isCollected = NO;
                 if ([responseObject[@"code"] integerValue]== 1) {
                     isCollected = [responseObject[@"result"][@"favorite"] boolValue];
                 }
                 
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.label.text = isCollected? @"收藏成功": @"取消收藏";
                 
                 [HUD hideAnimated:YES afterDelay:1];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self updateFavButtonWithIsCollected:isCollected];
                     [self.tableView reloadData];
                 });
             }
             failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.label.text = @"网络异常，操作失败";
                 
                 [HUD hideAnimated:YES afterDelay:1];
             }];
    }
}


#pragma mark - share
- (IBAction)share:(UIButton *)sender {
    NSLog(@"share");
    
    [_commentTextField resignFirstResponder];
    
    NSString *body = _isBlogDetail?_blogDetails.body:_newsDetails.body;
    NSString *href = _isBlogDetail?_blogDetails.href:_newsDetails.href;
    NSString *title = _isBlogDetail?_blogDetails.title:_newsDetails.title;
    
    NSString *trimmedHTML = [body deleteHTMLTag];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    NSString *digest = [trimmedHTML substringToIndex:length];
    
    // 微信相关设置
    [UMSocialData defaultData].extConfig.wxMessageType = UMSocialWXMessageTypeWeb;
    [UMSocialData defaultData].extConfig.wechatSessionData.url = href;
    [UMSocialData defaultData].extConfig.wechatTimelineData.url = href;
    [UMSocialData defaultData].extConfig.title = title;
    
    // 手机QQ相关设置
    [UMSocialData defaultData].extConfig.qqData.qqMessageType = UMSocialQQMessageTypeDefault;
    [UMSocialData defaultData].extConfig.qqData.title = title;
    //[UMSocialData defaultData].extConfig.qqData.shareText = weakSelf.objectTitle;
    [UMSocialData defaultData].extConfig.qqData.url = href;
    
    // 新浪微博相关设置
    [[UMSocialData defaultData].extConfig.sinaData.urlResource setResourceType:UMSocialUrlResourceTypeDefault url:href];
    
    [UMSocialSnsService presentSnsIconSheetView:self
                                         appKey:@"54c9a412fd98c5779c000752"
                                      shareText:[NSString stringWithFormat:@"%@...分享来自 %@", digest, href]
                                     shareImage:[UIImage imageNamed:@"logo"]
                                shareToSnsNames:@[UMShareToWechatTimeline, UMShareToWechatSession, UMShareToQQ, UMShareToSina]
                                       delegate:nil];
}


#pragma mark - UITableViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    [self.navigationController handleURL:URL name:nil];
    return NO;
}

- (NSString *)mURL
{
    if (_mURL) {
        return _mURL;
    } else {
        NSString *objId = [NSString stringWithFormat:@"%lld", _isBlogDetail? _blogDetails.id:_newsDetails.id];
        NSString *preUrl = _isBlogDetail?@"http://m.oschina.net/blog/":@"http://m.oschina.net/news/";
        NSString *strUrl = [NSString stringWithFormat:@"%@%@", preUrl,objId];
        _mURL = [strUrl copy];
        return _mURL;
    }
}
#pragma mark --- update RightButton
-(void)updateRightButton:(NSInteger)commentCount isNewsDetail:(BOOL)isNewsDetail{
    _rightBarBtn.hidden = NO;
    if (commentCount >= 999) {
        _rightBarBtn.frame = Large_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_4_appbar"] forState:UIControlStateNormal];
        [_rightBarBtn setTitle:@"999+" forState:UIControlStateNormal];
    }else if (commentCount >= 100){
        _rightBarBtn.frame = Medium_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_3_appbar"] forState:UIControlStateNormal];
        NSString* titleStr = isNewsDetail ? [NSString stringWithFormat:@"%ld",_newsDetails.commentCount] : [NSString stringWithFormat:@"%ld",_blogDetails.commentCount];
        [_rightBarBtn setTitle:titleStr forState:UIControlStateNormal];
    }else{
        _rightBarBtn.frame = Small_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_appbar"] forState:UIControlStateNormal];
        NSString* titleStr = isNewsDetail ? [NSString stringWithFormat:@"%ld",_newsDetails.commentCount] : [NSString stringWithFormat:@"%ld",_blogDetails.commentCount];
        [_rightBarBtn setTitle:titleStr forState:UIControlStateNormal];    }
}


@end
