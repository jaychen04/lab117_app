//
//  NewsBlogDetailTableViewController.h
//  iosapp
//
//  Created by 巴拉提 on 16/5/30.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSCNewHotBlog.h"

@interface NewsBlogDetailTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottmTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIButton *favButton;

@property (nonatomic)BOOL isBlogDetail;

- (instancetype)initWithObjectId:(NSInteger) objectId isBlogDetail:(BOOL) isBlogDetail;
@end
