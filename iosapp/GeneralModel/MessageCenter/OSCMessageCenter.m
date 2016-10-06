//
//  OSCMessageCenterModel.m
//  iosapp
//
//  Created by Graphic-one on 16/8/23.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "OSCMessageCenter.h"

@implementation OSCMessageCenter

@end

#pragma mark --- 私信列表Item
@implementation MessageItem @end

@implementation MessageSender @end

#pragma mark --- @我列表Item
@implementation AtMeItem @end

@implementation OSCOrigin

- (void)setType:(NSInteger)type{
    _type = type;
    
    switch (type) {
        case 0:
            _originType = OSCOriginTypeLinkNews;
            break;
        case 1:
            _originType = OSCOriginTypeSoftWare;
            break;
        case 2:
            _originType = OSCOriginTypeForum;
            break;
        case 3:
            _originType = OSCOriginTypeBlog;
            break;
        case 4:
            _originType = OSCOriginTypeTranslation;
            break;
        case 5:
            _originType = OSCOriginTypeActivity;
            break;
        case 6:
            _originType = OSCOriginTypeInfo;
            break;
        case 100:
            _originType = OSCOriginTypeTweet;
            break;
            
        default:
            _originType = NSNotFound;
            break;
    }
}

@end

@implementation OSCReceiver @end

#pragma mark --- 评论列表Item
@implementation CommentItem @end