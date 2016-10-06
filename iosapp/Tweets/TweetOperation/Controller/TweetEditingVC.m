//
//  TweetEditingVC.m
//  iosapp
//
//  Created by ChanAetern on 12/18/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "TweetEditingVC.h"
#import "EmojiPageVC.h"
#import "OSCAPI.h"
#import "TeamAPI.h"
#import "Config.h"
#import "Utils.h"
#import "PlaceholderTextView.h"
#import "LoginViewController.h"
#import "ImageViewerController.h"
#import "AppDelegate.h"
#import "TeamMemberListViewController.h"
#import "Config.h"
#import "OSCPhotoGroupView.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>
#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MBProgressHUD.h>
#import <ReactiveCocoa.h>
#import "TweetFriendsListViewController.h"
#import <Masonry.h>

//#import<ELCImagePickerController.h>
#import"ELCImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define maxStrLength 160

@interface TweetEditingVC () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIScrollViewDelegate,ELCImagePickerControllerDelegate>

@property (nonatomic, strong) UIScrollView          *scrollView;
@property (nonatomic, strong) UIView                *contentView;
@property (nonatomic, strong) PlaceholderTextView   *edittingArea;
@property (nonatomic, strong) UIToolbar             *toolBar;
@property (nonatomic, strong) NSLayoutConstraint    *keyboardHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint    *textViewHeightConstraint;
@property (nonatomic, strong) EmojiPageVC           *emojiPageVC;
@property (nonatomic, assign) BOOL                  isEmojiPageOnScreen;

@property (nonatomic, strong) UIImage               *image;
@property (nonatomic, strong) NSString              *topicName;
@property (nonatomic, assign) int                   teamID;
@property (nonatomic)         BOOL                  isTeamTweet;

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, copy) NSString *imageToken;
@property (nonatomic) NSInteger imageIndex;
@property (nonatomic) NSInteger failCount;
@property (nonatomic) BOOL isGotTweetAddImage;      //是否已有➕图片在images数组里
@property (nonatomic) BOOL isAddImage;          //是否是添加图片模式（点击➕图片添加）
@property (nonatomic, strong) MBProgressHUD *uploadImgHub;
@end

@implementation TweetEditingVC{
    NSMutableArray* _itemImageArr;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _isTeamTweet = NO;
        _images = [NSMutableArray new];
        _imageToken = @"";
        _imageIndex = 0;
        _failCount = 0;
        _isGotTweetAddImage = NO;
        _isAddImage = NO;
        _itemImageArr = [NSMutableArray arrayWithCapacity:9];
    }
    return self;
}

//多图
- (instancetype)initWithImages:(NSMutableArray *)images
{
    self = [super init];
    if (self) {

        _images = images;
        _imageToken = @"";
        _imageIndex = 0;
        _failCount = 0;
        _isGotTweetAddImage = NO;
        _isAddImage = NO;
    }
    
    return self;
}


- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = image;
    }
    
    return self;
}

- (instancetype)initWithTopic:(NSString *)topic
{
    self = [super init];
    if (self) {
        _topicName = topic;
    }
    
    return self;
}

- (instancetype)initWithTeamID:(int)teamID
{
    self = [super init];
    if (self) {
        _teamID = teamID;
        _isTeamTweet = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"弹一弹";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelButtonClicked)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(pubTweet)];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initSubViews];
    
    [self setUpLayoutIsRepeat:NO];
    
    if (!_edittingArea.text.length) {
        _edittingArea.text = [Config getTweetText];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_edittingArea.delegate textViewDidChange:_edittingArea];
    
    [_edittingArea becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)initSubViews
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.scrollEnabled = YES;
    _scrollView.bounces = YES;
    [self.view addSubview:_scrollView];
    
    _contentView = [[UIView alloc] initWithFrame:_scrollView.bounds];
    _contentView.userInteractionEnabled = YES;
    [_scrollView addSubview:_contentView];
    _scrollView.contentSize = _contentView.bounds.size;
    
    _edittingArea = [PlaceholderTextView new];
    _edittingArea.placeholder = @"今天你动弹了吗？";
    _edittingArea.delegate = self;
    if (_topicName.length) {
        _edittingArea.text = [NSString stringWithFormat:@"#%@#", _topicName];
    }
    _edittingArea.returnKeyType = UIReturnKeySend;
    _edittingArea.enablesReturnKeyAutomatically = YES;
    _edittingArea.scrollEnabled = NO;
    _edittingArea.font = [UIFont systemFontOfSize:16];
    _edittingArea.autocorrectionType = UITextAutocorrectionTypeNo;
    [_contentView addSubview:_edittingArea];
    
    if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode) {
        _edittingArea.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    
    _edittingArea.backgroundColor = [UIColor whiteColor];
    _edittingArea.textColor = [UIColor titleColor];
    
    _emojiPageVC = [[EmojiPageVC alloc] initWithTextView:_edittingArea];
    _emojiPageVC.view.hidden = YES;
    _emojiPageVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_emojiPageVC.view];
    
    
    /****** toolBar ******/
    
    _toolBar = [UIToolbar new];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpace.width = 25.0f;
    NSMutableArray *barButtonItems = [[NSMutableArray alloc] initWithObjects:fixedSpace, nil];
    NSArray *iconName = @[@"toolbar-image", @"toolbar-mention", @"toolbar-reference", @"toolbar-emoji"];
    NSArray *action   = @[@"addImage", @"mentionSomenone", @"referSoftware", @"switchInputView"];
    for (int i = 0; i < 4; i++) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:iconName[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:NSSelectorFromString(action[i])];
        //button.tintColor = [UIColor grayColor];
        if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode) {
            _toolBar.barTintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            button.tintColor = [UIColor clearColor];
        } else {
            _toolBar.barTintColor = [UIColor colorWithRed:246.0/255 green:246.0/255 blue:246.0/255 alpha:1.0];
            button.tintColor = [UIColor clearColor];
        }
        [barButtonItems addObject:button];
        if (i < 3) {[barButtonItems addObject:flexibleSpace];}
    }
    [barButtonItems addObject:fixedSpace];
    [_toolBar setItems:barButtonItems];
    
    // 底部添加border
    
    UIView *bottomBorder = [UIView new];
    bottomBorder.backgroundColor = [UIColor borderColor];
    bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
    [_toolBar addSubview:bottomBorder];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(bottomBorder);
    
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[bottomBorder]|" options:0 metrics:nil views:views]];
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomBorder(0.5)]|" options:0 metrics:nil views:views]];
    
    [self.view addSubview:_toolBar];
    
    _toolBar.backgroundColor = [UIColor themeColor];
}

#pragma mark -- 多图模式删除图片
- (void)deleteMutilImage:(UITapGestureRecognizer*)tap {
    NSInteger deleteImgIndex = tap.view.tag;
    [self.images removeObjectAtIndex:deleteImgIndex];
    if (_isGotTweetAddImage && _images.count == 1) {
        [_images removeAllObjects];
    }
    for (UIView *subView in _contentView.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            [subView removeFromSuperview];
        }
    }
    [self setUpLayoutIsRepeat:YES];
}
#pragma mark -- 多图模式布局
- (void)setUpLayoutIsRepeat:(BOOL)isRepeat {
    CGFloat edittingAreaHeight = (359*190)/(CGRectGetWidth(self.view.frame)-16);
    [_edittingArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-8);
        make.top.equalTo(_contentView);
        make.height.mas_equalTo(edittingAreaHeight);
    }];

    if (_images.count > 0 && _images.count < 9 && !_isGotTweetAddImage) {
        _isGotTweetAddImage = YES;
        [_images insertObject:[UIImage imageNamed:@"ic_tweet_add"] atIndex:_images.count];
    }
    
    [_itemImageArr removeAllObjects];
    for (int k=0; k<_images.count; k++) {
        UIImageView *iv = [UIImageView new];
        iv.tag = k;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.userInteractionEnabled = YES;
        UIImage* image = [_images objectAtIndex:k];
        iv.image = image;
        [iv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMutilImagePreview:)]];
        [_contentView addSubview:iv];
        
        NSData* imageData = UIImagePNGRepresentation(image);
        NSString* imageStr = [[NSString alloc]initWithData:imageData encoding:NSUTF8StringEncoding];
        NSURL* imageUrl = [NSURL URLWithString:imageStr];
        
        OSCPhotoGroupItem* imageItem = [OSCPhotoGroupItem new];
        imageItem.largeImageURL = imageUrl;
        imageItem.largeImageSize = [UIScreen mainScreen].bounds.size;
        imageItem.thumbView = iv;
        [_itemImageArr addObject:imageItem];
        
        CGFloat ivWidth = CGRectGetWidth([[UIScreen mainScreen]bounds])/3 - 12;
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_edittingArea.mas_left).offset(k%3*(ivWidth+8));
            make.top.equalTo(_edittingArea.mas_bottom).offset(k/3*(ivWidth+8)+8);
            make.width.and.height.mas_equalTo(ivWidth);
        }];
        
        if ((_images.count == 9 && !_isGotTweetAddImage) || k+1 < _images.count) {
            UILabel *deleteLabel = [UILabel new];
            deleteLabel.tag = k;
            deleteLabel.userInteractionEnabled = YES;
            deleteLabel.text = @"✕";
            deleteLabel.textColor = [UIColor whiteColor];
            deleteLabel.backgroundColor = [UIColor colorWithHex:0xe35050];
            deleteLabel.textAlignment = NSTextAlignmentCenter;
            [deleteLabel setCornerRadius:9];
            [deleteLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteMutilImage:)]];
            [iv addSubview:deleteLabel];
            
            [deleteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(iv.mas_right);
                make.top.equalTo(iv.mas_top);
                make.width.mas_equalTo(19);
                make.height.mas_equalTo(18);
            }];
        }
        
    }
    [_itemImageArr removeLastObject];
    
    if (!isRepeat) {

        /*** toolBar ***/
        [_toolBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.view);
        }];
        _keyboardHeightConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                    toItem:_toolBar  attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraint:_keyboardHeightConstraint];
        
        /*** emojiPage ***/
        NSDictionary *view = @{@"emojiPage": _emojiPageVC.view};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emojiPage(216)]|" options:0 metrics:nil views:view]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[emojiPage]|" options:0 metrics:nil views:view]];
    }
}
#pragma mark --- 预览大图
- (void)showMutilImagePreview:(UITapGestureRecognizer*)tap {
    NSInteger imageIndex = tap.view.tag;
    if (imageIndex < _images.count - 1) {
        [_edittingArea resignFirstResponder];
        UIImageView* fromView = (UIImageView* )tap.view;
        
        OSCPhotoGroupView* photoGroup = [[OSCPhotoGroupView alloc] initWithGroupItems:_itemImageArr.copy];
        
        UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
        [photoGroup presentFromImageView:fromView toContainer:keyWindow animated:YES completion:nil];
        photoGroup.isShowDownloadButton = NO;
        
    }else if (imageIndex == _images.count - 1) {
        if (_isGotTweetAddImage) {  //在原来基础上添加图片
            _isAddImage = YES;
            ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
            elcPicker.maximumImagesCount = 10 - _images.count;
            elcPicker.imagePickerDelegate = self;
            [self presentViewController:elcPicker animated:YES completion:nil];
        }else {
            [self.navigationController presentViewController:[[ImageViewerController alloc] initWithImage:[_images objectAtIndex:imageIndex]] animated:YES completion:nil];
        }
    }
}

- (void)cancelButtonClicked
{
    if (_edittingArea.text.length > 0) {
        NSString *alertString = _teamID? @"是否取消编辑动弹" : @"是否保存已编辑的信息";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertString message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        [alertView show];
    } else {
        [Config saveTweetText:@"" forUser:[Config getOwnID]];
        [_edittingArea resignFirstResponder];
        
        if (_teamID) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_teamID) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
    } else {
        [Config saveTweetText:buttonIndex == alertView.cancelButtonIndex? @"" : _edittingArea.text
                      forUser:[Config getOwnID]];
    }
    [_edittingArea resignFirstResponder];
    
    if (_teamID) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - ToolBar 高度相关

- (void)keyboardWillShow:(NSNotification *)notification {
    _emojiPageVC.view.hidden = YES;
    _isEmojiPageOnScreen = NO;
    
    CGRect keyboardBounds = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardHeightConstraint.constant = keyboardBounds.size.height;
    
    [self updateBarHeight];
}


- (void)keyboardWillHide:(NSNotification *)notification {
    _keyboardHeightConstraint.constant = 0;
    
    [self updateBarHeight];
}
#pragma mark 表情面板与键盘切换

- (void)switchInputView {
    // 还要考虑一下用外接键盘输入时，置空inputView后，字体小的情况
    if (_isEmojiPageOnScreen) {
        [_edittingArea becomeFirstResponder];
        
        [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-emoji"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        _edittingArea.font = [UIFont systemFontOfSize:16];
        _isEmojiPageOnScreen = NO;
        _emojiPageVC.view.hidden = YES;
    } else {
        [_edittingArea resignFirstResponder];
        
        [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-text"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        _keyboardHeightConstraint.constant = 216;
        [self updateBarHeight];
        _isEmojiPageOnScreen = YES;
        _emojiPageVC.view.hidden = NO;
    }
}


- (void)updateBarHeight {
    [self.view setNeedsUpdateConstraints];
    [UIView animateKeyframesWithDuration:0.25       //animationDuration
                                   delay:0
                                 options:7 << 16    //animationOptions
                              animations:^{
                                  [self.view layoutIfNeeded];
                              } completion:nil];
}



#pragma mark - ToolBar 操作

#pragma mark 图片相关

- (void)addImage {
    [self.edittingArea resignFirstResponder]; //键盘遮盖了actionsheet
    
    [[[UIActionSheet alloc] initWithTitle:@"添加图片"
                                 delegate:self
                        cancelButtonTitle:@"取消"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@"相册", @"相机", nil]
     
     showInView:self.view];
}




#pragma mark 插入字符串操作（@人，引用软件或发表话题）

- (void)mentionSomenone
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    if (_teamID) {
        [self.navigationController pushViewController:[TeamMemberListViewController new]
                                             animated:YES];
    }else {
        TweetFriendsListViewController * vc = [TweetFriendsListViewController new];
        [vc setSelectDone:^(NSString *result) {
            [self insertString:result andSelect:NO];
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)referSoftware
{
    [self insertString:@"#请输入软件名#" andSelect:YES];
}

- (void)insertString:(NSString *)string andSelect:(BOOL)shouldSelect
{
    [_edittingArea becomeFirstResponder];
    
    NSUInteger cursorLocation = _edittingArea.selectedRange.location;
    [_edittingArea replaceRange:_edittingArea.selectedTextRange withText:string];
    
    if (shouldSelect) {
        UITextPosition *selectedStartPos = [_edittingArea positionFromPosition:_edittingArea.beginningOfDocument offset:cursorLocation + 1];
        UITextPosition *selectedEndPos   = [_edittingArea positionFromPosition:_edittingArea.beginningOfDocument offset:cursorLocation + string.length - 1];
        
        UITextRange *newRange = [_edittingArea textRangeFromPosition:selectedStartPos toPosition:selectedEndPos];
        
        [_edittingArea setSelectedTextRange:newRange];
    }
}

#pragma mark -- 上传动弹多图
- (void)uploadTweetImages {
    [_edittingArea resignFirstResponder];
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    if (_imageIndex == 0) {
        _uploadImgHub = [Utils createHUD];
        _uploadImgHub.label.text = @"动弹发送中";
        _uploadImgHub.removeFromSuperViewOnHide = NO;
    }
    if (_uploadImgHub) {
        [_uploadImgHub showAnimated:YES];
    }
    self.navigationItem.rightBarButtonItem.accessibilityElementsHidden = YES;
    UIImage *postImage = [_images objectAtIndex:_imageIndex];
    NSString *urlStr = [NSString stringWithFormat:@"%@resource_image", OSCAPI_V2_PREFIX ];
    NSDictionary *paramDic = @{@"token":_imageToken};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCJsonManager];
    
    [manager POST:urlStr
       parameters:paramDic
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if (postImage) {
            [formData appendPartWithFileData:[Utils compressImage:postImage]
                                        name:@"resource"
                                    fileName:@"img.png"
                                    mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"message:%@",responseObject[@"message"]);
        _uploadImgHub = [Utils createHUD];
        _uploadImgHub.label.text = @"动弹发送中";
        
        if ([responseObject[@"code"]integerValue] == 1) {
            _imageIndex += 1;
            _imageToken = responseObject[@"result"][@"token"];
            if (_imageIndex < _images.count) {
            [self uploadTweetImages];
            }else if (_imageIndex == _images.count) {
                [self pubTweetIsWithImages:YES];
            }
        }else {
            _failCount += 1;
            _imageIndex += 1;
            if (_imageIndex < _images.count) {
                [self uploadTweetImages];
            }else if (_imageIndex == _images.count) {
                [self pubTweetIsWithImages:YES];
            }
        }
    
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        _imageIndex = 0;
        _failCount = 0;
        _imageToken = @"";
        _uploadImgHub.mode = MBProgressHUDModeCustomView;
         _uploadImgHub.label.text = @"请求超时，请重新发送";
        [_uploadImgHub hideAnimated:YES afterDelay:1];
    }];
}

#pragma mark -- 发表多图动弹
- (void)pubTweetIsWithImages:(BOOL)isImgTweet {
//    9752556
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
	
	MBProgressHUD *HUD;
	NSString *txtContent = [_edittingArea.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if([txtContent isEqualToString:@"#请输入软件名#"]) {
		
	} else {
		if (!isImgTweet) {
			HUD = [Utils createHUD];
			HUD.label.text = @"动弹发送中";
			HUD.removeFromSuperViewOnHide = NO;
		}
		NSString *urlStr = [NSString stringWithFormat:@"%@tweet", OSCAPI_V2_PREFIX];
		NSDictionary *paramDic = @{
								   @"content":[Utils convertRichTextToRawText:_edittingArea],
								   @"images":_imageToken
								   };
		AFHTTPRequestOperationManager* manger = [AFHTTPRequestOperationManager OSCJsonManager];
		[manger POST:urlStr
		  parameters:paramDic
			 success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
				 NSLog(@"tweetMessage:%@",responseObject[@"message"]);
				 
				 if ([responseObject[@"code"]integerValue] == 1) {
					 //提示上传图片失败信息
					 if (isImgTweet) {       //图片动弹
						 _uploadImgHub.mode = MBProgressHUDModeCustomView;
						 if (_failCount > 0) {
							 _uploadImgHub.label.text = [NSString stringWithFormat:@"%ld张图片上传失败", (long)_failCount];
						 }else {
							 _uploadImgHub.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
							 _uploadImgHub.label.text = @"动弹发送成功";
						 }
					 }else {     //文字动弹
						 HUD.mode = MBProgressHUDModeCustomView;
						 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
						 HUD.label.text = @"动弹发送成功";
					 }
				 }else {
					 if (isImgTweet) {
						 _uploadImgHub.label.text = responseObject[@"message"];
					 }else {
						 HUD.label.text = responseObject[@"message"];
					 }
				 }
				 dispatch_async(dispatch_get_main_queue(), ^{
					 UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
					 [MBProgressHUD hideAllHUDsForView:window animated:YES];
					 [_uploadImgHub hideAnimated:YES afterDelay:1];
					 [HUD hideAnimated:YES afterDelay:1];
					 [self dismissViewControllerAnimated:YES completion:nil];
				 });
			 }
			 failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
				 NSLog(@"%@",error);
			 }];
	}
}

#pragma mark 发表动弹

- (void)pubTweet {
    if (!_isTeamTweet) {
        if (_images.count > 0) {    //发布图片动弹
            if(_isGotTweetAddImage) {       //移除最后一张提示图片
                [_images removeLastObject];
            }
            [self uploadTweetImages];
        }else {    //发布文字动弹
            [self pubTweetIsWithImages:NO];
        }
		
    }else {     //团队动弹
        [self pubTeamTweet];
    }
	
}


#pragma mark -- 发表团队动弹
- (void)pubTeamTweet {
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    self.navigationItem.rightBarButtonItem.accessibilityElementsHidden = YES;
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.label.text = @"动弹发送中";
    HUD.removeFromSuperViewOnHide = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
        
        NSString *API = _teamID? TEAM_TWEET_PUB : OSCAPI_TWEET_PUB;
        [manager             POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, API]
                       parameters:@{
                                    @"uid": @([Config getOwnID]),
                                    @"msg": [Utils convertRichTextToRawText:_edittingArea],
                                    @"teamid": @(_teamID)
                                    }
         
        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        }
         
                          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
                              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
                              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
                              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
                              
                              HUD.mode = MBProgressHUDModeCustomView;
                              [HUD showAnimated:YES];
                              
                              if (errorCode == 1) {
                                  _edittingArea.text = @"";
                                  
                                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                                  HUD.label.text = @"动弹发表成功";
                                  
                                  [Config saveTweetText:@"" forUser:[Config getOwnID]];
                              } else {
                                  HUD.label.text = [NSString stringWithFormat:@"错误：%@", errorMessage];
                                  
                                  [Config saveTweetText:_edittingArea.text forUser:[Config getOwnID]];
                              }
                              
                              HUD.removeFromSuperViewOnHide = YES;
                              [HUD hideAnimated:YES afterDelay:1];
                              
                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              HUD.mode = MBProgressHUDModeCustomView;
                              HUD.label.text = @"网络异常，动弹发送失败";
                              HUD.removeFromSuperViewOnHide = YES;
                              [HUD hideAnimated:YES afterDelay:1];
                              
                              [Config saveTweetText:_edittingArea.text forUser:[Config getOwnID]];
                          }];
    });
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    } else if (buttonIndex == 0) {
        
        _isAddImage = NO;
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
        elcPicker.maximumImagesCount = 9;
        elcPicker.imagePickerDelegate = self;
        [self presentViewController:elcPicker animated:YES completion:nil];
        
    } else {
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Device has no camera"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
            
            [alertView show];
        } else {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            imagePickerController.delegate = self;
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePickerController.allowsEditing = NO;
            imagePickerController.showsCameraControls = YES;
            imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }
}



#pragma mark ELCImagePickerControllerDelegate Methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {

    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[info count]];
    for (NSDictionary *dict in info) {
        if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypePhoto){
            if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
                UIImage* image=[dict objectForKey:UIImagePickerControllerOriginalImage];
                [images addObject:image];
            } else {
                NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
            }
        } else if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypeVideo){
            if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
                
            } else {
                NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
            }
        } else {
            NSLog(@"Uknown asset type");
        }
    }
    if (!_isAddImage) {
        [_images removeAllObjects];
    }else {
        [_images removeLastObject];
    }
    [_images addObjectsFromArray:images];
    _isGotTweetAddImage = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subView in _contentView.subviews) {
            if ([subView isKindOfClass:[UIImageView class]]) {
                [subView removeFromSuperview];
            }
        }
        [self setUpLayoutIsRepeat:YES];
        [picker dismissViewControllerAnimated:NO completion:nil];
    });
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerController 回调函数

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [_images addObject:info[UIImagePickerControllerOriginalImage]];
    _isGotTweetAddImage = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subView in _contentView.subviews) {
            if ([subView isKindOfClass:[UIImageView class]]) {
                [subView removeFromSuperview];
            }
        }
        [self setUpLayoutIsRepeat:YES];
        [picker dismissViewControllerAnimated:NO completion:nil];
    });
    
    //如果是拍照的照片，则需要手动保存到本地，系统不会自动保存拍照成功后的照片
    //UIImageWriteToSavedPhotosAlbum(edit, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    

}

- (NSUInteger) lenghtWithString:(NSString *)string
{
    NSUInteger len = string.length;
    // 汉字字符集
    NSString * pattern  = @"[\u4e00-\u9fa5]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    // 计算中文字符的个数
    NSInteger numMatch = [regex numberOfMatchesInString:string options:NSMatchingReportProgress range:NSMakeRange(0, len)];
    
    return len + numMatch;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    NSString *comcatstr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSInteger caninputlen = maxStrLength - comcatstr.length;
    if (caninputlen < 0) {
        NSInteger len = text.length + caninputlen;
        //防止当text.length + caninputlen < 0时，使得rg.length为一个非法最大正数出错
        NSRange rg = {0,MAX(len,0)};
        if (rg.length > 0) {
            NSString *s = [text substringWithRange:rg];
            [textView setText:[textView.text stringByReplacingCharactersInRange:range withString:s]];
        }
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.label.text = @"最多只能输入160字";
        HUD.removeFromSuperViewOnHide = NO;
        [HUD hideAnimated:YES afterDelay:1];
        _edittingArea.text = [_edittingArea.text substringToIndex:_edittingArea.text.length-1];
        return NO;
    }
    
    if ([text isEqualToString: @"\n"]) {
        [self pubTweet];
        [textView resignFirstResponder];
        return NO;
    }
    
    if (_teamID && [text isEqualToString: @"@"]) {
        [self mentionSomenone];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = [textView hasText];
}

- (void)textViewDidChange:(PlaceholderTextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = [textView hasText];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == _scrollView) {
        [_edittingArea resignFirstResponder];
        
        if (_keyboardHeightConstraint.constant != 0) {
            _emojiPageVC.view.hidden = YES;
            _isEmojiPageOnScreen = NO;
            [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-emoji"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            
            _keyboardHeightConstraint.constant = 0;
            [self updateBarHeight];
        }
    }
}



@end
