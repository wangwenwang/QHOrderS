//
//  Tools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import <Foundation/Foundation.h>

@interface Tools : NSObject

/// 获取zip版本号
+ (nullable NSString *)getZipVersion;


/// 设置zip版本号
+ (void)setZipVersion:(nullable NSString *)version;


/// 获取服务器地址
+ (nullable NSString *)getServerAddress;


/// 设置服务器地址
+ (void)setServerAddress:(nullable NSString *)baseUrl;


/// 版本号比较，1为服务器>本地，0为服务器=本地，-1为服务器<本地，-2为版本号不合法
+ (int)compareVersion:(nullable NSString *)server andLocati:(nullable NSString *)locati;


/// 获取解压zip路径
+ (nullable NSString *)getUnzipPath;


/// 关闭Webview编辑功能
+ (void)closeWebviewEdit:(nullable WKWebView *)_webView;


/// 打开Webview编辑功能
+ (void)openWebviewEdit:(nullable WKWebView *)_webView;


/// 判断是否允许定位
//+ (BOOL)isLocationServiceOpen;


/// 判断网络状态
+ (BOOL)isConnectionAvailable;


/// 提示  参数:View    NSString
+ (void)showAlert:(nullable UIView *)view andTitle:(nullable NSString *)title;


/**
 提示带时间参数
 @param view  父窗口
 @param title 标题
 @param time  停留时间
 */
+ (void)showAlert:(nullable UIView *)view andTitle:(nullable NSString *)title andTime:(NSTimeInterval)time;


/// 设置上一次启动的版本号
+ (void)setLastVersion;


/// 获取上一次启动的版本号
+ (nullable NSString *)getLastVersion;


/// 获取当前版本号
+ (nullable NSString *)getCFBundleShortVersionString;


/// 检测位置权限
+ (void)skipLocationSettings;


/// 获取根控制器
+ (nullable UIViewController *)getRootViewController;


/// 获取是否进入过主页（判断检查定位权限延迟，第一次进入延迟时长至10秒，否则延迟3秒）
+ (nullable NSString *)getEnterTheHomePage;


/// 设置是否进入过主页（判断检查定位权限延迟，第一次进入延迟时长至10秒，否则延迟3秒）
+ (void)setEnterTheHomePage:(nullable NSString *)enter;


/**
 蓝牙是否打开
 */
@property (nonatomic, assign) BOOL blueToothOpen;


/**
 * 获取手机当前时间
 *
 * return 手机当前时间 "yyy-MM-dd HH:mm:ss"
 */
+ (nullable NSString *)getCurrentDate;


/**
 * JSON字符串转化为字典
 *
 * return 字典
 */
+ (nullable NSDictionary *)dictionaryWithJsonString:(nullable NSString *)jsonString;


/**
 判断一段字符串长度(汉字2字节)
 
 @param text 字符串
 @return 长度(汉字2字节)
 */
+ (int)textLength: (nullable NSString *)text;


/**
 保留字符串后面1位小数
 
 @param str 字符串
 
 @return 带1位小数的字符串
 */
+ (nullable NSString *)OneDecimal:(nullable NSString *)str;

@end
