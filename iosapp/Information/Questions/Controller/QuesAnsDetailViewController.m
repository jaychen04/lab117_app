//
//  QuesAnsDetailViewController.m
//  iosapp
//
//  Created by 李萍 on 16/6/16.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "QuesAnsDetailViewController.h"
#import "QuesAnsDetailHeadCell.h"
#import "NewCommentCell.h"
#import "OSCNewComment.h"
#import "OSCBlogDetail.h"
#import "CommentDetailViewController.h"
#import "AppDelegate.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "Config.h"
#import "Utils.h"
#import "OSCAPI.h"
#import "LoginViewController.h"


#import <MJExtension.h>
#import <MBProgressHUD.h>
#import <AFNetworking.h>
#import <UITableView+FDTemplateLayoutCell.h>
#import "UMSocial.h"
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MJRefresh.h>

static NSString *quesAnsDetailHeadReuseIdentifier = @"QuesAnsDetailHeadCell";
static NSString *quesAnsCommentHeadReuseIdentifier = @"NewCommentCell";

@interface QuesAnsDetailViewController () <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIButton *favButton;

@property (nonatomic, strong) OSCQuestion *questionDetail;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, assign) CGFloat webViewHeight;

@property (nonatomic, copy) NSString *nextPageToken;

@property (nonatomic, strong) UITapGestureRecognizer *tap;
//软键盘size
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation QuesAnsDetailViewController


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self hideHubView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialized];
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self getCommentsForQuestion:YES];
    }];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        [self getCommentsForQuestion:NO];
    }];

    //软键盘
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_more_normal"]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(rightBarButtonClicked)];
    [self getDetailForQuestion];
    [self getCommentsForQuestion:NO];/* 待调试 */
//    [self.tableView.mj_footer beginRefreshing]; 
	
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:nil];
	
	[self showHubView];
}

- (void)didReceiveMemoryWarning{
    [self.navigationController popViewControllerAnimated:YES];

    [super didReceiveMemoryWarning];
}
#pragma mark --- 
-(void)initialized{
    self.title = [NSString stringWithFormat:@"%ld个回答",(long)self.commentCount];
    _comments = [NSMutableArray new];
    _nextPageToken = @"";
    self.commentTextField.delegate = self;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"QuesAnsDetailHeadCell" bundle:nil] forCellReuseIdentifier:quesAnsDetailHeadReuseIdentifier];
    [self.tableView registerClass:[NewCommentCell class] forCellReuseIdentifier:quesAnsCommentHeadReuseIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 250;
}


#pragma mark - 获取数据
- (void)getDetailForQuestion
{
    NSString *blogDetailUrlStr = [NSString stringWithFormat:@"%@question?id=%ld", OSCAPI_V2_PREFIX, (long)self.questionID];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:blogDetailUrlStr
     parameters:nil
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            if ([responseObject[@"code"]integerValue] == 1) {
                _questionDetail = [OSCQuestion mj_objectWithKeyValues:responseObject[@"result"]];
                NSDictionary *data = @{@"content":  _questionDetail.body};
                _questionDetail.body = [Utils HTMLWithData:data
                                          usingTemplate:@"newTweet"];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFavButtonImage:_questionDetail.favorite];
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}

#pragma mark - 获取评论数组
- (void)getCommentsForQuestion:(BOOL)isRefresh
{
    
    NSString *qCommentUrlStr = [NSString stringWithFormat:@"%@comment", OSCAPI_V2_PREFIX];
    NSMutableDictionary *mutableParamDic = @{
                               @"sourceId"  : @(self.questionID),
                               @"type"      : @(2),
                               @"parts"     : @"refer,reply"
                               }.mutableCopy;
    if (!isRefresh) {//上拉刷新
        [mutableParamDic setValue:_nextPageToken forKey:@"pageToken"];
    }
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:qCommentUrlStr
     parameters:mutableParamDic.copy
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            if ([responseObject[@"code"] integerValue] == 1) {
                NSDictionary *result = responseObject[@"result"];
                NSArray *jsonItems = result[@"items"]?:@[];
                NSArray *array;
                if (jsonItems.count > 0) {
                    array = [OSCNewComment mj_objectArrayWithKeyValuesArray:jsonItems];
                }
                _nextPageToken = result[@"nextPageToken"];
                
                if (isRefresh) {
                    [_comments removeAllObjects];
                }
                [_comments addObjectsFromArray:array];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isRefresh) {
                        [self.tableView.mj_header endRefreshing];
                    }else{
                        if (array.count == 0) {
                            [self.tableView.mj_footer endRefreshingWithNoMoreData];
                        }else{
                            [self.tableView.mj_footer endRefreshing];
                        }
                    }
                    [self.tableView reloadData];
                });
            }else {
                if (isRefresh) {
                    [self.tableView.mj_header endRefreshing];
                }else{
                    [self.tableView.mj_footer endRefreshing];
                }
            }
            
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            if (isRefresh) {
                [self.tableView.mj_header endRefreshing];
            }else{
                [self.tableView.mj_footer endRefreshing];
            }
            NSLog(@"error = %@",error);
        }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_comments.count > 0) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1){
        if (_comments.count > 0) {
            return _comments.count;
        }
        return 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
            QuesAnsDetailHeadCell *cell = [tableView dequeueReusableCellWithIdentifier:quesAnsDetailHeadReuseIdentifier forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.questioinDetail = _questionDetail;
            cell.contentWebView.delegate = self;
                [cell.contentWebView loadHTMLString:_questionDetail.body baseURL:[NSBundle mainBundle].resourceURL];
            return cell;
        
    } else if (indexPath.section == 1) {
        
        NewCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:quesAnsCommentHeadReuseIdentifier forIndexPath:indexPath];//[NewCommentCell new];//
        if (_comments.count > 0) {
            OSCNewComment *comment = _comments[indexPath.row];
            
            [commentCell setDataForQuestionComment:comment];
            commentCell.commentButton.enabled = NO;
            commentCell.contentTextView.userInteractionEnabled = NO;
        }
        
        commentCell.contentView.backgroundColor = [UIColor newCellColor];
        commentCell.backgroundColor = [UIColor themeColor];
        commentCell.selectedBackgroundView = [[UIView alloc] initWithFrame:commentCell.frame];
        commentCell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
        
        return commentCell;
    }
    
    return [UITableViewCell new];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        if (_questionDetail.commentCount > 0) {
            return [self headerViewWithSectionTitle:[NSString stringWithFormat:@"回答(%lu)", (unsigned long)_questionDetail.commentCount]];
        }
        return [self headerViewWithSectionTitle:@"回答"];
    }
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:22];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        
        label.text = _questionDetail.title;
        CGFloat height = [label sizeThatFits:CGSizeMake(tableView.frame.size.width - 32, MAXFLOAT)].height;
        height += _webViewHeight;
        
        return 83 + height;
    } else if (indexPath.section == 1) {
        return UITableViewAutomaticDimension;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat headerViewHeight = 0.001;
    switch (section) {
        case 0:
            break;
        case 1:
            headerViewHeight = 32;
            break;
        default:
            break;
    }
    return headerViewHeight;
}
#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (_comments.count > indexPath.row) {
            OSCNewComment *comment = _comments[indexPath.row];
            
            CommentDetailViewController *commentDetailVC = [CommentDetailViewController new];
            commentDetailVC.questDetailId = self.questionID;
            commentDetailVC.commentId = comment.id;
            [self.navigationController pushViewController:commentDetailVC animated:YES];
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
	
	if(_webViewHeight != webViewHeight + 5) {
		_webViewHeight = webViewHeight + 5;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
			[self hideHubView];
		});
	}
}

#pragma mark -- DIY_headerView
- (UIView*)headerViewWithSectionTitle:(NSString*)title {
    
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen]bounds]), 32)];
    headerView.backgroundColor = [UIColor colorWithHex:0xf9f9f9];
    
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen]bounds]), 1)];
    topLineView.backgroundColor = [UIColor separatorColor];
    [headerView addSubview:topLineView];
    
    UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 31, CGRectGetWidth([[UIScreen mainScreen]bounds]), 1)];
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

#pragma mark - 右导航栏按钮
- (void)rightBarButtonClicked
{
	
	if ([Config getOwnID] == 0) {
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
		LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
		[self.navigationController pushViewController:loginVC animated:YES];
		return;
	} else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"举报"
                                                        message:[NSString stringWithFormat:@"链接地址：%@", _questionDetail.href]
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView textFieldAtIndex:0].placeholder = @"举报原因";
		if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode)
		{
			[alertView textFieldAtIndex:0].keyboardAppearance = UIKeyboardAppearanceDark;
		}
		[alertView show];
	}//end of if
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        /* 新举报接口 */
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        [manger POST:[NSString stringWithFormat:@"%@report", OSCAPI_V2_PREFIX]
          parameters:@{
                       @"sourceId"   : @(self.questionID),
                       @"type"       : @(2),
                       @"href"       : _questionDetail.href,//举报的文章地址
                       @"reason"     : @(1), //0 其他原因 1 广告 2 色情 3 翻墙 4 非IT话题
					   @"memo"		 : ([alertView textFieldAtIndex:0].text)
                       }
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 if ([responseObject[@"code"]integerValue] == 1) {
                     MBProgressHUD *HUD = [Utils createHUD];
                     HUD.mode = MBProgressHUDModeCustomView;
                     HUD.label.text = @"举报完成，感谢亲~";
                     [HUD hideAnimated:YES afterDelay:1];
				 } else {
					 MBProgressHUD *HUD = [Utils createHUD];
					 HUD.mode = MBProgressHUDModeCustomView;
					 HUD.label.text = @"其他未知错误，请稍后再试~";
					 [HUD hideAnimated:YES afterDelay:1];
				 }
             }
             failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
				 MBProgressHUD *HUD = [Utils createHUD];
				 HUD.mode = MBProgressHUDModeCustomView;
				 HUD.label.text = @"网络请求失败，请稍后再试~~";
				 [HUD hideAnimated:YES afterDelay:1];
             }];
    }//end of if
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
    /*
     发评论
     */
    if (textField == _commentTextField) {
        if (_commentTextField.text.length > 0) {
            if ([Config getOwnID] == 0) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
                LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                [self.navigationController pushViewController:loginVC animated:YES];
            } else {
                [self sendMessage];
            }
        } else {
            MBProgressHUD *HUD = [Utils createHUD];
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.label.text = @"评论不能为空";
            
            [HUD hideAnimated:YES afterDelay:1];
        }
    }
    
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
    
    _bottomLayoutConstraint.constant = _keyboardHeight;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyBoardHiden:)];
    [self.view addGestureRecognizer:_tap];
    
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    _bottomLayoutConstraint.constant = 0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - sendMessage
- (void)sendMessage
{
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    
    [manger POST:[NSString stringWithFormat:@"%@comment_pub", OSCAPI_V2_PREFIX]
     parameters:@{
                  @"sourceId"   : @(self.questionID),
                  @"type"       : @(2),
                  @"content"    : _commentTextField.text,
//                  @"replyId"    : @(0),
//                  @"reAuthorId" : @(0),
                  }
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if ([responseObject[@"code"]integerValue] == 1) {
                MBProgressHUD *HUD = [Utils createHUD];
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.label.text = @"评论成功";
                
                OSCNewComment *postedComment = [OSCNewComment mj_objectWithKeyValues:responseObject[@"result"]];
                if (postedComment) {
                    [_comments insertObject:postedComment atIndex:0];
                }
                
                _commentTextField.text = @"";
                [HUD hideAnimated:YES afterDelay:1];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}

#pragma mark - 软键盘隐藏
- (void)keyBoardHiden:(UITapGestureRecognizer *)tap
{
    [_commentTextField resignFirstResponder];
    [self.view removeGestureRecognizer:_tap];
}

#pragma mark - 按钮功能
- (IBAction)buttonClick:(UIButton *)sender {
    //先判断是否登录
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        if (sender.tag == 1) {
            [self favOrNoFavType];
        }
    }
    if (sender.tag == 2) {
        [self shareForOthers];
    }
}

- (void)favOrNoFavType
{
    //收藏
    NSString *blogDetailUrlStr = [NSString stringWithFormat:@"%@favorite_reverse", OSCAPI_V2_PREFIX];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger POST:blogDetailUrlStr
     parameters:@{
                  @"id"  : @(self.questionID),
                  @"type"      : @(2),
                  }
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if ([responseObject[@"code"] integerValue]== 1) {
                _questionDetail.favorite = [responseObject[@"result"][@"favorite"] boolValue];
                
                MBProgressHUD *HUD = [Utils createHUD];
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.label.text = _questionDetail.favorite? @"收藏成功": @"取消收藏";
                
                [HUD hideAnimated:YES afterDelay:1];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFavButtonImage:_questionDetail.favorite];

                [self.tableView reloadData];
            });
        }
        failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"%@",error);
        }];
}

- (void)setFavButtonImage:(BOOL)isFav
{
    if (isFav) {
        [_favButton setImage:[UIImage imageNamed:@"ic_faved_pressed"] forState:UIControlStateNormal];
    } else {
        [_favButton setImage:[UIImage imageNamed:@"ic_fav_pressed"] forState:UIControlStateNormal];
    }
}

- (void)shareForOthers
{
    //分享
    [_commentTextField resignFirstResponder];
    
    NSString *trimmedHTML = [_questionDetail.body deleteHTMLTag];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    NSString *digest = [trimmedHTML substringToIndex:length];
    
    // 微信相关设置
    [UMSocialData defaultData].extConfig.wxMessageType = UMSocialWXMessageTypeWeb;
    [UMSocialData defaultData].extConfig.wechatSessionData.url = _questionDetail.href;
    [UMSocialData defaultData].extConfig.wechatTimelineData.url = _questionDetail.href;
    [UMSocialData defaultData].extConfig.title = _questionDetail.title;
    
    // 手机QQ相关设置
    [UMSocialData defaultData].extConfig.qqData.qqMessageType = UMSocialQQMessageTypeDefault;
    [UMSocialData defaultData].extConfig.qqData.title = _questionDetail.title;
    //[UMSocialData defaultData].extConfig.qqData.shareText = weakSelf.objectTitle;
    [UMSocialData defaultData].extConfig.qqData.url = _questionDetail.href;
    
    // 新浪微博相关设置
    [[UMSocialData defaultData].extConfig.sinaData.urlResource setResourceType:UMSocialUrlResourceTypeDefault url:_questionDetail.href];
    
    [UMSocialSnsService presentSnsIconSheetView:self
                                         appKey:@"54c9a412fd98c5779c000752"
                                      shareText:[NSString stringWithFormat:@"%@...分享来自 %@", digest, _questionDetail.href]
                                     shareImage:[UIImage imageNamed:@"logo"]
                                shareToSnsNames:@[UMShareToWechatTimeline, UMShareToWechatSession, UMShareToQQ, UMShareToSina]
                                       delegate:nil];
}
#pragma mark --- HUD setting
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

@end
