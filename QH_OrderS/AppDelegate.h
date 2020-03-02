//
//  AppDelegate.h
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//是否连接蓝牙
@property (assign, nonatomic) BOOL isConnectedBLE;

//是否连接Wi-Fi
@property (assign, nonatomic) BOOL isConnectedWIFI;

@end

