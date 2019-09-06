//
//  CheckOrderPathViewController.h
//  Order
//
//  Created by 凯东源 on 16/10/20.
//  Copyright © 2016年 凯东源. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckOrderPathViewController : UIViewController

/// 用户的 idx
@property (copy, nonatomic) NSString *orderIDX;

/// 配载单号
@property (copy, nonatomic) NSString *shipmentCode;

/// 配载状态 在途、交付
@property (copy, nonatomic) NSString *shipmentStatus;

@end
