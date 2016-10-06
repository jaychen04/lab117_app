//
//  TweetTableViewController.h
//  iosapp
//
//  Created by 李萍 on 16/5/23.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "OSCObjsViewController.h"

typedef NS_ENUM(NSUInteger, NewTweetsType)
{
    NewTweetsTypeAllTweets = 1,
    NewTweetsTypeHotestTweets,
    NewTweetsTypeOwnTweets,
};

@interface TweetTableViewController : OSCObjsViewController

@property (nonatomic, copy) void (^didScroll)();

//新接口
-(instancetype)initTweetListWithType:(NewTweetsType)type;
-(instancetype)initTweetListWithTopic:(NSString *)topicTag;
@end
