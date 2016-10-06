//
//  TweetDetailsWithBottomBarViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 1/14/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "TweetDetailsWithBottomBarViewController.h"
#import "TweetDetailsViewController.h"
#import "CommentsViewController.h"
#import "OSCUserHomePageController.h"
#import "ImageViewerController.h"
#import "OSCTweet.h"
#import "OSCCommentItem.h"
#import "TweetDetailsCell.h"
#import "Config.h"
#import "Utils.h"

#import "TweetDetailNewTableViewController.h"

#import <objc/runtime.h>
#import <MBProgressHUD.h>


@interface TweetDetailsWithBottomBarViewController () <UIWebViewDelegate>

@property (nonatomic, strong) TweetDetailNewTableViewController *tweetDetailsNewVC;
@property (nonatomic, assign) int64_t tweetID;
@property (nonatomic, assign) BOOL isReply;

@end

@implementation TweetDetailsWithBottomBarViewController

- (instancetype)initWithTweetID:(int64_t)tweetID
{
    self = [super initWithModeSwitchButton:NO];
    if (self) {
		
        self.hidesBottomBarWhenPushed = YES;
        _tweetID = tweetID;
        _tweetDetailsNewVC = [[TweetDetailNewTableViewController alloc]init];
        _tweetDetailsNewVC.tweetID = _tweetID;
        [self addChildViewController:_tweetDetailsNewVC];
        
        [self setUpBlock];
    }
    
    return self;
}



- (void)setUpBlock
{
    __weak TweetDetailsWithBottomBarViewController *weakSelf = self;

    _tweetDetailsNewVC.didTweetCommentSelected = ^(OSCCommentItem *comment) {
        NSString *authorString = [NSString stringWithFormat:@"@%@ ", comment.author.name];
        
        if ([weakSelf.editingBar.editView.text rangeOfString:authorString].location == NSNotFound) {
            [weakSelf.editingBar.editView replaceRange:weakSelf.editingBar.editView.selectedTextRange withText:authorString];
            [weakSelf.editingBar.editView becomeFirstResponder];
        }
    };
    
    _tweetDetailsNewVC.didScroll = ^ {
        [weakSelf.editingBar.editView resignFirstResponder];
        [weakSelf hideEmojiPageView];
    };

	_tweetDetailsNewVC.didActivatedInputBar = ^ {
        [weakSelf.editingBar.editView becomeFirstResponder];
    };

}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"动弹详情";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setLayout];
	
	
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setLayout
{
    [self.view addSubview:_tweetDetailsNewVC.view];
    
    for (UIView *view in self.view.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *views = @{@"tableView": _tweetDetailsNewVC.view, @"editingBar": self.editingBar};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][editingBar]"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil views:views]];
}


- (void)sendContent
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.label.text = @"评论发送中";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_COMMENT_PUB]
       parameters:@{
                    @"catalog": @(3),
                    @"id": @(_tweetID),
                    @"uid": @([Config getOwnID]),
                    @"content": [Utils convertRichTextToRawText:self.editingBar.editView],
                    @"isPostToMyZone": @(0)
                    }
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
              
              HUD.mode = MBProgressHUDModeCustomView;
              
              if (errorCode == 1) {
                  self.editingBar.editView.text = @"";
                  [self updateInputBarHeight];
                  
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.label.text = @"评论发表成功";
                  
                  [_tweetDetailsNewVC.tableView setContentOffset:CGPointZero animated:NO];
                  [_tweetDetailsNewVC reloadCommentList];
                  
              } else {
                  HUD.label.text = [NSString stringWithFormat:@"错误：%@", errorMessage];
              }
              
              [HUD hideAnimated:YES afterDelay:1];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              HUD.mode = MBProgressHUDModeCustomView;
              HUD.label.text = @"网络异常，动弹发送失败";
              
              [HUD hideAnimated:YES afterDelay:1];
          }];
}








@end
