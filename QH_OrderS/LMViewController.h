//
//  LMViewController.h
//  QH_OrderS
//
//  Created by wangww on 2019/9/6.
//  Copyright © 2019 王文望. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKMapView.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMViewController : UIViewController

/// 用户的 idx
@property (copy, nonatomic) NSString *orderIDX;

/// 配载单号
@property (copy, nonatomic) NSString *shipmentCode;

/// 配载状态 在途、交付
@property (copy, nonatomic) NSString *shipmentStatus;

@end

NS_ASSUME_NONNULL_END
