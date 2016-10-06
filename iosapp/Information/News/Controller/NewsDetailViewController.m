//
//  NewsDetailViewController.m
//  iosapp
//
//  Created by 李萍 on 16/7/18.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "NewsDetailViewController.h"
#import "OSCInformationDetails.h"
#import "NewCommentListViewController.h"//新评论列表
#import "SoftWareViewController.h"      //软件详情
#import "NewCommentCell.h"
#import "TitleInfoTableViewCell.h"
#import "webAndAbsTableViewCell.h"
#import "RecommandBlogTableViewCell.h"
#import "ContentWKWebViewCell.h"
#import "NewCommentCell.h"
#import "RelatedSoftWareCell.h"
#import "UIColor+Util.h"
#import "NewsBlogDetailTableViewController.h"
#import "CommentsBottomBarViewController.h"
#import "LoginViewController.h"

#import "Utils.h"
#import "OSCAPI.h"
#import "Config.h"
#import "IMYWebView.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import <MJExtension.h>
#import <MBProgressHUD.h>
#import <AFNetworking.h>
#import <UITableView+FDTemplateLayoutCell.h>
#import "UMSocial.h"


static NSString *titleInfoReuseIdentifier = @"TitleInfoTableViewCell";
static NSString *recommandBlogReuseIdentifier = @"RecommandBlogTableViewCell";
static NSString *contentWebReuseIdentifier = @"contentWebTableViewCell";
static NSString *newCommentReuseIdentifier = @"NewCommentCell";
static NSString *relatedSoftWareReuseIdentifier = @"RelatedSoftWareCell";

#define Large_Frame  (CGRect){{0,0},{40,25}}
#define Medium_Frame (CGRect){{0,0},{30,25}}
#define Small_Frame  (CGRect){{0,0},{25,25}}

@interface NewsDetailViewController ()<IMYWebViewDelegate,UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate,UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIButton *favButton;

@property (nonatomic)int64_t newsId;
@property (nonatomic, strong) OSCInformationDetails *newsDetails;
@property (nonatomic, strong) NSMutableArray *newsDetailRecommends;
@property (nonatomic, strong) NSMutableArray *newsDetailComments;
@property (nonatomic) BOOL isExistRelatedSoftware;      //存在相关软件的信息

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) UIButton *rightBarBtn;
@property (nonatomic,assign) BOOL isReboundTop;
@property (nonatomic,assign) CGPoint readingOffest;
@property (nonatomic, assign) CGFloat webViewHeight;

@property (nonatomic, copy) NSString *mURL;
@property (nonatomic, assign) BOOL isReply;
@property (nonatomic, assign) NSInteger selectIndexPath;
//被评论的某条评论的信息
@property (nonatomic) NSInteger beRepliedCommentAuthorId;
@property (nonatomic) NSInteger beRepliedCommentId;

//软键盘size
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation NewsDetailViewController

- (instancetype)initWithNewsId:(NSInteger)newsId {
    if(self) {
        self.newsId = newsId;
        _newsDetailRecommends = [NSMutableArray new];
        _newsDetailComments = [NSMutableArray new];
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
    
    self.title = @"资讯";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.commentTextField.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TitleInfoTableViewCell" bundle:nil] forCellReuseIdentifier:titleInfoReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommandBlogTableViewCell" bundle:nil] forCellReuseIdentifier:recommandBlogReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"ContentWebViewCell" bundle:nil] forCellReuseIdentifier:contentWebReuseIdentifier];
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
    [_rightBarBtn addTarget:self action:@selector(rightBarButtonScrollToNewsCommitSection) forControlEvents:UIControlEventTouchUpInside];
    [_rightBarBtn setTitle:@"" forState:UIControlStateNormal];
    _rightBarBtn.titleEdgeInsets = UIEdgeInsetsMake(-4, 0, 0, 0);
    [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_appbar"] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightBarBtn];
    //    _rightBarBtn.hidden = NO;
    
    // 添加等待动画
    [self showHubView];
    //获取资讯详情和资讯评论
    [self getNewsData];
    [self getNewsComments];
    
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
- (void)viewWillDisappear:(BOOL)animated {
    [self hideHubView];
    [super viewWillDisappear:animated];
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
                [self updateNewsFavButtonWithIsCollected:_newsDetails.favorite];
                [self updateNewsRightButton:_newsDetails.commentCount];
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

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionNumber = 1;
    //资讯详情
    if (_isExistRelatedSoftware) {
        sectionNumber += 1;
    }
    if (_newsDetails.abouts.count > 0) {
        sectionNumber += 1;
    }
    if (_newsDetailComments.count > 0) {
        sectionNumber += 1;
    }
    return sectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //资讯详情
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
    
    return 0;
}


- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //资讯详情
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
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //资讯详情
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
                        return UITableViewAutomaticDimension;
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
                        return UITableViewAutomaticDimension;
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
                    return UITableViewAutomaticDimension;
                }
            }
        }
        default:
            break;
    }
    
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section != 0 ? 32 : 0.001;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     //资讯详情
        switch (indexPath.section) {
            case 0: {
                if (indexPath.row==0) {
                    TitleInfoTableViewCell *titleInfoCell = [tableView dequeueReusableCellWithIdentifier:titleInfoReuseIdentifier forIndexPath:indexPath];
                    titleInfoCell.newsDetail = _newsDetails;
                    
                    titleInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return titleInfoCell;
                } else if (indexPath.row==1) {
                    ContentWKWebViewCell *webViewCell = [tableView dequeueReusableCellWithIdentifier:contentWebReuseIdentifier forIndexPath:indexPath];
                    webViewCell.contentWebView.delegate = self;
                    if (_newsDetails.body.length > 0 && _webViewHeight == 0) {
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
                            OSCNewComment *detailComment = _newsDetailComments[indexPath.row];
                            commentNewsCell.comment = detailComment;
                            
                            if (detailComment.refer.author.length > 0) {
                                commentNewsCell.referCommentView.hidden = NO;
                            } else {
                                commentNewsCell.referCommentView.hidden = YES;
                            }
                            commentNewsCell.commentButton.tag = indexPath.row;
                            [commentNewsCell.commentButton addTarget:self action:@selector(selectedNewsToComment:) forControlEvents:UIControlEventTouchUpInside];
                            
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
                            
                            OSCNewComment *detailComment = _newsDetailComments[indexPath.row];
                            commentNewsCell.comment = detailComment;
                            
                            if (detailComment.refer.author.length > 0) {
                                commentNewsCell.referCommentView.hidden = NO;
                            } else {
                                commentNewsCell.referCommentView.hidden = YES;
                            }
                            commentNewsCell.commentButton.tag = indexPath.row;
                            [commentNewsCell.commentButton addTarget:self action:@selector(selectedNewsToComment:) forControlEvents:UIControlEventTouchUpInside];
                            
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
                        [commentNewsCell.commentButton addTarget:self action:@selector(selectedNewsToComment:) forControlEvents:UIControlEventTouchUpInside];
                        
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

    
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
       //资讯详情
        if (indexPath.section == 1) {
            if (_isExistRelatedSoftware) {      //相关的软件详情
                SoftWareViewController* detailsViewController = [[SoftWareViewController alloc]initWithSoftWareID:[_newsDetails.software[@"id"] integerValue]];
                [detailsViewController setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:detailsViewController animated:YES];
                
            }else if (_newsDetails.abouts.count > 0) {     //相关推荐的资讯详情
                OSCBlogDetailRecommend *detailRecommend = _newsDetailRecommends[indexPath.row];
                [self pushDetailsVcWithDetailModel:detailRecommend];
            }else if (_newsDetailComments.count > 0) {
                //资讯评论列表
                if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                    //新评论列表
                    NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForNews sourceID:_newsDetails.id];
                    [self.navigationController pushViewController:newCommentVC animated:YES];
                }
            }
        }else if (indexPath.section == 2) {
            if (_isExistRelatedSoftware && _newsDetails.abouts.count > 0) {
                OSCBlogDetailRecommend *detailRecommend = _newsDetailRecommends[indexPath.row];
                [self pushDetailsVcWithDetailModel:detailRecommend];
            }else {
                //资讯评论列表
                if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                    //新评论列表
                    NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForNews sourceID:_newsDetails.id];
                    [self.navigationController pushViewController:newCommentVC animated:YES];
                }
            }
        }else if (indexPath.section == 3) {
            if (_newsDetailComments.count > 0 && indexPath.row == _newsDetailComments.count) {
                //新评论列表
                NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForNews sourceID:_newsDetails.id];
                [self.navigationController pushViewController:newCommentVC animated:YES];
            }
        }
}

#pragma mark - UIWebViewDelegate or WKWebViewDelegate

- (BOOL)webView:(IMYWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType{
    if ([request.URL.absoluteString hasPrefix:@"file"]) {return YES;}
    
    [self.navigationController handleURL:request.URL name:nil];
    return [request.URL.absoluteString isEqualToString:@"about:blank"];
}
-(void)webViewDidFinishLoad:(IMYWebView*)webView{
    [webView evaluateJavaScript:@"document.body.offsetHeight" completionHandler:^(NSNumber* result, NSError *err) {
        CGFloat webViewHeight = [result floatValue];
        if (_webViewHeight == webViewHeight) return ;
        _webViewHeight = webViewHeight;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self hideHubView];
        });
    }];
}


#pragma  mark -- 相关推荐跳转
-(void)pushDetailsVcWithDetailModel:(OSCBlogDetailRecommend*)detailModel {
    NSInteger pushType = detailModel.type;
    if (pushType == 0) {
        pushType = 6;
    }
    switch (pushType) {
        case 1:{        //软件详情
            SoftWareViewController* detailsViewController = [[SoftWareViewController alloc]initWithSoftWareID:detailModel.id];
            [detailsViewController setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:detailsViewController animated:YES];
        }
            break;
        case 3:{        //博客详情
            NewsBlogDetailTableViewController *newsBlogDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:detailModel.id
                                                                                                                isBlogDetail:YES];
            [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
        }
            break;
        case 6:{        //资讯详情
            NewsDetailViewController *newsBlogDetailVc = [[NewsDetailViewController alloc]initWithNewsId:detailModel.id];
            [self.navigationController pushViewController:newsBlogDetailVc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 回复某条评论
- (void)selectedNewsToComment:(UIButton *)button
{
    OSCNewComment *comment = _newsDetailComments[button.tag];
    
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
#pragma mark - collect 收藏
- (void)updateNewsFavButtonWithIsCollected:(BOOL)isCollected
{
    if (isCollected) {
        [_favButton setImage:[UIImage imageNamed:@"ic_faved_pressed"] forState:UIControlStateNormal];
    }else {
        [_favButton setImage:[UIImage imageNamed:@"ic_fav_pressed"] forState:UIControlStateNormal];
    }
}
#pragma mark --- update RightButton
-(void)updateNewsRightButton:(NSInteger)commentCount{
    _rightBarBtn.hidden = NO;
    if (commentCount >= 999) {
        _rightBarBtn.frame = Large_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_4_appbar"] forState:UIControlStateNormal];
        [_rightBarBtn setTitle:@"999+" forState:UIControlStateNormal];
    }else if (commentCount >= 100){
        _rightBarBtn.frame = Medium_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_3_appbar"] forState:UIControlStateNormal];
        NSString* titleStr = [NSString stringWithFormat:@"%ld",_newsDetails.commentCount];
        [_rightBarBtn setTitle:titleStr forState:UIControlStateNormal];
    }else{
        _rightBarBtn.frame = Small_Frame;
        [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_appbar"] forState:UIControlStateNormal];
        NSString* titleStr = [NSString stringWithFormat:@"%ld",_newsDetails.commentCount] ;
        [_rightBarBtn setTitle:titleStr forState:UIControlStateNormal];
    }
}
#pragma mark - 右导航栏按钮
- (void)rightBarButtonScrollToNewsCommitSection
{
    if (self.isReboundTop == NO) {
        self.readingOffest = self.tableView.contentOffset;
        NSIndexPath* lastSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:(self.tableView.numberOfSections - 1)];
        [self.tableView scrollToRowAtIndexPath:lastSectionIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else{
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//        跳转到reading位置
//        [self.tableView setContentOffset:self.readingOffest animated:YES];
    }
    self.isReboundTop = !self.isReboundTop;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 收藏
- (IBAction)favClick:(id)sender {
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        NSDictionary *parameterDic =@{@"id"  : @(_newsDetails.id),
                                      @"type": @(6)
                                      };
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
                     [self updateNewsFavButtonWithIsCollected:isCollected];
                     [self.tableView reloadData];
                 });
             }
             failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
//                 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                 HUD.label.text = @"网络异常，操作失败";
                 
                 [HUD hideAnimated:YES afterDelay:1];
             }];
    }

}

#pragma mark - 分享
- (IBAction)shareClick:(id)sender {
    [_commentTextField resignFirstResponder];

    NSString *body = _newsDetails.body;
    NSString *href = _newsDetails.href;
    NSString *title = _newsDetails.title;
    
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

#pragma mark - UITextViewDelegate
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
        NSString *objId = [NSString stringWithFormat:@"%lld", _newsDetails.id];
        NSString *preUrl = @"http://m.oschina.net/news/";
        NSString *strUrl = [NSString stringWithFormat:@"%@%@", preUrl,objId];
        _mURL = [strUrl copy];
        return _mURL;
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendComment];
    [textField resignFirstResponder];
    
    return YES;
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
        NSMutableDictionary *paraDic = [NSMutableDictionary dictionaryWithDictionary:
                                        @{
                                          @"sourceId":@(_newsDetails.id),
                                          @"type":@(6),
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
                     
                     [_newsDetailComments insertObject:postedComment atIndex:0];

                     [HUD hideAnimated:YES afterDelay:1];
                     _commentTextField.text = @"";
                     _commentTextField.placeholder = @"";
                 }else {
//                     HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                     HUD.label.text = [NSString stringWithFormat:@"错误：%@", responseObject[@"message"]];
                 }
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     [self.tableView reloadData];
                 });
             }
             failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                 HUD.mode = MBProgressHUDModeCustomView;
//                 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                 HUD.label.text = @"网络异常，评论发送失败";
                 [HUD hideAnimated:YES afterDelay:1];
             }];
    }
}

- (void)keyboardDidShow:(NSNotification *)nsNotification
{
    
    //获取键盘的高度
    
    NSDictionary *userInfo = [nsNotification userInfo];
    
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardRect = [aValue CGRectValue];
    
    _keyboardHeight = keyboardRect.size.height;
    
    _bottomConstraint.constant = _keyboardHeight;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyBoardHiden:)];
    [self.view addGestureRecognizer:_tap];
    
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    _bottomConstraint.constant = 0;
}

#pragma mark - 软键盘隐藏
- (void)keyBoardHiden:(UITapGestureRecognizer *)tap
{
    [_commentTextField resignFirstResponder];
    [self.view removeGestureRecognizer:_tap];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
