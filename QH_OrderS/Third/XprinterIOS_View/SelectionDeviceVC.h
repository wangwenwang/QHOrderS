//
//  SelectionDeviceVC.h
//  Printer
//
//  Created by 李善忠 on 2017/10/20.
//  Copyright © 2017年 李善忠. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^VoidBlock_id)(id);

#define ConnectBleSuccessNote @"ConnectBleSuccessNote"

@class CBPeripheral, CBCharacteristic;

@interface SelectionDeviceVC : UIViewController

@property (nonatomic, strong)VoidBlock_id callBack;

+ (instancetype)controller;

#pragma mark - XYSDKDelegate// 发现周边
- (void)XYdidUpdatePeripheralList:(NSArray *)peripherals RSSIList:(NSArray *)rssiList;
// 连接周边
- (void)XYdidConnectPeripheral:(CBPeripheral *)peripheral;
// 连接失败
- (void)XYdidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
// 断开连接
- (void)XYdidDisconnectPeripheral:(CBPeripheral *)peripheral isAutoDisconnect:(BOOL)isAutoDisconnect;
// 发送数据成功
- (void)XYdidWriteValueForCharacteristic:(CBCharacteristic *)character error:(NSError *)error;

@end
