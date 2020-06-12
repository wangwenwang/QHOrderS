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
#import <AFNetworking.h>
#import "NSString+toDict.h"
#import "NSDictionary+toString.h"
#import "IOSToVue.h"

// 推送
#import <GTSDK/GeTuiSdk.h>                          // GTSDK 头文件
#import <PushKit/PushKit.h>                         // VOIP支持需要导入PushKit库,实现 PKPushRegistryDelegate
#import <UserNotifications/UserNotifications.h>     // iOS10 通知头文件
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif
// GTSDK 配置信息
#define kGtAppId @"3XaObvshst7kndg9Sny0B9"
#define kGtAppKey @"Z4iGcM5qR07sixGQ6T3ZU3"
#define kGtAppSecret @"n59KfCTM428EqYL7RuN8Y4"

@interface AppDelegate ()<ServiceToolsDelegate, WXApiDelegate>

@property (strong, nonatomic) WKWebView *webView;

@property (nonatomic, strong)UIView *downView;

@property (nonatomic, strong)LMProgressView *progressView;

@property (nonatomic, strong)BMKMapManager *mapManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 接收webview
    [self addNotification];
    
    _mapManager = [[BMKMapManager alloc] init];
    // 如果要关注网络及授权验证事件，请设定generalDelegate参数
    BOOL ret = [_mapManager start:@"yIa27m9OpzEA0MMv7Eddl7aAUjcEGZPD"  generalDelegate:nil];
    if (!ret) {
        NSLog(@"百度地图加载失败！");
    }else {
        NSLog(@"百度地图加载成功！");
    }
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    ViewController *mainView = [[ViewController alloc] init];
    _window.rootViewController = mainView;
    [_window makeKeyAndVisible];
    
    // 注册微信凭证
    BOOL b = [WXApi registerApp:WXAPPID universalLink:@"https://tms.kaidongyuan.com"];
    
    if(b) { NSLog(@"微信注册成功");}
    else  { NSLog(@"微信注册失败");}
    
    // 检查HTML zip 是否有更新
    [self checkZipVersion];
    
    // [ GTSDK ]：使用APPID/APPKEY/APPSECRENT创建个推实例
    [GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret delegate:self];
    
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册远程通知
    [self registerRemoteNotification];
    
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册VOIP
    [self voipRegistration];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    return YES;
}


#pragma mark - 微信登录

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [WXApi handleOpenURL:url delegate:self];
}

// 授权回调的结果
- (void)onResp:(BaseResp *)resp {
    
    NSLog(@"resp:%d", resp.errCode);
    
    if([resp isKindOfClass:[SendAuthResp class]]) {
        
        SendAuthResp *rep = (SendAuthResp *)resp;
        if(resp.errCode == -2) {
            
            NSLog(@"用户取消");
        }else if(resp.errCode == -4) {
            
            NSLog(@"用户拒绝授权");
        }else {
            
            NSString *code = rep.code;
            NSString *appid = WXAPPID;
            NSString *appsecret = WXAPPSECRED;
            NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", appid, appsecret, code];
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                NSDictionary *result = [[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
                NSString *access_token = result[@"access_token"];
                NSString *openid = result[@"openid"];
                [self wxLogin:access_token andOpenid:openid];
                NSLog(@"请求access_token成功");
                [self bindingWX:openid];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                NSLog(@"请求access_token失败");
            }];
        }
    }
}


// 获取tms用户信息
- (void)bindingWX:(NSString *)openid {
    
    NSString *params = [NSString stringWithFormat:@"{\"wxOpenid\":\"%@\"}", openid];
    NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"%@login.do?params=%@", [Tools getServerAddress], paramsEncoding];
    NSLog(@"请求APP用户信息参数：%@",url);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSDictionary *result = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];

        int status = [result[@"status"] intValue];
        id data = result[@"data"];
        NSString *Msg = result[@"Msg"];

        if(status == 1) {

            NSString *params = [result toString];
            NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [IOSToVue TellVueWXBind_YES_Ajax:_webView andParamsEncoding:paramsEncoding];
            NSLog(@"请求APP用户信息成功");
        } else if(status == 3){

            if([data isKindOfClass:[NSString class]]) {

                [IOSToVue TellVueWXBind_NO_Ajax:_webView andOpenid:openid];
                NSLog(@"此微信未注册");
            }
        }else {

            NSLog(@"%@", Msg);
        }
        NSLog(@"%@", result);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"请求APP用户信息失败");
    }];
}


// 获取微信个人信息
- (void)wxLogin:(NSString *)access_token andOpenid:(NSString *)openid {
    
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", access_token, openid];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *result =[[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
        NSLog(@"请求个人信息成功");
        NSLog(@"%@", result);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"请求个人信息失败");
    }];
}


#pragma mark - 检查版本

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
        
        [s queryAppVersion:NO];
    }
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


#pragma mark - 通知

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWebView:) name:kReceive_WebView_Notification object:nil];
}


- (void)receiveWebView:(NSNotification *)aNotification {
    
    _webView = aNotification.userInfo[@"webView"];
}


#pragma mark - 用户通知(推送) _自定义方法

/**
 * [ 参考代码，开发者注意根据实际需求自行修改 ] 注册远程通知
 *
 * 警告：Xcode8及以上版本需要手动开启“TARGETS -> Capabilities -> Push Notifications”
 * 警告：该方法需要开发者自定义，以下代码根据APP支持的iOS系统不同，代码可以对应修改。以下为参考代码
 * 注意根据实际需要修改，注意测试支持的iOS系统都能获取到DeviceToken
 *
 */
- (void)registerRemoteNotification {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!error && granted) {
                NSLog(@"[ TestDemo ] iOS 10 request authorization succeeded!");
            }
        }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        return;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        return;
    }
}

#pragma mark - 远程通知(推送)回调

/// [ 系统回调 ] 远程通知注册成功回调，获取DeviceToken成功，同步给个推服务器
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // [ GTSDK ]：（新版）向个推服务器注册deviceToken
    [GeTuiSdk registerDeviceTokenData:deviceToken];
    
    // [ 测试代码 ] 日志打印DeviceToken
    NSLog(@"[ TestDemo ] [ DeviceToken(NSData) ]: %@\n", deviceToken);
}

/// [ 系统回调:可选 ] 远程通知注册失败回调，获取DeviceToken失败，打印错误信息
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    // [ 测试代码 ] 日志打印错误信息
    NSLog(@"[ TestDemo ] [DeviceToken Error]: %@\n", error.description);
}

#pragma mark - iOS 10中收到推送消息

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

/// [ 系统回调 ] iOS 10 通知方法: APNs通知将要显示时触发
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    // [ 测试代码 ] 日志打印APNs信息
    NSLog(@"[ TestDemo ] [APNs] %@：%@", NSStringFromSelector(_cmd), notification.request.content.userInfo);
    
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要，判断是否要提示用户Badge、Sound、Alert
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

/// [ 系统回调 ] iOS 10 通知方法: APNs点击通知时触发
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    
    // [ 测试代码 ] 日志打印APNs信息
    NSLog(@"[ TestDemo ] [APNs] %@ \nTime:%@ \n%@",
          NSStringFromSelector(_cmd),
          response.notification.date,
          response.notification.request.content.userInfo);
    
    // [ GTSDK ]：将收到的APNs信息传给个推统计
    [GeTuiSdk handleRemoteNotification:response.notification.request.content.userInfo];
    
    completionHandler();
}
#endif

#pragma mark - APP运行中接收到通知(推送)处理 - iOS 10以下版本收到推送

/// [ 系统回调 ] App收到远程通知
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    // [ 测试代码 ] 日志打印APNs信息
    NSLog(@"[ TestDemo ] [APNs] %@：%@", NSStringFromSelector(_cmd), userInfo);
    
    // [ GTSDK ]：将收到的APNs信息传给个推统计
    [GeTuiSdk handleRemoteNotification:userInfo];
    
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要自行修改参数值
    completionHandler(UIBackgroundFetchResultNewData);
}


#pragma mark - VOIP 接入

/**
 * [ 参考代码，开发者注意根据实际需求自行修改 ] 注册VOIP服务
 *
 * 警告：以下为参考代码, 注意根据实际需要修改.
 *
 */
- (void)voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

#pragma mark PKPushRegistryDelegate 协议方法

/// [ 系统回调 ] 系统返回VOIPToken，并提交个推服务器
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    // [ GTSDK ]：（新版）向个推服务器注册 VoipToken
    [GeTuiSdk registerVoipTokenCredentials:credentials.token];
    
    // [ 测试代码 ] 日志打印DeviceToken
    NSLog(@"[ TestDemo ] [ VoipToken(NSData) ]: %@\n\n", credentials.token);
}

/**
 * [ 系统回调 ] 收到voip推送信息
 * 接收VOIP推送中的payload进行业务逻辑处理（一般在这里调起本地通知实现连续响铃、接收视频呼叫请求等操作），并执行个推VOIP回执统计
 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    //  [ GTSDK ]：个推VOIP回执统计
    [GeTuiSdk handleVoipNotification:payload.dictionaryPayload];
    
    // [ 测试代码 ] 接受VOIP推送中的payload内容进行具体业务逻辑处理
    NSLog(@"[ TestDemo ] [ Voip Payload ]: %@, %@", payload, payload.dictionaryPayload);
}


#pragma mark - GeTuiSdkDelegate

/// [ GTSDK回调 ] SDK启动成功返回cid
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    // [ GTSDK ]：个推SDK已注册，返回clientId
    NSLog(@"[ TestDemo ] [GTSdk RegisterClient]:%@", clientId);
}

/// [ GTSDK回调 ] SDK收到透传消息回调
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId {
    // [ GTSDK ]：汇报个推自定义事件(反馈透传消息)
    [GeTuiSdk sendFeedbackMessage:90001 andTaskId:taskId andMsgId:msgId];
    
    // 数据转换
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [[NSString alloc] initWithBytes:payloadData.bytes length:payloadData.length encoding:NSUTF8StringEncoding];
    }
    
    // [ 测试代码 ] 控制台打印日志
    NSString *msg = [NSString stringWithFormat:@"taskId=%@,messageId:%@,payloadMsg:%@%@", taskId, msgId, payloadMsg, offLine ? @"<离线消息>" : @""];
    NSLog(@"[ TestDemo ] [GTSdk ReceivePayload]:%@\n\n", msg);
}

/// [ GTSDK回调 ] SDK收到sendMessage消息回调
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(int)result {
    // [ 测试代码 ] 控制台打印日志
    NSString *msg = [NSString stringWithFormat:@"sendmessage=%@,result=%d", messageId, result];
    NSLog(@"[ TestDemo ] [GTSdk DidSendMessage]:%@ \n\n", msg);
}

/// [ GTSDK回调 ] SDK运行状态通知
- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)aStatus {
    // [ 测试代码 ] 控制台打印日志，通知SDK运行状态
    NSLog(@"[ TestDemo ] [GTSdk SdkState]:%u \n\n", aStatus);
}

/// [ GTSDK回调 ] SDK设置推送模式回调
- (void)GeTuiSdkDidSetPushMode:(BOOL)isModeOff error:(NSError *)error {
    // [ 测试代码 ] 控制台打印日志
    if (error) {
        NSLog(@"\n>>[GTSdk SetModeOff Error]:%@\n\n", [error localizedDescription]);
        return;
    }
    
    NSLog(@"\n>>[GTSdk SetModeOff]:%@\n\n", isModeOff ? @"开启" : @"关闭");
}
              
@end
