//
//  TranslationViewController.m
//  iosapp
//
//  Created by 李萍 on 16/6/29.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "TranslationViewController.h"
#import "TitleInfoTableViewCell.h"
#import "webAndAbsTableViewCell.h"
#import "RecommandBlogTableViewCell.h"
#import "ContentWebViewCell.h"
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
#import "CommentsBottomBarViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "NewCommentListViewController.h"//新评论列表

#import <MJExtension.h>
#import <MBProgressHUD.h>
#import <AFNetworking.h>
#import <UITableView+FDTemplateLayoutCell.h>
#import "UMSocial.h"

static NSString *titleInfoReuseIdentifier = @"TitleInfoTableViewCell";
static NSString *recommandBlogReuseIdentifier = @"RecommandBlogTableViewCell";
static NSString *abstractReuseIdentifier = @"abstractTableViewCell";
static NSString *contentWebReuseIdentifier = @"contentWebTableViewCell";
static NSString *newCommentReuseIdentifier = @"NewCommentCell";
static NSString *relatedSoftWareReuseIdentifier = @"RelatedSoftWareCell";

@interface TranslationViewController ()<UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate,UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIButton *favButton;

@property (nonatomic, strong) OSCInformationDetails *translationDetails;
@property (nonatomic, strong) NSMutableArray *translationDetailComments;
@property (nonatomic) BOOL isExistRelatedTranslation;      //存在相关软件的信息

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

@property (nonatomic,assign) BOOL isReboundTop;
@property (nonatomic,assign) CGPoint readingOffest;

@end

@implementation TranslationViewController

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

- (void)viewWillDisappear:(BOOL)animated
{
    [self hideHubView];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.title = @"翻译";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.commentTextField.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TitleInfoTableViewCell" bundle:nil] forCellReuseIdentifier:titleInfoReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommandBlogTableViewCell" bundle:nil] forCellReuseIdentifier:recommandBlogReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"webAndAbsTableViewCell" bundle:nil] forCellReuseIdentifier:abstractReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"ContentWebViewCell" bundle:nil] forCellReuseIdentifier:contentWebReuseIdentifier];
    [self.tableView registerClass:[NewCommentCell class] forCellReuseIdentifier:newCommentReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"RelatedSoftWareCell" bundle:nil] forCellReuseIdentifier:relatedSoftWareReuseIdentifier];
    
    self.tableView.tableFooterView = [UIView new];
    
    // 添加等待动画
    [self showHubView];
    
    [self getTranslationData];
    [self getTranslationComments];
    
    _rightBarBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightBarBtn.userInteractionEnabled = YES;
    _rightBarBtn.frame  = CGRectMake(0, 0, 27, 20);
    _rightBarBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    _rightBarBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [_rightBarBtn addTarget:self action:@selector(rightBarButtonScrollToCommitSection) forControlEvents:UIControlEventTouchUpInside];
    [_rightBarBtn setTitle:@"" forState:UIControlStateNormal];
    _rightBarBtn.titleEdgeInsets = UIEdgeInsetsMake(-3, 0, 0, 0);
    [_rightBarBtn setBackgroundImage:[UIImage imageNamed:@"ic_comment_appbar"] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightBarBtn];
    
    
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
#pragma mark - 右导航栏按钮
- (void)rightBarButtonScrollToCommitSection
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
#pragma mark - 获取翻译详情
- (void)getTranslationData {
    NSString *translationDetailUrlStr = [NSString stringWithFormat:@"%@translation?id=%ld", OSCAPI_V2_PREFIX, (long)self.translationId];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:translationDetailUrlStr
     parameters:nil
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            if ([responseObject[@"code"]integerValue] == 1) {
                _translationDetails = [OSCInformationDetails mj_objectWithKeyValues:responseObject[@"result"]];
                
                NSDictionary *data = @{@"content":  _translationDetails.body};
                _translationDetails.body = [Utils HTMLWithData:data
                                                 usingTemplate:@"blog"];
                
                [self updateFavButtonWithIsCollected:_translationDetails.favorite];
                [_rightBarBtn setTitle:[NSString stringWithFormat:@"%ld",(long)_translationDetails.commentCount] forState:UIControlStateNormal];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}
#pragma mark - 获取翻译详情评论
-(void)getTranslationComments{
    NSString *newsDetailUrlStr = [NSString stringWithFormat:@"%@comment", OSCAPI_V2_PREFIX];
    NSInteger fixedTranslastionId = _translationId > 10000000 ? _translationId-10000000:_translationId;
    NSDictionary *paraDic = @{@"pageToken":@"",
                              @"sourceId":@(fixedTranslastionId),
                              @"type":@(4),
                              @"parts":@"refer,reply",
                              };
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:newsDetailUrlStr
     parameters:paraDic
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if ([responseObject[@"code"]integerValue] == 1) {
                _translationDetailComments = [OSCNewComment mj_objectArrayWithKeyValuesArray:responseObject[@"result"][@"items"]];
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
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(16, 0, 100, 16)];
    titleLabel.center = CGPointMake(titleLabel.center.x, headerView.center.y);
    titleLabel.tag = 8;
    titleLabel.textColor = [UIColor colorWithHex:0x6a6a6a];
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.text = title;
    [headerView addSubview:titleLabel];
    
    return headerView;
}
#pragma mark -- 获取评论cell的高度
- (NSInteger)getCommentCellHeightWithComment:(OSCNewComment*)comment {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:14];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    label.attributedText = [NewCommentCell contentStringFromRawString:comment.content];
    
    CGFloat height = [label sizeThatFits:CGSizeMake(self.tableView.frame.size.width - 32, MAXFLOAT)].height;
    
    height += 7;
    OSCNewCommentRefer *refer = comment.refer;
    int i = 0;
    while (refer.author.length > 0) {
        NSMutableAttributedString *replyContent = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:\n", refer.author]];
        [replyContent appendAttributedString:[Utils emojiStringFromRawString:[refer.content deleteHTMLTag]]];
        label.attributedText = replyContent;
        height += [label sizeThatFits:CGSizeMake( self.tableView.frame.size.width - 60 - (i+1)*8, MAXFLOAT)].height + 6;
        i++;
        refer = refer.refer;
    }
    
    return height + 76;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionNumber = 1;
    if (_translationDetailComments.count > 0) {
        sectionNumber += 1;
    }
    return sectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
        {
            return 2;
            break;
        }
        case 1:
        {
            if (_translationDetailComments.count > 0) {
                return _translationDetailComments.count+1;
            }
            break;
        }
            
        default:
            break;
    }
    
    return 0;
}


- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        
        if (_translationDetailComments.count > 0) {
            return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"评论(%lu)", (unsigned long)_translationDetails.commentCount]];
        }
        return [self headerViewWithSectionTitle:@"评论"];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    return [tableView fd_heightForCellWithIdentifier:titleInfoReuseIdentifier configuration:^(TitleInfoTableViewCell *cell) {
                        cell.newsDetail = _translationDetails;
                        
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
            
            if (_translationDetailComments.count > 0) {
                if (indexPath.row == _translationDetailComments.count) {
                    return 44;
                } else {
                    return [self getCommentCellHeightWithComment:_translationDetailComments[indexPath.row]];
                }
            }
            
            
            break;
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
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row==0) {
                TitleInfoTableViewCell *titleInfoCell = [tableView dequeueReusableCellWithIdentifier:titleInfoReuseIdentifier forIndexPath:indexPath];
                titleInfoCell.newsDetail = _translationDetails;
                
                titleInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                return titleInfoCell;
            } else if (indexPath.row==1) {
                ContentWebViewCell *webViewCell = [tableView dequeueReusableCellWithIdentifier:contentWebReuseIdentifier forIndexPath:indexPath];
                webViewCell.contentWebView.delegate = self;
                [webViewCell.contentWebView loadHTMLString:_translationDetails.body baseURL:[NSBundle mainBundle].resourceURL];
                webViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                return webViewCell;
            }
            break;
        }
        case 1: {
            
            if (_translationDetailComments.count > 0) {
                if (indexPath.row == _translationDetailComments.count) {
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
                    OSCNewComment *detailComment = _translationDetailComments[indexPath.row];
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
            
            break;
        }
            
            
        default:
            break;
    }
    
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (_translationDetailComments.count > 0 && indexPath.row == _translationDetailComments.count) {
            //评论列表
            NewCommentListViewController *newCommentVC = [[NewCommentListViewController alloc] initWithCommentType:CommentIdTypeForTranslate sourceID:_translationDetails.id];
            [self.navigationController pushViewController:newCommentVC animated:YES];
        }
    }
    
    
}
#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    if ([request.URL.absoluteString hasPrefix:@"file"]) {return YES;}
    
    [self.navigationController handleURL:request.URL name:nil];
    return [request.URL.absoluteString isEqualToString:@"about:blank"];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGFloat webViewHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
    if (_webViewHeight == webViewHeight) {return;}
    _webViewHeight = webViewHeight;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self hideHubView];
    });
}


#pragma mark - 回复某条评论
- (void)selectedToComment:(UIButton *)button
{
    OSCNewComment *comment =  _translationDetailComments[button.tag];
    
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
        NSInteger fixedTranslastionId = _translationId > 10000000 ? _translationId-10000000:_translationId;
        NSDictionary *paraDic = @{
                                  @"sourceId":@(fixedTranslastionId),
                                  @"type":@(4),
                                  @"content":_commentTextField.text,
                                  @"reAuthorId": @(_beRepliedCommentAuthorId),
                                  @"replyId": @(_beRepliedCommentId)
                                  };
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        [manger POST:[NSString stringWithFormat:@"%@%@", OSCAPI_V2_PREFIX,OSCAPI_COMMENT_PUB]
          parameters:paraDic
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 
                 HUD.mode = MBProgressHUDModeCustomView;
                 
                 if ([responseObject[@"code"]integerValue] == 1) {
                     HUD.mode = MBProgressHUDModeCustomView;
                     HUD.label.text = @"评论成功";
                     
                     OSCNewComment *postedComment = [OSCNewComment mj_objectWithKeyValues:responseObject[@"result"]];
                     [_translationDetailComments insertObject:postedComment atIndex:0];
                     
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



#pragma mark - 更新收藏状态
- (void)updateFavButtonWithIsCollected:(BOOL)isCollected
{
    if (isCollected) {
        [_favButton setImage:[UIImage imageNamed:@"ic_faved_pressed"] forState:UIControlStateNormal];
    }else {
        [_favButton setImage:[UIImage imageNamed:@"ic_fav_pressed"] forState:UIControlStateNormal];
    }
}
#pragma mark - 收藏
- (IBAction)favClick:(id)sender {
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        
        NSDictionary *parameterDic =@{@"id"     : @(_translationId),
                                      @"type"   : @(4)};
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
//                 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                 HUD.label.text = @"网络异常，操作失败";
                 
                 [HUD hideAnimated:YES afterDelay:1];
             }];
    }
}

#pragma mark - 分享
- (IBAction)shareClick:(id)sender {
    [_commentTextField resignFirstResponder];
    
    NSString *body = _translationDetails.body;
    NSString *href = _translationDetails.href;
    NSString *title = _translationDetails.title;
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
@end
