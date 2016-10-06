//
//  HomeButtonCell.h
//  iosapp
//
//  Created by 李萍 on 16/7/13.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeButtonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *creditButton;
@property (nonatomic, weak) IBOutlet UIButton *collectionButton;
@property (nonatomic, weak) IBOutlet UIButton *followingButton;
@property (nonatomic, weak) IBOutlet UIButton *fanButton;

@property (nonatomic, weak) IBOutlet UIButton *creditTitleButton;
@property (nonatomic, weak) IBOutlet UIButton *collectionTitleButton;
@property (nonatomic, weak) IBOutlet UIButton *followingTitleButton;
@property (nonatomic, weak) IBOutlet UIButton *fanTitleButton;
@property (weak, nonatomic) IBOutlet UIView *redPointView;

@end
