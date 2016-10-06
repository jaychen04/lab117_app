//
//  HomePageHeadView.m
//  iosapp
//
//  Created by 李萍 on 16/8/16.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "HomePageHeadView.h"
#import "Utils.h"
#import "OSCUser.h"
#import "AppDelegate.h"


#import <Masonry.h>

#define screen_width [UIScreen mainScreen].bounds.size.width
#define screen_half_width [UIScreen mainScreen].bounds.size.width * 0.5

#define userPortrait_width 80
#define genderImageView_width 20
#define bottomButton_height 60
#define bottom_subButton_height 30
#define setupButton_width 24

#define view_userPortrait 63

@implementation HomePageHeadView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setLayout];
    }
    return self;
}

- (void)setLayout
{
    CGFloat viewHeight = CGRectGetHeight(self.frame);
    
    QuartzCanvasView* drawView = [[QuartzCanvasView alloc]initWithFrame:(CGRect){{0,0},self.bounds.size}];
    _drawView = drawView;
    _drawView.minimumRoundRadius = userPortrait_width * 0.5 + 30;
    _drawView.openRandomness = NO;
    _drawView.duration = 25;
    _drawView.bgColor = [UIColor colorWithHex:0x24CF5F];
    _drawView.strokeColor = [UIColor colorWithHex:0x6FDB94];
    _drawView.offestCenter = (OffestCenter){0, view_userPortrait + userPortrait_width * 0.5 - viewHeight * 0.5};
    [self addSubview:_drawView];
    
    _setUpButton = [UIButton new];
    [_setUpButton setImage:[UIImage imageNamed:@"btn_my_setting"] forState:UIControlStateNormal];
    [self addSubview:_setUpButton];
    
    _codeButton = [UIButton new];
    [_codeButton setImage:[UIImage imageNamed:@"btn_qrcode"] forState:UIControlStateNormal];
    [self addSubview:_codeButton];
    
    _userPortrait = [UIImageView new];
    _userPortrait.backgroundColor = [UIColor redColor];
    _userPortrait.contentMode = UIViewContentModeScaleAspectFit;
    [_userPortrait setCornerRadius:userPortrait_width * 0.5];
    _userPortrait.userInteractionEnabled = YES;
    [self addSubview:_userPortrait];
    
    _genderImageView = [UIImageView new];
    _genderImageView.contentMode = UIViewContentModeScaleAspectFit;
    _genderImageView.hidden = YES;
    [self addSubview:_genderImageView];
    
    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont systemFontOfSize:20];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.numberOfLines = 1;
    _nameLabel.textColor = [UIColor colorWithHex:0xFFFFFF];
    [self addSubview:_nameLabel];
    
    _descLable = [UILabel new];
    _descLable.font = [UIFont systemFontOfSize:13];
    _descLable.textAlignment = NSTextAlignmentCenter;
    _descLable.numberOfLines = 3;
    _descLable.lineBreakMode = NSLineBreakByWordWrapping;
    _descLable.textColor = [UIColor colorWithHex:0xFFFFFF];
    [self addSubview:_descLable];
    _descLable.text = @"该用户还没有填写描述...";
    
    _creditLabel = [UILabel new];
    _creditLabel.font = [UIFont systemFontOfSize:13];
    _creditLabel.textAlignment = NSTextAlignmentCenter;
    _creditLabel.numberOfLines = 1;
    _creditLabel.textColor = [UIColor colorWithHex:0xFFFFFF];
    _creditLabel.text = @"积分：0";
    [self addSubview:_creditLabel];
    
    [self sendSubviewToBack:_drawView];
    
    [_setUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(16);
        make.top.equalTo(self.mas_top).with.offset(16);
        make.width.and.height.equalTo(@setupButton_width);
    }];
    
    [_codeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mas_right).with.offset(-16);
        make.top.equalTo(self.mas_top).with.offset(16);
        make.width.and.height.equalTo(@setupButton_width);
    }];
    
    [_userPortrait mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(screen_half_width-(userPortrait_width * 0.5));
        make.top.equalTo(self).with.offset(view_userPortrait);
        make.width.and.height.equalTo(@userPortrait_width);
    }];
    
    [_genderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.and.bottom.equalTo(self.userPortrait).with.offset(0);
        make.width.and.height.equalTo(@genderImageView_width);
    }];
    
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(32);
        make.right.equalTo(self).with.offset(-32);
        make.top.equalTo(self.userPortrait.mas_bottom).with.offset(8);
    }];
    
    [_descLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(32);
        make.right.equalTo(self).with.offset(-32);
        make.top.equalTo(self.nameLabel.mas_bottom).with.offset(7);
    }];
    
    [_creditLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(32);
        make.right.equalTo(self).with.offset(-32);
        make.top.equalTo(self.descLable.mas_bottom).with.offset(15);
    }];
    
}

@end
