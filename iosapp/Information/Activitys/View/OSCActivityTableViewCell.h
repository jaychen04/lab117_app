//
//  OSCActivityTableViewCell.h
//  iosapp
//
//  Created by Graphic-one on 16/5/24.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSCActivities.h"

extern NSString* OSCActivityTableViewCell_IdentifierString;

@interface OSCActivityTableViewCell : UITableViewCell

+(instancetype)returnReuseCellFormTableView:(UITableView* )tableView
                                  indexPath:(NSIndexPath *)indexPath
                                 identifier:(NSString *)identifierString;

@property (nonatomic,strong) OSCActivities* viewModel;

@end
