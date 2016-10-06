//
//  NewCommentListViewController.m
//  iosapp
//
//  Created by 李萍 on 16/6/28.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "NewCommentListViewController.h"
#import "NewCommentCell.h"
#import "LoginViewController.h"

#import "OSCAPI.h"
#import "Utils.h"
#import "OSCNewComment.h"
#import "Config.h"

#import <MJExtension.h>
#import <MJRefresh.h>
#import <MBProgressHUD.h>

static NSString *newCommentReuseIdentifier = @"NewCommentCell";
@interface NewCommentListViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;

@property (nonatomic, assign) CommentIdType commentType;
@property (nonatomic, assign) NSInteger sourceId;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, copy) NSString *nextPageToken;

//软键盘size
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, assign) BOOL isReply;
@property (nonatomic, assign) NSInteger selectIndexPath;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation NewCommentListViewController

- (instancetype)initWithCommentType:(CommentIdType)commentType sourceID:(NSInteger)sourceId
{
    self = [super init];
    
    if (self) {
        _commentType = commentType;
        _sourceId = sourceId;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"评论列表";
    _comments = [NSMutableArray new];
    _nextPageToken = @"";
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.commentTextField.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[NewCommentCell class] forCellReuseIdentifier:newCommentReuseIdentifier];
    self.tableView.tableFooterView = [UIView new];
    [self getCommentData:NO];
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        [self.tableView.mj_header beginRefreshing];
        [self getCommentData:YES];
    }];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
//        [self.tableView.mj_header beginRefreshing];
        [self getCommentData:NO];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 获取数据
- (void)getCommentData:(BOOL)isRefresh
{
    NSString *blogDetailUrlStr = [NSString stringWithFormat:@"%@comment", OSCAPI_V2_PREFIX];
    AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
    [manger GET:blogDetailUrlStr
     parameters:@{
                  @"sourceId"  : @(self.sourceId),
                  @"type"      : @(self.commentType),
                  @"pageToken" : _nextPageToken,
                  @"parts"     : @"refer",
                  }
        success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            if ([responseObject[@"code"] integerValue] == 1) {
                NSDictionary *result = responseObject[@"result"];
                NSArray *jsonItems = result[@"items"];
                NSArray *array = [OSCNewComment mj_objectArrayWithKeyValuesArray:jsonItems];
                _nextPageToken = result[@"nextPageToken"];
                
                if (isRefresh) {
                    [_comments removeAllObjects];
                }
                [_comments addObjectsFromArray:array];
                if (isRefresh) {
                    [self.tableView.mj_header endRefreshing];
                }else{
                    [self.tableView.mj_footer endRefreshing];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.tableView reloadData];
                });
            } else {
                MBProgressHUD *hud = [Utils createHUD];
                hud.mode = MBProgressHUDModeCustomView;
                hud.label.text = responseObject[@"message"];
                
                [hud hideAnimated:YES afterDelay:1];
                
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

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_comments.count > 0) {
        return _comments.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewCommentCell *cell = [NewCommentCell new];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (_comments.count > 0) {
        OSCNewComment *comment = _comments[indexPath.row];
        cell.comment = comment;
        
        if (comment.refer.author.length > 0) {
            cell.referCommentView.hidden = NO;
        } else {
            cell.referCommentView.hidden = YES;
        }
        
        cell.commentButton.tag = indexPath.row;
        [cell.commentButton addTarget:self action:@selector(selectedToComment:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_comments.count > indexPath.row) {
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:14];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        
        OSCNewComment *blogComment = _comments[indexPath.row];
        label.attributedText = [NewCommentCell contentStringFromRawString:blogComment.content];
        
        CGFloat height = [label sizeThatFits:CGSizeMake(tableView.frame.size.width - 32, MAXFLOAT)].height;
        
        height += 7;
        OSCNewCommentRefer *refer = blogComment.refer;
        int i = 0;
        while (refer.author.length > 0) {
            NSMutableAttributedString *replyContent = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:\n", refer.author]];
            [replyContent appendAttributedString:[Utils emojiStringFromRawString:[refer.content deleteHTMLTag]]];
            label.attributedText = replyContent;
            height += [label sizeThatFits:CGSizeMake( self.tableView.frame.size.width - 60 - (i+1)*8, MAXFLOAT)].height + 12;
            i++;
            refer = refer.refer;
        }
        
        return height + 71;
    }
    return 0;
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
    NSLog(@"send mesage");
    
    if (_isReply) {
        OSCNewComment *comment = _comments[_selectIndexPath];
        if ([Config getOwnID] == 0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
        } else {
            [self sendComment:comment.id authorID:comment.authorId];
        }
        
    } else {
        if (_commentTextField.text.length > 0) {
            if ([Config getOwnID] == 0) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
                LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                [self.navigationController pushViewController:loginVC animated:YES];
            } else {
                [self sendComment:0 authorID:0];
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

#pragma mark - 评论
- (void)selectedToComment:(UIButton *)button
{
    OSCNewComment *comment = _comments[button.tag];

    if (_selectIndexPath == button.tag) {
        _isReply = !_isReply;
    } else {
        _isReply = YES;
    }
    _selectIndexPath = button.tag;

    if (_isReply) {
        if (comment.authorId > 0) {
            _commentTextField.text = [NSString stringWithFormat:@"@%@", comment.author];
            _commentTextField.placeholder = [NSString stringWithFormat:@"@%@", comment.author];
        } else {
            MBProgressHUD *hud = [Utils createHUD];
            hud.mode = MBProgressHUDModeCustomView;
            hud.label.text = @"该用户不存在，不可引用回复";
            [hud hideAnimated:YES afterDelay:1];
        }
        
    } else {
        _commentTextField.text = @"";
        _commentTextField.placeholder = @"我要评论";
    }
    
    [_commentTextField becomeFirstResponder];
}

#pragma mark - 发评论
- (void)sendComment:(NSInteger)replyID authorID:(NSInteger)authorID
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    } else {
        
        AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
        
        [manger POST:[NSString stringWithFormat:@"%@comment_pub", OSCAPI_V2_PREFIX]
          parameters:@{
                       @"sourceId"   : @(self.sourceId),
                       @"type"       : @(self.commentType),
                       @"content"    : _commentTextField.text,
                       @"replyId"    : @(replyID),
                       @"reAuthorId" : @(authorID),
                       }
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 if ([responseObject[@"code"]integerValue] == 1) {
                     MBProgressHUD *HUD = [Utils createHUD];
                     HUD.mode = MBProgressHUDModeCustomView;
                     HUD.label.text = @"评论成功";
                     
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
}

@end
