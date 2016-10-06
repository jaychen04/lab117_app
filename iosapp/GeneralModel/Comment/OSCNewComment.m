//
//  OSCNewComment.m
//  iosapp
//
//  Created by 李萍 on 16/6/22.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "OSCNewComment.h"

@implementation OSCNewComment

////发表评论后解析返回的评论内容，便于显示
//- (instancetype)initWithXML:(ONOXMLElement *)xml
//{
//    if (self = [super init]) {
//        _id = [[[xml firstChildWithTag:@"id"] numberValue] longLongValue];
//        _authorId = [[[xml firstChildWithTag:@"authorid"] numberValue] longLongValue];
//        _authorPortrait = [[xml firstChildWithTag:@"portrait"] stringValue];
//        _author = [[xml firstChildWithTag:@"author"] stringValue];
//        _content = [[xml firstChildWithTag:@"content"] stringValue];
//        _pubDate = [[xml firstChildWithTag:@"pubDate"] stringValue];
//    }
//    return self;
//}


+(NSDictionary *)mj_objectClassInArray{
    return @{
             @"reply" : [OSCNewCommentReply class],
             };
}

@end

//引用
@implementation OSCNewCommentRefer

@end


//回复
@implementation OSCNewCommentReply

@end