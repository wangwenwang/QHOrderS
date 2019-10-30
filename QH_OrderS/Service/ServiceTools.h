//
//  ServiceTools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceToolsDelegate <NSObject>

@optional
- (void)failureOfLogin:(nullable NSString *)msg;

@optional
- (void)downloadStart;

@optional
- (void)downloadProgress:(double)progress;

@optional
- (void)downloadCompletion:(nullable NSString *)version andFilePath:(nullable NSString *)filePath;


@end

@interface ServiceTools : NSObject

@property (nullable, weak, nonatomic)id <ServiceToolsDelegate> delegate;


/// 查询版本号
/// @param showPrompt 是否显示提示
- (void)queryAppVersion:(BOOL)showPrompt;

@end
