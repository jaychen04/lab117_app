//
//  HomepageViewController.m
//  iosapp
//
//  Created by AeternChan on 7/18/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "HomepageViewController.h"
#import "Utils.h"
#import "Config.h"
#import "OSCAPI.h"
#import "OSCNotice.h"
#import "OSCUser.h"
#import "OSCUserItem.h"
#import "SwipableViewController.h"
#import "FriendsViewController.h"
#import "FavoritesViewController.h"
#import "MessageCenter.h"
#import "LoginViewController.h"
#import "MyBasicInfoViewController.h"
#import "TeamAPI.h"
#import "TeamTeam.h"
#import "TeamCenter.h"
#import "AppDelegate.h"
#import "FeedBackViewController.h"
#import "SettingsPage.h"
#import "ActivitiesViewController.h"
#import "MyBlogsViewController.h"
#import "HomeButtonCell.h"
#import "UIScrollView+ScalableCover.h"
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "HomePageHeadView.h"
#import "ImageViewerController.h"

#import "OSCMessageCenterController.h"

#import "TweetTableViewController.h"
#import "OSCFavorites.h"

#import <MBProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MJRefresh.h>
#import <MJExtension.h>

static NSString *reuseIdentifier = @"HomeButtonCell";


#define screen_height [UIScreen mainScreen].bounds.size.height - 44
@interface HomepageViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *myQRCodeImageView;

@property (nonatomic, assign) int64_t myID;
@property (nonatomic, strong) OSCUser *myProfile;
@property (nonatomic, strong) OSCUserItem *myInfo;
@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic, strong) NSMutableArray *noticeCounts;
@property (nonatomic, assign) int badgeValue;

@property (nonatomic, strong) UIImageView * imageView;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) HomePageHeadView *homePageHeadView;
@property (nonatomic, strong) UIView *statusBarView;//状态栏
@property (nonatomic, assign) BOOL isNewFans;

@end

@implementation HomepageViewController

- (void)dawnAndNightMode
{
    self.refreshControl.tintColor = [UIColor refreshControlColor];
    
    [self refreshHeaderView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noticeUpdateHandler:)
                                                 name:OSCAPI_USER_NOTICE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userRefreshHandler:)
                                                 name:@"userRefresh"
                                               object:nil];
    
    _noticeCounts = [NSMutableArray arrayWithArray:@[@(0), @(0), @(0)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.tableHeaderView = self.homePageHeadView;
    
    [self refreshHeaderView];
    [self statusBarViewState];
    self.tableView.backgroundView.backgroundColor = [UIColor redColor];
//    [self navigationBarClearColor:YES];//test1
    
    [self refresh];

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    self.homePageHeadView = nil;
    self.tableView.tableHeaderView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _imageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
    self.tableView.backgroundColor = [UIColor themeColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.bounces = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"HomeButtonCell" bundle:nil] forCellReuseIdentifier:reuseIdentifier];
//    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    _myID = [Config getOwnID];
    [self refreshHeaderView];
    
    [self refresh];
    
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - dealloc
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - 状态栏
- (void)statusBarViewState
{
    _statusBarView = [[UIView alloc] initWithFrame:CGRectMake(-[UIScreen mainScreen].bounds.size.width, -20, [UIScreen mainScreen].bounds.size.width*3, 20)];
    _statusBarView.backgroundColor = [UIColor colorWithHex:0x24CF5F];
    [self.view addSubview:_statusBarView];
}

#pragma mark - 处理导航栏下1px横线
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

#pragma mark - 刷新
- (void)refresh
{
    _myID = [Config getOwnID];
    if (_myID == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshHeaderView];
            [self.refreshControl endRefreshing];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    } else {
        //新用户信息接口
        //*
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCJsonManager];
        
        NSString *strUrl = [NSString stringWithFormat:@"%@user_info", OSCAPI_V2_PREFIX];
        
        [manager GET:strUrl
          parameters:nil
             success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                 NSInteger code = [responseObject[@"code"] integerValue];
                 if (code == 1) {
                     _myInfo = [OSCUserItem mj_objectWithKeyValues:responseObject[@"result"]];
                 }
                 
                 [Config updateProfile:[self changeUpdateWithOSCUser:_myInfo]];
                 
                 [self refreshHeaderView];
                 [self.refreshControl endRefreshing];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadData];
                 });
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.label.text = @"网络异常，加载失败";
                 
                 [HUD hideAnimated:YES afterDelay:1];
                 
                 [self.refreshControl endRefreshing];
             }];
        //*/
    }
}

- (OSCUser *)changeUpdateWithOSCUser:(OSCUserItem *)userItem
{
    OSCUser *user = [[OSCUser alloc] init];
    
    user.userID = userItem.id;
    user.name = userItem.name;
    user.portraitURL = [NSURL URLWithString:userItem.portrait];
    
    user.gender = [NSString stringWithFormat:@"%d", userItem.gender];
    user.desc = userItem.desc;
    user.relationship = userItem.relation;
    
    user.developPlatform = userItem.more.platform;
    user.expertise = userItem.more.expertise;
    user.location = userItem.more.city;
    user.joinTime = [NSDate dateFromString:userItem.more.joinDate];
    
    user.score = userItem.statistics.score;
    user.tweetCount = userItem.statistics.tweet;
    user.favoriteCount = userItem.statistics.collect;
    user.fansCount = userItem.statistics.fans;
    user.followersCount = userItem.statistics.follow;
    
    return user;
}

#pragma mark - refresh header

- (void)refreshHeaderView
{
    _myProfile = [Config myProfile];
    
    _isLogin = _myID != 0;
    
    if (_isLogin) {
        [self.homePageHeadView.userPortrait sd_setImageWithURL:_myProfile.portraitURL
                                              placeholderImage:[UIImage imageNamed:@"default-portrait"]
                                                       options:SDWebImageContinueInBackground | SDWebImageHandleCookies
                                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                         if (!image) {return;}
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"TweetUserUpdate" object:@(YES)];
                                                     }];
        self.homePageHeadView.descLable.hidden = NO;
        self.homePageHeadView.creditLabel.hidden = NO;
        self.homePageHeadView.creditLabel.text = [NSString stringWithFormat:@"积分:%d", _myProfile.score];
        self.homePageHeadView.descLable.text = _myProfile.desc.length ? _myProfile.desc : @"这个人很懒，啥也没写";
    
        [self.homePageHeadView.codeButton addTarget:self action:@selector(showCodeAction) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        
        self.homePageHeadView.userPortrait.image = [UIImage imageNamed:@"default-portrait"];
        self.homePageHeadView.descLable.hidden = YES;
        self.homePageHeadView.creditLabel.hidden = YES;
    }
    
    self.homePageHeadView.nameLabel.text = _isLogin ? _myProfile.name : @"点击头像登录";
    self.homePageHeadView.genderImageView.hidden = YES;
    if ([_myProfile.gender isEqualToString:@"1"]) {
        [self.homePageHeadView.genderImageView setImage:[UIImage imageNamed:@"ic_male"]];
        self.homePageHeadView.genderImageView.hidden = NO;
    } else if ([_myProfile.gender isEqualToString:@"2"]) {
        [self.homePageHeadView.genderImageView setImage:[UIImage imageNamed:@"ic_female"]];
        self.homePageHeadView.genderImageView.hidden = NO;
    }
    
    [self.homePageHeadView.setUpButton addTarget:self action:@selector(setUpAction) forControlEvents:UIControlEventTouchUpInside];
    [self.homePageHeadView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPortraitAction)]];
    self.homePageHeadView.userInteractionEnabled = YES;
    
    [self setUpSubviews];
}


#pragma mark - customize subviews

- (void)setUpSubviews
{
    [self.homePageHeadView.userPortrait setBorderWidth:2.0 andColor:[UIColor whiteColor]];
    [self.homePageHeadView.userPortrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changePortraitAction)]];
    
    self.refreshControl.tintColor = [UIColor refreshControlColor];
}

/*
#pragma mark - 弹性HeaderView 刷新
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //获取偏移量
    CGPoint offset = scrollView.contentOffset;
    
    //判断是否改变
    if (offset.y < 0) {
        CGRect rect = self.homePageHeadView.drawView.frame;
        //我们只需要改变图片的y值和高度即可
        rect.origin.y = offset.y;
        //
        CGFloat homeViewHeight = 0;
        if ([UIScreen mainScreen].bounds.size.height < 500) {
            homeViewHeight = 250;
        } else {
            homeViewHeight = screen_height - 202;//45*4+48
        }
        
        if (_isLogin) {
            homeViewHeight = homeViewHeight - 61;
        }
        rect.size.height = homeViewHeight - offset.y;
        
        //
//        if ([UIScreen mainScreen].bounds.size.height < 500) {
//            rect.size.height = 250 - offset.y;
//        } else {
//            rect.size.height = screen_height - 202 - offset.y;
//        }
        
        self.homePageHeadView.drawView.frame = rect;
    }
}
 */

#pragma mark - change Portrait
- (void)changePortraitAction
{
    if (![Utils isNetworkExist]) {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeText;
        HUD.label.text = @"网络无连接，请检查网络";
        
        [HUD hideAnimated:YES afterDelay:1];
    } else {
        if ([Config getOwnID] == 0) {
            [self statusBarViewState];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"选择操作" message:nil delegate:self
                                                      cancelButtonTitle:@"取消" otherButtonTitles:@"更换头像", @"查看大头像", nil];
            alertView.tag = 1;
            
            [alertView show];
        }
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {return;}
    
    if (alertView.tag == 1)
    {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        } else if (buttonIndex == 1){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"选择图片" message:nil delegate:self
                                                      cancelButtonTitle:@"取消" otherButtonTitles:@"相机", @"相册", nil];
            alertView.tag = 2;
            
            [alertView show];
            
        } else {
            
            NSString *str = [NSString stringWithFormat:@"%@", _myInfo.portrait];
            
            if (str.length == 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"尚未设置头像" message:nil delegate:self
                                                          cancelButtonTitle:@"知道了" otherButtonTitles: nil];
                [alertView show];
                return ;
            }
            
            NSArray *array1 = [str componentsSeparatedByString:@"_"];
            
            NSArray *array2 = [array1[1] componentsSeparatedByString:@"."];
            
            NSString *bigPortraitURL = [NSString stringWithFormat:@"%@_200.%@", array1[0], array2[1]];
            
            ImageViewerController *imgViewweVC = [[ImageViewerController alloc] initWithImageURL:[NSURL URLWithString:bigPortraitURL]];
            
            [self presentViewController:imgViewweVC animated:YES completion:nil];
        }
        
    } else {
        if (buttonIndex == 1) {
            if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Device has no camera"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles: nil];
                
                [alertView show];
            } else {
                UIImagePickerController *imagePickerController = [UIImagePickerController new];
                imagePickerController.delegate = self;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.allowsEditing = YES;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
                
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
            
            
        } else {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            imagePickerController.delegate = self;
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePickerController.allowsEditing = YES;
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }
}

- (void)updatePortrait
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.label.text = @"正在上传头像";

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCJsonManager];
    
    NSString *strUrl = [NSString stringWithFormat:@"%@user_edit_portrait", OSCAPI_V2_PREFIX];
    
    [manager POST:strUrl
parameters:@{@"uid":@([Config getOwnID])}
constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if (_image) {
            [formData appendPartWithFileData:[Utils compressImage:_image]
                                        name:@"portrait"
                                    fileName:@"img.jpg"
                                    mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 1) {
            _myInfo = [OSCUserItem mj_objectWithKeyValues:responseObject[@"result"]];
            
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
            HUD.label.text = @"头像更新成功";
        } else {
            HUD.label.text = @"头像更换失败";
        }
        [HUD hideAnimated:YES afterDelay:1];
        
        [Config updateProfile:[self changeUpdateWithOSCUser:_myInfo]];
        
        [self refreshHeaderView];
        [self.refreshControl endRefreshing];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.label.text = @"网络异常，头像更换失败";
        
        [HUD hideAnimated:YES afterDelay:1];
    }];
    
}


#pragma mark - UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _image = info[UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:^ {
        [self updatePortrait];
    }];
}

- (void)tapPortraitAction
{
    if (![Utils isNetworkExist]) {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeText;
        HUD.label.text = @"网络无连接，请检查网络";
        
        [HUD hideAnimated:YES afterDelay:1];
    } else {
        [self statusBarViewState];
        
        if ([Config getOwnID] == 0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
        } else {
            MyBasicInfoViewController *basicInfoVC = [MyBasicInfoViewController new];
            basicInfoVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:basicInfoVC animated:YES];
        }
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!_isLogin) {
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_isLogin) {
        return 4;
    } else {
        switch (section) {
            case 0:
                return 1;
                break;
            case 1:
                return 4;
                break;
                
            default:
                break;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isLogin) {
        return 45;
    } else {
        if (indexPath.section == 0) {
            return 61;
        } else {
            return 45;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isLogin) {
        UITableViewCell *cell = [UITableViewCell new];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIView *selectedBackground = [UIView new];
        selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
        [cell setSelectedBackgroundView:selectedBackground];
        
        cell.backgroundColor = [UIColor whiteColor];
        
        cell.textLabel.text = @[@"我的消息", @"我的博客", @"我的活动", @"我的团队"][indexPath.row];
        cell.imageView.image = [UIImage imageNamed:@[@"ic_my_messege", @"ic_my_blog", @"ic_my_event", @"ic_my_team"][indexPath.row]];
        
        
        cell.textLabel.textColor = [UIColor titleColor];
        
        if (indexPath.row == 0 && indexPath.section == 1) {
            if (_badgeValue == 0) {
                cell.accessoryView = nil;
            } else {
//                UIView *accessoryBadge = [UIView new];
//                accessoryBadge.backgroundColor = [UIColor redColor];
//                accessoryBadge.clipsToBounds = YES;
//                accessoryBadge.layer.cornerRadius = 3;
                UILabel *accessoryBadge = [UILabel new];
                accessoryBadge.backgroundColor = [UIColor redColor];
                accessoryBadge.text = [@(_badgeValue) stringValue];
                accessoryBadge.textColor = [UIColor whiteColor];
                accessoryBadge.textAlignment = NSTextAlignmentCenter;
                accessoryBadge.layer.cornerRadius = 11;
                accessoryBadge.clipsToBounds = YES;
                
                CGFloat width = [accessoryBadge sizeThatFits:CGSizeMake(MAXFLOAT, 26)].width + 8;
                width = width > 26? width: 22;
                accessoryBadge.frame = CGRectMake(0, 0, 6, 6);
                cell.accessoryView = accessoryBadge;
            }
        }
        
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
        
        return cell;
    } else {
        if (indexPath.section == 0) {
            
            HomeButtonCell *buttonCell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
            buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [buttonCell.creditButton setTitle:[Utils numberLimitString:_myProfile.tweetCount] forState:UIControlStateNormal];//动弹数
            [buttonCell.collectionButton setTitle:[Utils numberLimitString:_myProfile.favoriteCount] forState:UIControlStateNormal];
            [buttonCell.followingButton setTitle:[Utils numberLimitString:_myProfile.followersCount] forState:UIControlStateNormal];
            [buttonCell.fanButton setTitle:[Utils numberLimitString:_myProfile.fansCount] forState:UIControlStateNormal];
            buttonCell.redPointView.hidden = !self.isNewFans;
            
            [buttonCell.creditButton addTarget:self action:@selector(pushTweetList) forControlEvents:UIControlEventTouchUpInside];
            [buttonCell.creditTitleButton addTarget:self action:@selector(pushTweetList) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonCell.collectionButton addTarget:self action:@selector(pushFavoriteSVC) forControlEvents:UIControlEventTouchUpInside];
            [buttonCell.collectionTitleButton addTarget:self action:@selector(pushFavoriteSVC) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonCell.followingTitleButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            [buttonCell.followingButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonCell.fanButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            [buttonCell.fanTitleButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            
            return buttonCell;
        } else {
            
            UITableViewCell *cell = [UITableViewCell new];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            UIView *selectedBackground = [UIView new];
            selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
            [cell setSelectedBackgroundView:selectedBackground];
            
            cell.backgroundColor = [UIColor whiteColor];//colorWithHex:0xF9F9F9
            
            cell.textLabel.text = @[@"我的消息", @"我的博客", @"我的活动", @"我的团队"][indexPath.row];
            cell.imageView.image = [UIImage imageNamed:@[@"ic_my_messege", @"ic_my_blog", @"ic_my_event", @"ic_my_team"][indexPath.row]];
            
            cell.textLabel.textColor = [UIColor titleColor];
            
            if (indexPath.row == 0 && indexPath.section == 1) {
                if (_badgeValue == 0) {
                    cell.accessoryView = nil;
                } else {
                    UILabel *accessoryBadge = [UILabel new];
                    accessoryBadge.backgroundColor = [UIColor redColor];
                    accessoryBadge.text = [@(_badgeValue) stringValue];
                    accessoryBadge.textColor = [UIColor whiteColor];
                    accessoryBadge.textAlignment = NSTextAlignmentCenter;
                    accessoryBadge.layer.cornerRadius = 11;
                    accessoryBadge.clipsToBounds = YES;
                    
                    CGFloat width = [accessoryBadge sizeThatFits:CGSizeMake(MAXFLOAT, 26)].width + 8;
                    width = width > 26? width: 22;
                    accessoryBadge.frame = CGRectMake(0, 0, width, 22);
                    cell.accessoryView = accessoryBadge;
                }
            }
            
            cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
            cell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
            
            return cell;
        }
    }
    
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self statusBarViewState];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!_isLogin) {
        if ([Config getOwnID] == 0) {
            [self statusBarViewState];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
            return;
        }
        
        if (indexPath.section == 0) {
            switch (indexPath.row) {
                case 0: {
                    _badgeValue = 0;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    });
                    self.navigationController.tabBarItem.badgeValue = nil;
                    
                    OSCMessageCenterController* messageCenter = [[OSCMessageCenterController alloc] initWithNoticeCounts:_noticeCounts];
                    messageCenter.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:messageCenter animated:YES];
                    
                    break;
                }
                case 1: {
                    MyBlogsViewController *blogsVC = [[MyBlogsViewController alloc] initWithUserID:(NSInteger)_myID];
                    blogsVC.navigationItem.title = @"我的博客";
                    blogsVC.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:blogsVC animated:YES];
                    break;
                }
                case 2: {
                    ActivitiesViewController *myActivitiesVc = [[ActivitiesViewController alloc] initWithUID:[Config getOwnID]];
                    myActivitiesVc.navigationItem.title = @"我的活动";
                    myActivitiesVc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:myActivitiesVc animated:YES];
                    break;
                }
                case 3: {
                    TeamCenter *teamCenter = [TeamCenter new];
                    teamCenter.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:teamCenter animated:YES];
                    
                    break;
                }
                default: break;
            }
        }
    } else {
        if ([Config getOwnID] == 0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
            return;
        }
        
        if (indexPath.section == 1) {
            switch (indexPath.row) {
                case 0: {
                    _badgeValue = 0;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    });
                    self.navigationController.tabBarItem.badgeValue = nil;
                    
                    OSCMessageCenterController* messageCenter = [[OSCMessageCenterController alloc] initWithNoticeCounts:_noticeCounts];
                    messageCenter.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:messageCenter animated:YES];
                    
                    break;
                }
                case 1: {
                    MyBlogsViewController *blogsVC = [[MyBlogsViewController alloc] initWithUserID:(NSInteger)_myID];
                    blogsVC.navigationItem.title = @"我的博客";
                    blogsVC.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:blogsVC animated:YES];
                    break;
                }
                case 2: {
                    ActivitiesViewController *myActivitiesVc = [[ActivitiesViewController alloc] initWithUID:[Config getOwnID]];
                    myActivitiesVc.navigationItem.title = @"我的活动";
                    myActivitiesVc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:myActivitiesVc animated:YES];
                    break;
                }
                case 3: {
                    TeamCenter *teamCenter = [TeamCenter new];
                    teamCenter.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:teamCenter animated:YES];
                    
                    break;
                }
                default: break;
            }
        }
    }
}

#pragma mark - 处理通知
- (void)noticeUpdateHandler:(NSNotification *)notification
{
    NSArray *noticeCounts = [notification object];
    
    OSCNotice *oldNotice = [Config getNotice];
    int oldNumber = oldNotice.mention + oldNotice.letter + oldNotice.review;
    
    OSCNotice *newNotice = [OSCNotice new];
    
    __block int sumOfCount = 0;
    [noticeCounts enumerateObjectsUsingBlock:^(NSNumber *count, NSUInteger idx, BOOL *stop) {
        switch (idx) {
            case 0:
                _noticeCounts[idx] =  @([count intValue] + oldNotice.mention);
                newNotice.mention = [_noticeCounts[idx] intValue];
                sumOfCount += [count intValue];
                break;
            case 1:
                _noticeCounts[idx] =  @([count intValue] + oldNotice.review);
                newNotice.review = [_noticeCounts[idx] intValue];
                sumOfCount += [count intValue];
                break;
            case 2:
                _noticeCounts[idx] =  @([count intValue] + oldNotice.letter);
                newNotice.letter = [_noticeCounts[idx] intValue];
                sumOfCount += [count intValue];
                break;
            case 3:
                newNotice.fans = [count intValue] + oldNotice.fans;
                break;
            case 4:
                newNotice.like = [count intValue] + oldNotice.like;
                break;
                
            default:
                break;
        }
    }];
    
    if (newNotice.fans > 0) {
        self.isNewFans = YES;
    } else {
        self.isNewFans = NO;
    }
    
    [Config saveNotice:newNotice];
    
    _badgeValue = sumOfCount + oldNumber;
    if (_badgeValue) {
        self.navigationController.tabBarItem.badgeValue = [@(_badgeValue) stringValue];
    } else {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    });
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_badgeValue];
}


- (void)userRefreshHandler:(NSNotification *)notification
{
    _myID = [Config getOwnID];
    
    [self refreshHeaderView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - 功能
#pragma mark - 动弹
- (void)pushTweetList
{
    [self statusBarViewState];
    
    TweetTableViewController *myFriendTweetViewCtl = [[TweetTableViewController alloc] initTweetListWithType:NewTweetsTypeOwnTweets];
    myFriendTweetViewCtl.title = @"动弹";
    myFriendTweetViewCtl.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:myFriendTweetViewCtl animated:YES];
}

#pragma mark - 收藏
- (void)pushFavoriteSVC
{
    [self statusBarViewState];
    /*
     
     全部收藏
     1 软件
     2 问答
     3 博客
     4 翻译
     5 活动
     6 新闻
     */
    SwipableViewController *favoritesSVC = [[SwipableViewController alloc] initWithTitle:@"收藏"
                                                                            andSubTitles:@[@"综合", @"软件", @"问答", @"博客", @"翻译", @"资讯"]
                                                                          andControllers:@[
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeAll],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeSoftware],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeQuestion],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeBlog],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeTranslate],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeNews]
                                                                                           ]];
    favoritesSVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:favoritesSVC animated:YES];
}

#pragma mark - 关注/粉丝
- (void)pushFriendsSVC:(UIButton *)button
{
    [self statusBarViewState];
    
    if (button.tag == 1) {
        FriendsViewController *friendVC = [[FriendsViewController alloc] initUserId:_myID andRelation:OSCAPI_USER_FOLLOWS];
        friendVC.title = @"关注";
        friendVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:friendVC animated:YES];
    } else {

        FriendsViewController *friendVC = [[FriendsViewController alloc] initUserId:_myID andRelation:OSCAPI_USER_FANS];
        friendVC.title = @"粉丝";
        friendVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:friendVC animated:YES];
    }
}

#pragma mark - setup
- (void)setUpAction {
    
    [self statusBarViewState];
    
    SettingsPage *settingPage = [SettingsPage new];
    settingPage.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:settingPage animated:YES];
}

#pragma mark - 二维码相关
- (void)showCodeAction {
    
    if ([Config getOwnID] == 0) {
        [self statusBarViewState];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    } else {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.customView.backgroundColor = [UIColor whiteColor];
        
        HUD.label.text = @"扫一扫上面的二维码，加我为好友";
        HUD.label.font = [UIFont systemFontOfSize:13];
        HUD.label.textColor = [UIColor grayColor];
        HUD.customView = self.myQRCodeImageView;
        [HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideHUD:)]];
    }
}

- (void)hideHUD:(UIGestureRecognizer *)recognizer
{
    [(MBProgressHUD *)recognizer.view hideAnimated:YES];
}

- (UIImageView *)myQRCodeImageView
{
    if (!_myQRCodeImageView) {
        UIImage *myQRCode = [Utils createQRCodeFromString:[NSString stringWithFormat:@"http://my.oschina.net/u/%llu", [Config getOwnID]]];
        _myQRCodeImageView = [[UIImageView alloc] initWithImage:myQRCode];
    }
    
    return _myQRCodeImageView;
}

#pragma mark - 初始化
- (HomePageHeadView *)homePageHeadView {
    if(_homePageHeadView == nil) {
        CGFloat homeViewHeight = 0;
        if ([UIScreen mainScreen].bounds.size.height < 500) {
            homeViewHeight = 330;
        } else {
            homeViewHeight = screen_height - 202;//45*4+48
        }
        
        if (_isLogin) {
            homeViewHeight = homeViewHeight - 61;
        }
        
        _homePageHeadView = [[HomePageHeadView alloc] initWithFrame:(CGRect){{0,0},{[UIScreen mainScreen].bounds.size.width, homeViewHeight}}];
    }
    return _homePageHeadView;
}

@end
