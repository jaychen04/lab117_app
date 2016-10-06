//
//  OSCCommentItem.h
//  iosapp
//
//  Created by Holden on 16/7/22.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCUserItem.h"
#import "OSCReference.h"
#import "OSCReply.h"
#import "TeamMember.h"
#import <UIKit/UIKit.h>

@interface OSCCommentItem : NSObject
@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) int appClient;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) OSCUserItem *author;

//新接口未用到的属性，如需用更改属性名与后台返回名字相同
@property (nonatomic, copy) NSString *pubDate;
@property (nonatomic, strong) NSArray *references;
@property (nonatomic, strong) NSArray *replies;

+ (NSAttributedString *)attributedTextFromReplies:(NSArray *)replies;
@end
