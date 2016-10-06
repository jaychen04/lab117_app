//
//  AppDelegate.m
//  iosapp
//
//  Created by chenhaoxiang on 14-10-13.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import "AppDelegate.h"
#import "OSCThread.h"
#import "Config.h"
#import "UIView+Util.h"
#import "UIColor+Util.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "OSCAPI.h"
#import "OSCUser.h"
#import "PersonSearchViewController.h"
#import "ScanViewController.h"
#import "ShakingViewController.h"
#import "TweetEditingVC.h"
#import "SwipableViewController.h"

#import "RootViewController.h"
#import "OSCTabBarController.h"
#import "SoftWareViewController.h"
#import "QuesAnsDetailViewController.h"
#import "NewsBlogDetailTableViewController.h"
#import "TranslationViewController.h"
#import "ActivityDetailViewController.h"

#import "UMMobClick/MobClick.h"


#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <UMSocial.h>
#import <UMengSocial/UMSocialQQHandler.h>
#import <UMengSocial/UMSocialWechatHandler.h>
#import <UMengSocial/UMSocialSinaHandler.h>

@interface AppDelegate () <UIApplicationDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    _inNightMode = [Config getMode];
	
	//友盟统计SDK
	UMConfigInstance.appKey = @"54c9a412fd98c5779c000752";
	UMConfigInstance.channelId = @"AppStore";	
	[MobClick startWithConfigure:UMConfigInstance];
    
    
    [self loadCookies];
    
    /************ 控件外观设置 **************/
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    NSDictionary *navbarTitleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UITabBar appearance] setTintColor:[UIColor colorWithHex:0x24CF5F]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithHex:0x24cf5f]} forState:UIControlStateSelected];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor navigationbarColor]];
    [[UITabBar appearance] setBarTintColor:[UIColor titleBarColor]];
    
    [UISearchBar appearance].tintColor = [UIColor colorWithHex:0x15A230];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setCornerRadius:14.0];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setAlpha:0.6];
    
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor colorWithHex:0xDCDCDC];
    pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
    
    [[UITextField appearance] setTintColor:[UIColor nameColor]];
    [[UITextView appearance]  setTintColor:[UIColor nameColor]];
    
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    [menuController setMenuVisible:YES animated:YES];
    [menuController setMenuItems:@[
                                   [[UIMenuItem alloc] initWithTitle:@"复制" action:NSSelectorFromString(@"copyText:")],
                                   [[UIMenuItem alloc] initWithTitle:@"删除" action:NSSelectorFromString(@"deleteObject:")]
                                   ]];
    
    /************ 检测通知 **************/
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    /*if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 &&
        [[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
    }*/
    if ([Config getOwnID] != 0) {[OSCThread startPollingNotice];}
    
    
    /************ 友盟分享组件 **************/
    
    [UMSocialData setAppKey:@"54c9a412fd98c5779c000752"];
    [UMSocialWechatHandler setWXAppId:@"wxa8213dc827399101" appSecret:@"5c716417ce72ff69d8cf0c43572c9284" url:@"http://www.umeng.com/social"];
    [UMSocialQQHandler setQQWithAppId:@"100942993" appKey:@"8edd3cc7ca8dcc15082d6fe75969601b" url:@"http://www.umeng.com/social"];
    [UMSocialSinaHandler openSSOWithRedirectURL:@"http://sns.whalecloud.com/sina2/callback"];
    
    
    /************ 第三方登录设置 *************/
    
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:@"3616966952"];
    
    /*3D Touch*/
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {//判定系统版本
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKeyedSubscript:UIApplicationLaunchOptionsShortcutItemKey];
        
        if(shortcutItem)
        {
            [self quickActionWithShortcutItem:shortcutItem];
        }
    }
    
    return YES;
}

- (void)loadCookies
{
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"sessionCookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie: cookie];
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [UMSocialSnsService handleOpenURL:url]             ||
           [WXApi handleOpenURL:url delegate:_loginDelegate]  ||
           [TencentOAuth HandleOpenURL:url]                   ||
           [WeiboSDK handleOpenURL:url delegate:_loginDelegate];
    
//    return [UMSocialSnsService handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    //外部链接打开相关详情界面
    if ([[url scheme] isEqualToString:@"oscapp"]) {
        NSLog(@"Calling Application Bundle ID: %@", sourceApplication);
        NSLog(@"URL scheme:%@", [url scheme]);
        NSLog(@"URL query: %@", [url query]);
        
        OSCTabBarController *tabBarVc = (OSCTabBarController*)((RootViewController*)self.window.rootViewController).contentViewController;
        
//        type=1&id=75112
        
        __block NSInteger type = 0;
        __block NSInteger objId = 0;
        UIViewController *detailVc;
        NSArray *queryArray = [[url query] componentsSeparatedByString:@"&"];
        [queryArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj containsString:@"type"] && ![obj isEqualToString:@"main"]) {
                NSCharacterSet* nonDigits =[[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                type =[[obj stringByTrimmingCharactersInSet:nonDigits] integerValue];
            } else if ([obj containsString:@"id"]) {
                NSCharacterSet* nonDigits =[[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                objId =[[obj stringByTrimmingCharactersInSet:nonDigits] integerValue];
            }
        }];
        switch (type) {
             
            case 1:{
                //37059
                SoftWareViewController *softWareDetailVc = [[SoftWareViewController alloc]initWithSoftWareID:objId];
                detailVc = softWareDetailVc;
                break;
            }
                
            case 2:{
                //2187587
                QuesAnsDetailViewController *quesAnsDetailVC = [QuesAnsDetailViewController new];
                quesAnsDetailVC.questionID = objId;
                detailVc = quesAnsDetailVC;
                break;
            }
                
            case 3:{
                //709321
                NewsBlogDetailTableViewController *blogDetailVc =[[NewsBlogDetailTableViewController alloc]initWithObjectId:objId isBlogDetail:YES];
                detailVc = blogDetailVc;
                break;
            }
                
            case 4:{
                //10003462
                TranslationViewController *translationVc = [TranslationViewController new];
                translationVc.translationId = objId;
                detailVc = translationVc;
                break;
            }
                
            case 5:{
                //2185476
                ActivityDetailViewController *activityDetailVc = [[ActivityDetailViewController alloc] initWithActivityID:objId];
                detailVc = activityDetailVc;
                break;
            }
            case 6:{
                //75112
                NewsBlogDetailTableViewController *newsDetailVc = [[NewsBlogDetailTableViewController alloc]initWithObjectId:objId isBlogDetail:NO];
                detailVc = newsDetailVc;
                break;
            }
                
            default:
                break;
        }
        
        if (detailVc) {
            detailVc.hidesBottomBarWhenPushed = YES;
            [tabBarVc.linkUtilNavController pushViewController:detailVc animated:YES];
        }
        return YES;
    }else {
        return [UMSocialSnsService handleOpenURL:url]             ||
        [WXApi handleOpenURL:url delegate:_loginDelegate]  ||
        [TencentOAuth HandleOpenURL:url]                   ||
        [WeiboSDK handleOpenURL:url delegate:_loginDelegate];
    }
    
//    return [UMSocialSnsService handleOpenURL:url];
}

#pragma mark - 3D Touch
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [self quickActionWithShortcutItem:shortcutItem];
    completionHandler(YES);
}

- (void)quickActionWithShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    NSLog(@"%@",shortcutItem.type);
    
    if ([shortcutItem.type isEqualToString:@"弹一弹"]) {
        TweetEditingVC *tweetEditingVC = [TweetEditingVC new];
        UINavigationController *tweetEditingNav = [[UINavigationController alloc] initWithRootViewController:tweetEditingVC];
        [self.window.rootViewController presentViewController:tweetEditingNav animated:YES completion:nil];
        
    } else if ([shortcutItem.type isEqualToString:@"扫一扫"]) {
        ScanViewController *scanVC = [ScanViewController new];
        UINavigationController *scanNav = [[UINavigationController alloc] initWithRootViewController:scanVC];
        [self.window.rootViewController presentViewController:scanNav animated:NO completion:nil];
        
    } else if ([shortcutItem.type isEqualToString:@"找一找"]) {
        PersonSearchViewController *personSearchVC = [PersonSearchViewController new];
        UINavigationController *personSearchNavVC = [[UINavigationController alloc] initWithRootViewController:personSearchVC];
        [self.window.rootViewController presentViewController:personSearchNavVC animated:YES completion:nil];
        
    } else if ([shortcutItem.type isEqualToString:@"摇一摇"]) {
        ShakingViewController *shakingVC = [ShakingViewController new];
        UINavigationController *shakingNavVC = [[UINavigationController alloc] initWithRootViewController:shakingVC];
        [self.window.rootViewController presentViewController:shakingNavVC animated:YES completion:nil];
        
    }
}


@end
