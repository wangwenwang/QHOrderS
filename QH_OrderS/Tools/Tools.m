//
//  Tools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "Tools.h"
#import <MBProgressHUD.h>
//#import "LM_alert.h"
#import "AppDelegate.h"

@implementation Tools

+ (nullable NSString *)getZipVersion {
    
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_ZipVersion_local_key];
}

+ (void)setZipVersion:(nullable NSString *)version {
    
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:kUserDefaults_ZipVersion_local_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (nullable NSString *)getServerAddress {
    
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_Server_Address_key];
}

+ (void)setServerAddress:(nullable NSString *)baseUrl {
    
    [[NSUserDefaults standardUserDefaults] setObject:baseUrl forKey:kUserDefaults_Server_Address_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)compareVersion:(nullable NSString *)server andLocati:(nullable NSString *)locati {
    NSArray *servers = [server componentsSeparatedByString:@"."];
    NSArray *locatis = [locati componentsSeparatedByString:@"."];
    @try {
        int s = [servers[0] intValue] * 100 + [servers[1] intValue] * 10 + [servers[2] intValue] * 1;
        int l = [locatis[0] intValue] * 100 + [locatis[1] intValue] * 10 + [locatis[2] intValue] * 1;
        if(s == l) return 0;
        else return (s > l) ? 1 : -1;
    } @catch (NSException *exception) {
        return -2;
    }
}

+ (nullable NSString *)getUnzipPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *unzipPath = [documentpath stringByAppendingPathComponent:@"/unzip"];
    return unzipPath;
}

+ (void)closeWebviewEdit:(nullable UIWebView *)_webView {
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}

+ (void)openWebviewEdit:(nullable UIWebView *)_webView {
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='text';"];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='text';"];
}

//+ (BOOL)isLocationServiceOpen {
//    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
//        return YES;
//    } else {
//        return NO;
//    }
//}

+ (BOOL)isConnectionAvailable {
    BOOL isExistenceNetwork = YES;
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    
    switch ([reach currentReachabilityStatus]) {
        case NotReachable:
            isExistenceNetwork = NO;
            //NSLog(@"notReachable");
            break;
        case ReachableViaWiFi:
            isExistenceNetwork = YES;
            //NSLog(@"WIFI");
            break;
        case ReachableViaWWAN:
            isExistenceNetwork = YES;
            //NSLog(@"3G");
            break;
    }
    return isExistenceNetwork;
}

+ (void)showAlert:(nullable UIView *)view andTitle:(nullable NSString *)title {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.label.numberOfLines = 0;
    hud.margin = 15.0f;
    hud.removeFromSuperViewOnHide = YES;
    hud.userInteractionEnabled = NO;
    [hud hideAnimated:YES afterDelay:2];
}

+ (void)showAlert:(nullable UIView *)view andTitle:(nullable NSString *)title andTime:(NSTimeInterval)time {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.label.numberOfLines = 0;
    hud.margin = 15.0f;
    hud.removeFromSuperViewOnHide = YES;
    hud.userInteractionEnabled = NO;
    [hud hideAnimated:YES afterDelay:time];
}

+ (void)setLastVersion {
    
    NSString *app_version = [self getCFBundleShortVersionString];
    [[NSUserDefaults standardUserDefaults] setValue:app_version forKey:kUserDefaults_Last_Version_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (nullable NSString *)getLastVersion {
    
     return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_Last_Version_key];
}

+ (nullable NSString *)getCFBundleShortVersionString {
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return [infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

+ (void)skipLocationSettings {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *promptLocation = [NSString stringWithFormat:@"请打开系统设置中\"隐私->定位服务\",允许%@使用定位服务", AppDisplayName];
//    [LM_alert showLMAlertViewWithTitle:@"打开定位开关" message:promptLocation cancleButtonTitle:nil okButtonTitle:@"立即设置" otherButtonTitleArray:nil clickHandle:^(NSInteger index) {
//        if(SystemVersion > 8.0) {
//            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//            if ([[UIApplication sharedApplication] canOpenURL:url]) {
//                [[UIApplication sharedApplication] openURL:url];
//            }
//        } else {
//            [self showAlert:app.window andTitle:@"不支持iOS及以下设备"];
//        }
//    }];
}

+ (nullable UIViewController *)getRootViewController {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootViewController = app.window.rootViewController;
    return rootViewController;
}

+ (nullable NSString *)getEnterTheHomePage {
    
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_EnterTheHomePage];
}


+ (void)setEnterTheHomePage:(nullable NSString *)enter {
    
    [[NSUserDefaults standardUserDefaults] setObject:enter forKey:kUserDefaults_EnterTheHomePage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
