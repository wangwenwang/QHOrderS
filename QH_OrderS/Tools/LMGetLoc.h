//
//  LMGetLoc.h
//  QH_OrderS
//
//  Created by wangww on 2019/8/1.
//  Copyright © 2019 王文望. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SendAddress)(NSString *address, double lng, double lat);

@interface LMGetLoc : NSObject

- (void)startLoc:(SendAddress)address;

@property (nonatomic, strong)SendAddress sendAddressBlock;

@end

NS_ASSUME_NONNULL_END
