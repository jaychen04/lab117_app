//
//  OSCMessageCenterModel.h
//  iosapp
//
//  Created by Graphic-one on 16/8/23.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,OSCOriginType){
    OSCOriginTypeLinkNews = 0,      //链接新闻
    OSCOriginTypeSoftWare = 1,      //软件推荐
    OSCOriginTypeForum = 2,         //讨论区帖子
    OSCOriginTypeBlog = 3,          //博客
    OSCOriginTypeTranslation = 4,   //翻译文章
    OSCOriginTypeActivity = 5,      //活动类型
    OSCOriginTypeInfo = 6,          //资讯
    OSCOriginTypeTweet = 100        //动弹
};

typedef NS_ENUM(NSInteger,OSCPrivateType){
    OSCPrivateTypeText = 1,     //文本
    OSCPrivateTypeImage = 3,    //图片
    OSCPrivateTypeFile = 5      //文件
};

@interface OSCMessageCenter : NSObject
 /**
  * MessageItem ---> 私信列表Item
  *
  * AtMeItem    ---> @我列表Item
  *
  * CommentItem ---> 评论我列表Item
  */
@end

#pragma mark --- 私信列表Item
@class MessageSender;
@interface MessageItem : NSObject

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, copy) NSString *pubDate;

@property (nonatomic, assign) OSCPrivateType type;

@property (nonatomic, strong) MessageSender *sender;

@property (nonatomic, copy) NSString *resource;

@end

@interface MessageSender : NSObject

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *portrait;

@end


#pragma mark --- @我列表Item
@class OSCOrigin,OSCReceiver;
@interface AtMeItem : NSObject

@property (nonatomic, strong) OSCReceiver *author;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, strong) OSCOrigin *origin;

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, assign) NSInteger appClient;

@property (nonatomic, copy) NSString *pubDate;

@property (nonatomic, assign) NSInteger commentCount;

@end

@interface OSCOrigin : NSObject

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, copy) NSString *href;

@property (nonatomic, copy) NSString *desc;

@property (nonatomic, assign) NSInteger type;

@property (nonatomic,assign) OSCOriginType originType;

@end

@interface OSCReceiver : NSObject

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *portrait;

@end


#pragma mark --- 评论我列表Item
@class OSCOrigin,OSCReceiver;
@interface CommentItem : NSObject

@property (nonatomic, strong) OSCReceiver *author;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, strong) OSCOrigin *origin;

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, assign) NSInteger appClient;

@property (nonatomic, copy) NSString *pubDate;

@property (nonatomic, assign) NSInteger commentCount;

@end

















