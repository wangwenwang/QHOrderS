//
//  AppDelegate.m
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ServiceTools.h"
#import <WXApi.h>
#import "Tools.h"
#import <SSZipArchive.h>
#import <LMProgressView.h>

@interface AppDelegate ()<ServiceToolsDelegate>

@property (nonatomic, strong)UIView *downView;

@property (nonatomic, strong)LMProgressView *progressView;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    ViewController *mainView = [[ViewController alloc] init];
    _window.rootViewController = mainView;
    [_window makeKeyAndVisible];
    
    // 注册微信凭证
    BOOL b = [WXApi registerApp:WXAPPID];
    
    if(b) { NSLog(@"微信注册成功");}
    else  { NSLog(@"微信注册失败");}
    
    // 检查HTML zip 是否有更新
    [self checkZipVersion];
    
    return YES;
}


- (void)checkZipVersion {
    
    NSString *currVersion = [Tools getZipVersion];
    if(currVersion == nil) {
        NSLog(@"初次检查zip版本，设置默认");
        [Tools setZipVersion:kUserDefaults_ZipVersion_local_defaultValue];
    }else{
        NSLog(@"本地zip版本：%@", currVersion);
    }
    
    ServiceTools *s = [[ServiceTools alloc] init];
    s.delegate = self;
    UIViewController *rootViewController = _window.rootViewController;
    if([rootViewController isKindOfClass:[ViewController class]]) {
        
        [s queryAppVersion];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}


- (void)applicationWillTerminate:(UIApplication *)application {
    
}


#pragma mark - ServiceToolsDelegate

// 开始下载zip
- (void)downloadStart {
    
    if(!_downView) {
        _downView = [[UIView alloc] init];
    }
    [_downView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [_downView setBackgroundColor:RGB(145, 201, 249)];
    [_window addSubview:_downView];
    
    _progressView = [[LMProgressView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_window.frame), CGRectGetHeight(_window.frame))];
    [_downView addSubview:_progressView];
}

// 下载zip进度
- (void)downloadProgress:(double)progress {
    
    WeakSelf;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.progressView.progress = progress;
    });
}

// 下载zip完成
- (void)downloadCompletion:(NSString *)version andFilePath:(NSString *)filePath {
    
    WeakSelf;
    
    NSLog(@"解压中...");
    NSString *unzipPath = [Tools getUnzipPath];
    BOOL unzip_b = [SSZipArchive unzipFileAtPath:filePath toDestination:unzipPath];
    if(unzip_b) {
        
        NSLog(@"解压完成，开始刷新APP内容...");
    }else {
        
        NSLog(@"解压失败");
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"延迟0.5秒");
        usleep(500000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIViewController *rootViewController = [Tools getRootViewController];
            if([rootViewController isKindOfClass:[ViewController class]]) {
                
                ViewController *vc = (ViewController *)rootViewController;
                [vc addWebView];
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                
                weakSelf.downView.alpha = 0.0f;
            }completion:^(BOOL finished){
                
                [weakSelf.downView removeFromSuperview];
                if(unzip_b) {
                    
                    [Tools setZipVersion:version];
                }else {
                    
                    NSLog(@"zip解压失败，不更新zip版本号");
                }
            }];
            NSLog(@"刷新内容完成");
        });
    });
}
              
@end
