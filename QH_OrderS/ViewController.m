//
//  ViewController.m
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <SSZipArchive.h>
#import "Tools.h"

@interface ViewController ()<UIGestureRecognizerDelegate, UIWebViewDelegate>

@property (strong, nonatomic) AppDelegate *app;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addWebView];
}

#pragma mark GET方法
- (void)addWebView {
    
    if(_webView == nil) {
        
        _webView = [[UIWebView alloc] init];
        [_webView setFrame:CGRectMake(0, kStatusHeight, ScreenWidth, ScreenHeight - kStatusHeight - SafeAreaBottomHeight)];
        _webView.delegate = self;
        [self.view addSubview:_webView];
        
        // 初始化信息
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // 长按5秒，开启webview编辑模式
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        longPress.minimumPressDuration = 3;
        [_webView addGestureRecognizer:longPress];
        
        NSString *unzipPath = [Tools getUnzipPath];
        NSLog(@"unzipPath:%@", unzipPath);
        
        NSString *checkFilePath = [unzipPath  stringByAppendingPathComponent:@"dist/index.html"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:checkFilePath] && [[Tools getLastVersion] isEqualToString:[Tools getCFBundleShortVersionString]]) {
            
            NSLog(@"HTML已存在，无需解压");
        } else {
            
            NSLog(@"第一次加载，或版本有更新，解压");
            NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
            NSLog(@"zipPath:%@", zipPath);
            [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
        }
        [Tools setLastVersion];
        
        // 加载URL
        NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
        NSURL *url = [[NSURL alloc] initWithString:filePath];
        
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
        // 禁用弹簧效果
        for (id subview in _webView.subviews){
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
            }
        }
        // 取消右侧，下侧滚动条，去处上下滚动边界的黑色背景
        for (UIView *_aView in [_webView subviews]) {
            if ([_aView isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)_aView setShowsVerticalScrollIndicator:NO];
                // 右侧的滚动条
                [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
                // 下侧的滚动条
                for (UIView *_inScrollview in _aView.subviews) {
                    if ([_inScrollview isKindOfClass:[UIImageView class]]) {
                        _inScrollview.hidden = YES;  // 上下滚动出边界时的黑色的图片
                    }
                }
            }
        }
    }
}

@end
