//
//  OSCUserItem.h
//  iosapp
//
//  Created by Holden on 16/7/22.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSCUserStatistics,OSCUserMoreInfo;
@interface OSCUserItem : NSObject

@property (nonatomic, assign) long id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSString *portrait;

@property (nonatomic, assign) int gender;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, assign) int relation;


@property (nonatomic, strong) OSCUserMoreInfo *more;
@property (nonatomic, strong) OSCUserStatistics *statistics;


@end


/** 他人动态主页用到的Item*/
@interface OSCUserHomePageItem : NSObject

@property (nonatomic, assign) NSInteger gender;

@property (nonatomic, copy) NSString *portrait;

@property (nonatomic, assign) NSInteger id;

@property (nonatomic, strong) OSCUserMoreInfo *more;

@property (nonatomic, assign) NSInteger relation;

@property (nonatomic, strong) OSCUserStatistics *statistics;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *desc;

@end


@interface OSCUserStatistics : NSObject

@property (nonatomic, assign) NSInteger follow;

@property (nonatomic, assign) NSInteger score;

@property (nonatomic, assign) NSInteger answer;

@property (nonatomic, assign) NSInteger collect;

@property (nonatomic, assign) NSInteger tweet;

@property (nonatomic, assign) NSInteger discuss;

@property (nonatomic, assign) NSInteger fans;

@property (nonatomic, assign) NSInteger blog;

@end


@interface OSCUserMoreInfo : NSObject

@property (nonatomic, copy) NSString *expertise;

@property (nonatomic, copy) NSString *joinDate;

@property (nonatomic, copy) NSString *city;

@property (nonatomic, copy) NSString *platform;

@end

