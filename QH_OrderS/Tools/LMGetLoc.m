//
//  LMGetLoc.m
//  QH_OrderS
//
//  Created by wangww on 2019/8/1.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "LMGetLoc.h"
#import <BMKLocationkit/BMKLocationComponent.h>
#import "Tools.h"

@interface LMGetLoc ()<BMKLocationAuthDelegate, BMKLocationManagerDelegate>

@property (nonatomic, strong) BMKLocationManager *locationManager;

// 定位block
@property (nonatomic, copy) BMKLocatingCompletionBlock completionBlock;

@end

@implementation LMGetLoc

- (void)startLoc:(SendAddress)address {
    
    // block赋值
    self.sendAddressBlock = address;
    
    // 初始化定位参数
    [self configLocationManager];

    // 声明回调
    [self initCompleteBlock];

    // 执行定位
    [self reGeocodeAction];
}


- (void)configLocationManager {
    
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"yIa27m9OpzEA0MMv7Eddl7aAUjcEGZPD" authDelegate:self];
    _locationManager = [[BMKLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    _locationManager.allowsBackgroundLocationUpdates = NO;
    _locationManager.locationTimeout = 10;
    _locationManager.reGeocodeTimeout = 10;
}


- (void)initCompleteBlock {
    
    __weak __typeof(self)weakSelf = self;
    self.completionBlock = ^(BMKLocation *location, BMKLocationNetworkState state, NSError *error) {
        if (error) {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
        }
        if (location) {//得到定位信息，添加annotation
            
            if (location.location) {
                NSLog(@"LOC = %@",location.location);
            }
            if (location.rgcData) {
                NSLog(@"rgc = %@",[location.rgcData description]);
            }
            
            BMKLocationReGeocode *rgcData = location.rgcData;
            NSString *displayLabel = @"";
            // 省
            if(rgcData.province) {
                
                displayLabel = [NSString stringWithFormat:@"%@%@", displayLabel, rgcData.province];
            }
            // 市
            if(rgcData.city) {
                
                displayLabel = [NSString stringWithFormat:@"%@%@", displayLabel, rgcData.city];
            }
            // 区/县
            if(rgcData.district) {
                
                displayLabel = [NSString stringWithFormat:@"%@%@", displayLabel, rgcData.district];
            }
            // 街道
            if(rgcData.street) {
                
                displayLabel = [NSString stringWithFormat:@"%@%@", displayLabel, rgcData.street];
            }
            // 门牌号
            if(rgcData.streetNumber) {
                
                displayLabel = [NSString stringWithFormat:@"%@%@", displayLabel, rgcData.streetNumber];
            }
            NSLog(@"省:%@", rgcData.province);
            NSLog(@"市:%@", rgcData.city);
            NSLog(@"区/县:%@", rgcData.district);
            NSLog(@"街道:%@", rgcData.street);
            NSLog(@"门牌号:%@", rgcData.streetNumber);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakSelf.sendAddressBlock(displayLabel, location.location.coordinate.longitude, location.location.coordinate.latitude);
            });
            
            if(!rgcData.province && !rgcData.city && !rgcData.district) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:[UIApplication sharedApplication].keyWindow andTitle:@"鉴权失败，重新定位"];
                    // 执行定位
                    [weakSelf reGeocodeAction];
                });
            }
        }
        NSLog(@"netstate = %d",state);
    };
}


- (void)reGeocodeAction {
    
    [self.locationManager requestLocationWithReGeocode:YES withNetworkState:NO completionBlock:self.completionBlock];
}


#pragma mark - BMKLocationAuthDelegate

// 百度地图授权验证
- (void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError {
    
    switch (iError) {
        case BMKLocationAuthErrorSuccess:
            NSLog(@"百度地图|鉴权成功");
            break;
        case BMKLocationAuthErrorNetworkFailed:
            NSLog(@"百度地图|因网络鉴权失败");
            break;
        case BMKLocationAuthErrorFailed:
            NSLog(@"百度地图|KEY非法鉴权失败");
            break;
        case BMKLocationAuthErrorUnknown:
            NSLog(@"百度地图|未知错误");
            break;
            
        default:
            break;
    }
}

@end
