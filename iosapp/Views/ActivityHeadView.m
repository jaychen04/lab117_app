//
//  ActivityHeadView.m
//  iosapp
//
//  Created by 李萍 on 16/5/30.
//  Copyright © 2016年 oschina. All rights reserved.
//

#import "ActivityHeadView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+LBBlurredImage.h"
#import "Utils.h"

@interface ActivityHeadView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageCtl;

@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, assign) NSInteger currentIndex;
@property NSTimer *timer;

@end

@implementation ActivityHeadView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _currentIndex = 0;
    }
    return self;
}

- (void)setUpScrollView:(NSMutableArray *)bannners
{
    _banners = bannners;
    
    NSInteger arrayCount = bannners.count;
    _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * arrayCount, CGRectGetHeight(self.frame));
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor blackColor];
    [self addSubview:_scrollView];
    
    _pageCtl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame)-27, CGRectGetWidth(self.frame), 27)];
    _pageCtl.backgroundColor = [UIColor clearColor];
    _pageCtl.currentPage = 0;
    _pageCtl.numberOfPages = arrayCount;
    _pageCtl.currentPageIndicatorTintColor = [UIColor newSectionButtonSelectedColor];
    _pageCtl.pageIndicatorTintColor = [UIColor whiteColor];
    [self addSubview:_pageCtl];
    
    CGFloat imageViewWidth = CGRectGetWidth(_scrollView.frame);
    CGFloat imageViewHeight = CGRectGetHeight(_scrollView.frame);
    
    for (int i = 0; i < arrayCount; i++) {
        BottomImageView *view = [[BottomImageView alloc] initWithFrame:CGRectMake(imageViewWidth * i, 0, imageViewWidth, imageViewHeight)];
        view.tag = i+1;
        [_scrollView addSubview:view];
        OSCBanner *banner  = bannners[i];
        [view setContentForTopImages:banner];
        
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTopImage:)]];
    }
    if (arrayCount > 1) {
        if(!self.timer) {
            self.timer = [NSTimer timerWithTimeInterval:4.0f target:self selector:@selector(scrollToNextPage:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
            [self.timer fire];
        }
    }
}

- (void)setBanners:(NSMutableArray *)banners
{
    [self setUpScrollView:banners];
}

#pragma mark - 自动滚动
- (void)scrollToNextPage:(NSTimer *)timer
{
    _currentIndex++;
    if (_currentIndex >= _banners.count) {
        _currentIndex = 0;
    }
    _pageCtl.currentPage = _currentIndex;
    [_scrollView setContentOffset:CGPointMake(_currentIndex*CGRectGetWidth(_scrollView.frame), 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _currentIndex = scrollView.contentOffset.x/CGRectGetWidth(self.frame);
    _pageCtl.currentPage = _currentIndex;
}

#pragma mark - /*点击滚动图片*/
- (void)clickTopImage:(UITapGestureRecognizer *)tap
{
    [delegate clickScrollViewBanner:tap.view.tag-1];
}

#pragma mark - 代理方法

- (void)clickScrollViewBanner:(NSInteger)bannerTag
{
    [delegate clickScrollViewBanner:bannerTag];
}

@end

//带背景图片的UIImageView
@implementation BottomImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI:frame];
    }
    return self;
}

- (void)setUpUI:(CGRect)frame
{
    _bottomImage = [[UIImageView alloc] initWithFrame:frame];
    _bottomImage.contentMode = UIViewContentModeScaleAspectFill;
    _bottomImage.backgroundColor = [UIColor lightGrayColor];
    _bottomImage.clipsToBounds = YES;
    [self addSubview:_bottomImage];
   
    _subImageView = [[UIImageView alloc] init];
    [_bottomImage addSubview:_subImageView];
    
    _titleLable = [[UILabel alloc] init];
    _titleLable.font = [UIFont systemFontOfSize:18];
    _titleLable.numberOfLines = 0;
    _titleLable.lineBreakMode = NSLineBreakByWordWrapping;
    _titleLable.textColor = [UIColor colorWithHex:0xffffff];
    [_bottomImage addSubview:_titleLable];
    
    _descLable = [[UILabel alloc] init];
    _descLable.font = [UIFont systemFontOfSize:14];
    _descLable.numberOfLines = 0;
    _descLable.lineBreakMode = NSLineBreakByWordWrapping;
    _descLable.textColor = [UIColor colorWithHex:0xffffff];
    [_bottomImage addSubview:_descLable];
    
    [self setLayout];
}

- (void)setLayout
{
    for (UIView *view in self.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *views = NSDictionaryOfVariableBindings(_bottomImage);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_bottomImage]|"
                                                                             options:0
                                                                             metrics:nil views:views]];
    
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_bottomImage]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    
    
    for (UIView *view in _bottomImage.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *subViews = NSDictionaryOfVariableBindings(_subImageView, _titleLable, _descLable);
    
    [_bottomImage addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_subImageView(180)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:subViews]];
    [_bottomImage addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_titleLable]-16-[_descLable]-27-|"
                                                                 options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                 metrics:nil
                                                                   views:subViews]];
    [_bottomImage addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-16-[_subImageView(120)]-16-[_titleLable]-16-|"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:nil
                                                                   views:subViews]];
}

- (void)setContentForTopImages:(OSCBanner *)banner
{
    [_subImageView loadPortrait:[NSURL URLWithString:banner.img]];
    [_bottomImage setImageToBlur:_subImageView.image blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:^{
        
    }];
    _titleLable.text = banner.name;
    _descLable.text = banner.detail;
}


@end
