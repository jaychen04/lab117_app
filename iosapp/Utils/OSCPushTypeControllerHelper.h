//
//  OSCPushTypeControllerHelper.h
//  iosapp
//
//  Created by Graphic-one on 16/8/31.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OSCOrigin,OSCDiscussOrigin;
@interface OSCPushTypeControllerHelper : NSObject

+ (UIViewController* )pushControllerWithOriginType:(OSCOrigin* )origin;

+ (UIViewController* )pushControllerWithDiscussOriginType:(OSCDiscussOrigin* )discussOrigin;

@end
