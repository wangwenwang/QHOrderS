//
//  PrintVC.m
//  Order
//
//  Created by wenwang wang on 2019/4/3.
//  Copyright © 2019 凯东源. All rights reserved.
//

#import "PrintVC.h"
#import "Tools.h"

#import "XYBLEManager.h"
#import "SelectionDeviceVC.h"
#import "PosCommand.h"
#import "AppDelegate.h"

@interface PrintVC ()<UIAlertViewDelegate, XYBLEManagerDelegate>

/** BLE */
@property (strong, nonatomic) XYBLEManager *manager;

// 是否打开蓝牙
@property (strong, nonatomic) Tools *t;

// 连接/断开按钮
@property (weak, nonatomic) IBOutlet UIButton *statusBtn;

@end

@implementation PrintVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title =  @"蓝牙打印";
    
    _t = [[Tools alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectBle:) name:ConnectBleSuccessNote object:nil];
    [self.manager addObserver:self
                   forKeyPath:@"writePeripheral.state"
                      options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                      context:nil];
    [self.manager XYstartScan];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(1000000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            BOOL b = [_t blueToothOpen];
            
            if(!b) {
//                [LM_alert showLMAlertViewWithTitle:@"请打开蓝牙" message:@"" cancleButtonTitle:@"确定" okButtonTitle:nil otherButtonTitleArray:nil];
                NSLog(@"fds");
            }
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    self.manager.delegate = self;
}


- (void)dealloc {
    
    [self.manager XYdisconnectRootPeripheral];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ConnectBleSuccessNote object:nil];
    [self.manager removeObserver:self forKeyPath:@"writePeripheral.state" context:nil];
    //    [_t stopBleScan];
    [self.manager XYstopScan];
    self.manager.delegate = nil;
}

#pragma mark - 事件

- (IBAction)dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 通知

- (void)connectBle:(NSNotification *)text{
    
    [self.statusBtn setTitle:@"断开连接" forState:UIControlStateNormal];
    [self.statusBtn setBackgroundColor:[UIColor redColor]];
    SharedAppDelegate.isConnectedBLE = YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (self.manager && object == self.manager && [keyPath isEqualToString:@"writePeripheral.state"]) {
        // 更行蓝牙的连接状态
        switch (self.manager.writePeripheral.state) {
            case CBPeripheralStateDisconnected:
            {
                [self.statusBtn setTitle:@"蓝牙连接" forState:UIControlStateNormal];
                [self.statusBtn setBackgroundColor:RGB(61, 147, 73)];
                SharedAppDelegate.isConnectedBLE = NO;
                break;
            }
                
            case CBPeripheralStateConnecting:
            {
                [self.statusBtn setTitle:@"设备正在连接" forState:UIControlStateNormal];
                break;
            }
            case CBPeripheralStateConnected:
            {
                [self.statusBtn setTitle:@"断开连接" forState:UIControlStateNormal];
                [self.statusBtn setBackgroundColor:[UIColor redColor]];
                SharedAppDelegate.isConnectedBLE = YES;
                break;
            }
            case CBPeripheralStateDisconnecting:
            {
                [self.statusBtn setTitle:@"蓝牙连接" forState:UIControlStateNormal];
                [self.statusBtn setBackgroundColor:RGB(61, 147, 73)];
                SharedAppDelegate.isConnectedBLE = NO;
                break;
            }
            default:
                break;
        };
    }
}


- (IBAction)connectOnclick {
    
    if(SharedAppDelegate.isConnectedBLE) {
        
        [self.manager XYdisconnectRootPeripheral];
    }else {
        
        SelectionDeviceVC *vc = [[SelectionDeviceVC alloc] init];;
        vc.callBack = ^(id x){
            SharedAppDelegate.isConnectedBLE = YES;
            SharedAppDelegate.isConnectedWIFI = NO;
            NSString *message = @"蓝牙连接成功";
            [Tools showAlert:self.view andTitle:message];
        };
        [self presentViewController:vc animated:YES completion:nil];
    }
}

//打印文字
- (IBAction)printOnclick {
    
    BOOL b = [_t blueToothOpen];
    
    if(!b) {
        
        [Tools showAlert:self.view andTitle:@"请打开蓝牙"];
        return;
    }
    
    if([_dict[@"tenant_code"] isEqualToString:@"TYWL"]){
        
        [self printText_TY:@"存根联"];
        [self printText_TY:@"虚线"];
        [self printText_TY:@"客户联"];
        [self printText_TY:@"虚线"];
        [self printText_TY:@"回单联"];
    }else{
        
        [self printText:@"客户联"];
        [self printText:@"虚线"];
        [self printText:@"回单联"];
    }
}

- (void)printText_TY:(NSString *)CUSTOM_OR_RECEIPT {
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSMutableData* dataM=[NSMutableData dataWithData:[XYCommand initializePrinter]];
    
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"虚线"]) {
        
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData: [@"- - - - - - - - - - - - - - - - - - - - - - - -" dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        if (SharedAppDelegate.isConnectedBLE) {
            
            [self.manager XYWriteCommandWithData:dataM];
        }else{
            
            [Tools showAlert:self.view andTitle:@"请连接蓝牙"];
        }
        return;
    }
    
    // 客户联|回单联
    [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:200 andNH:01]];
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"存根联"]) {
        [dataM appendData: [@"【存根联】" dataUsingEncoding: gbkEncoding]];
    }else if ([CUSTOM_OR_RECEIPT isEqualToString:@"客户联"]) {
        [dataM appendData: [@"【客户联】" dataUsingEncoding: gbkEncoding]];
    }else if ([CUSTOM_OR_RECEIPT isEqualToString:@"回单联"]) {
        [dataM appendData: [@"【回单联】" dataUsingEncoding: gbkEncoding]];
    }
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 头部
    // 抬头 居中
    [dataM appendData:[XYCommand selectAlignment:1]];
    
//    [dataM appendData:[XYCommand selectOrCancleBoldModel:1]];
    [dataM appendData:[XYCommand selectCharacterSize:17]];
    [dataM appendData: [_dict[@"header"] dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData:[XYCommand initializePrinter]];
    
    [dataM appendData:[XYCommand selectAlignment:0]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 订单号
    NSString *orderNO = _dict[@"order_no"];
    // 发货客户
    NSString *conoCompany = _dict[@"cono_company"];
    // 收货客户
    NSString *coneCompany = _dict[@"cone_company"];
    // 收货人
    NSString *coneName = _dict[@"cone_name"];
    // 收货人电话
    NSString *coneTel = _dict[@"cone_tel"];
    // 收货地址
    NSString *coneAddress = _dict[@"cone_address"];
    
    // 订单号 居左
    NSString *ordNo = [NSString stringWithFormat:@"订 单 号：%@", orderNO];
    [dataM appendData: [ordNo dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 发货客户 居左
    conoCompany = [NSString stringWithFormat:@"发货客户：%@", conoCompany];
    [dataM appendData: [conoCompany dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 收货客户 居左
    coneCompany = [NSString stringWithFormat:@"收货客户：%@", coneCompany];
    [dataM appendData: [coneCompany dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 收货人 居左
    coneName = [NSString stringWithFormat:@"收 货 人：%@  %@", coneName, coneTel];
    [dataM appendData: [coneName dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 收货地址
    coneAddress = [NSString stringWithFormat:@"收货地址：%@", coneAddress];
    [dataM appendData: [coneAddress dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 商品格式说明 居左
    [dataM appendData: [@"商品/数量/重量" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData:[XYCommand selectAlignment:0]];
    
    NSArray *product =_dict[@"product"];
    for (int i = 0; i < product.count; i++) {
        
        NSDictionary *p = product[i];
        
        NSString *name = [NSString stringWithFormat:@"%d.%@", i + 1, p[@"name"]];
        // 产品名称太长，分两行
        NSString *namePadPreix = name;
        NSString *nameSuffix = @"";
        
        // 数量占位t符
        NSString *qtyLoc = @"abcdefgheijklnmopqrstuv";
        int nameLenght = [Tools textLength:namePadPreix];
        int pad = [Tools textLength:qtyLoc] - nameLenght;
        if(pad > 0){
            for (int i = 0; i < pad; i++) {
                namePadPreix = [namePadPreix stringByAppendingFormat:@" "];
            }
        }
        
        // 产品名称超过设置长度，自动换行
        if(pad < 0) {
            int padPreix = 1;
            for (int i = 0; i <= name.length; i++) {
                if(padPreix > 0) {
                    namePadPreix = [name substringToIndex:i];
                    int namePadPreixLenght = [Tools textLength:namePadPreix];
                    padPreix = [Tools textLength:qtyLoc] - namePadPreixLenght;
                }else {
                    nameSuffix = [name substringFromIndex:i - 1];
                    break;
                }
            }
        }
        
        // 名称
        [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:00 andNH:00]];
        [dataM appendData: [namePadPreix dataUsingEncoding: gbkEncoding]];
        
        // 数量
        NSString *qty = [NSString stringWithFormat:@"   %@[%@]", [Tools  OneDecimal:p[@"qty"]], p[@"uom"]];
        [dataM appendData: [qty dataUsingEncoding: gbkEncoding]];
        
        // 重量
        NSString *weight = [NSString stringWithFormat:@"%.1f公斤", [p[@"weight"] floatValue]];
        [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:200 andNH:01]];
        [dataM appendData: [weight dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        
        if(pad < 0) {
            // 名称(第二行)
            [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:25 andNH:00]];
            [dataM appendData: [nameSuffix dataUsingEncoding: gbkEncoding]];
            [dataM appendData:[XYCommand printAndFeedLine]];
        }
    }
    
    // 总数量
    float totalQTY = [_dict[@"total_qty"] floatValue];
    // 总重量
    float totalWeight = [_dict[@"total_weight"] floatValue];
    // 订单类型
    NSString *orderType = _dict[@"order_type"];
    // 交货方式
    NSString *deliveryWay = _dict[@"delivery_way"];
    // 下单时间
    NSString *ordDateAdd = _dict[@"ord_date_add"];
    // 打印人
    NSString *printPerson = _dict[@"print_person"];
    
    // 尾部
    // 总数量、总重量
    [dataM appendData:[XYCommand selectAlignment:0]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    NSString *total = [NSString stringWithFormat:@"总 数 量：%.1f     总重量：%.1f公斤", totalQTY, totalWeight];
    [dataM appendData: [total dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 订单类型 居左
    orderType = [NSString stringWithFormat:@"订单类型：%@", orderType];
    [dataM appendData: [orderType dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 交货方式 居左
    deliveryWay = [NSString stringWithFormat:@"交货方式：%@", deliveryWay];
    [dataM appendData: [deliveryWay dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 下单时间 居左
    ordDateAdd = [NSString stringWithFormat:@"下单时间：%@", ordDateAdd];
    [dataM appendData: [ordDateAdd dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 打印人 居左
    printPerson = [NSString stringWithFormat:@"打 印 人：%@", printPerson];
    [dataM appendData: [printPerson dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"回单联"]) {
        
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData: [@"客户签名：" dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        // 换行，不用手动走纸
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
    }
    
    if (SharedAppDelegate.isConnectedBLE) {
        
        [self.manager XYWriteCommandWithData:dataM];
    }else{
        
        [Tools showAlert:self.view andTitle:@"请连接蓝牙"];
    }
}

- (void)printText:(NSString *)CUSTOM_OR_RECEIPT {
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSMutableData* dataM=[NSMutableData dataWithData:[XYCommand initializePrinter]];
    
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"虚线"]) {
        
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData: [@"- - - - - - - - - - - - - - - - - - - - - - - -" dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        if (SharedAppDelegate.isConnectedBLE) {
            
            [self.manager XYWriteCommandWithData:dataM];
        }else{
            
            [Tools showAlert:self.view andTitle:@"请连接蓝牙"];
        }
        return;
    }
    
    // 客户联|回单联
    [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:200 andNH:01]];
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"客户联"]) {
        [dataM appendData: [@"【客户联】" dataUsingEncoding: gbkEncoding]];
    }else if ([CUSTOM_OR_RECEIPT isEqualToString:@"回单联"]) {
        [dataM appendData: [@"【回单联】" dataUsingEncoding: gbkEncoding]];
    }
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 头部
    // 抬头 居中
    [dataM appendData:[XYCommand selectAlignment:1]];
    
    [dataM appendData: [_dict[@"header"] dataUsingEncoding: gbkEncoding]];
    
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData:[XYCommand selectAlignment:0]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 客户代码
    NSString *partyCode = _dict[@"cone_code"];
    // 客户名称
    NSString *partyName = _dict[@"cone_name"];
    // 客户地址
    NSString *partyAddress = _dict[@"cone_address"];
    // 客户电话
    NSString *partyTel = _dict[@"cone_tel"];
    
    // 客户代码/电话/ 居左
    partyCode = [NSString stringWithFormat:@"客户代码：%@   [%@]", partyCode, partyTel];
    [dataM appendData: [partyCode dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 客户名称 居左
    partyName = [NSString stringWithFormat:@"客户名称：%@", partyName];
    [dataM appendData: [partyName dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 客户地址 居左
    partyName = [NSString stringWithFormat:@"客户地址：%@", partyAddress];
    [dataM appendData: [partyName dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    // 商品格式说明 居左
    [dataM appendData: [@"商品/数量/单价" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    [dataM appendData:[XYCommand selectAlignment:0]];
    
    NSArray *product =_dict[@"product"];
    for (int i = 0; i < product.count; i++) {
        
        NSDictionary *p = product[i];
        
        NSString *name = [NSString stringWithFormat:@"%d.%@", i + 1, p[@"name"]];
        // 产品名称太长，分两行
        NSString *namePadPreix = name;
        NSString *nameSuffix = @"";
        
        // 数量占位t符
        NSString *qtyLoc = @"abcdefgheijklnmopqrstuv";
        int nameLenght = [Tools textLength:namePadPreix];
        int pad = [Tools textLength:qtyLoc] - nameLenght;
        if(pad > 0){
            for (int i = 0; i < pad; i++) {
                namePadPreix = [namePadPreix stringByAppendingFormat:@" "];
            }
        }
        
        // 产品名称超过设置长度，自动换行
        if(pad < 0) {
            int padPreix = 1;
            for (int i = 0; i <= name.length; i++) {
                if(padPreix > 0) {
                    namePadPreix = [name substringToIndex:i];
                    int namePadPreixLenght = [Tools textLength:namePadPreix];
                    padPreix = [Tools textLength:qtyLoc] - namePadPreixLenght;
                }else {
                    nameSuffix = [name substringFromIndex:i - 1];
                    break;
                }
            }
        }
        
        // 名称
        [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:00 andNH:00]];
        [dataM appendData: [namePadPreix dataUsingEncoding: gbkEncoding]];
        
        // 数量
        NSString *qty = [NSString stringWithFormat:@"   %@[%@]", [Tools  OneDecimal:p[@"qty"]], p[@"uom"]];
        [dataM appendData: [qty dataUsingEncoding: gbkEncoding]];
        
        // 金额
        NSString *price = [NSString stringWithFormat:@"￥%.2f", [p[@"price"] floatValue]];
        [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:200 andNH:01]];
        [dataM appendData: [price dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        
        if(pad < 0) {
            // 名称(第二行)
            [dataM appendData:[XYCommand setAbsolutePrintXYitionWithNL:25 andNH:00]];
            [dataM appendData: [nameSuffix dataUsingEncoding: gbkEncoding]];
            [dataM appendData:[XYCommand printAndFeedLine]];
        }
    }
    
    // 总数量
    float totalQTY = [_dict[@"total_qty"] floatValue];
    // 总金额
    float totalPrice = [_dict[@"total_price"] floatValue];
    // 订单号
    NSString *orderNO = _dict[@"order_no"];
    
    // 尾部
    // 总数量、总金额
    [dataM appendData:[XYCommand selectAlignment:0]];
    [dataM appendData: [@"---------------------------------------------" dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    NSString *total = [NSString stringWithFormat:@"总数量：%.1f     总金额：%.2f", totalQTY, totalPrice];
    [dataM appendData: [total dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 打印时间、开单人、帐号
    NSString *userName = _dict[@"cono_name"];
    NSString *time = [NSString stringWithFormat:@"%@  [%@  %@]", [Tools getCurrentDate], _dict[@"cono_tel"], userName];
    [dataM appendData: [time dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    // 订单号
    NSString *ordNo = [NSString stringWithFormat:@"订单号：%@", orderNO];
    [dataM appendData: [ordNo dataUsingEncoding: gbkEncoding]];
    [dataM appendData:[XYCommand printAndFeedLine]];
    
    if ([CUSTOM_OR_RECEIPT isEqualToString:@"回单联"]) {
        
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData: [@"客户签名：" dataUsingEncoding: gbkEncoding]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        // 换行，不用手动走纸
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
        [dataM appendData:[XYCommand printAndFeedLine]];
    }
    
    if (SharedAppDelegate.isConnectedBLE) {
        
        [self.manager XYWriteCommandWithData:dataM];
    }else{
        
        [Tools showAlert:self.view andTitle:@"请连接蓝牙"];
    }
}

#pragma mark - GET方法

- (XYBLEManager *)manager {
    
    if (!_manager) {
        
        _manager = [XYBLEManager sharedInstance];
        _manager.delegate = self;
    }
    return _manager;
}

#pragma mark - XYSDKDelegate
- (void)XYdidUpdatePeripheralList:(NSArray *)peripherals RSSIList:(NSArray *)rssiList {
    
    NSMutableArray *dataArr = [NSMutableArray arrayWithArray:peripherals];
    int i = 0;
    for (CBPeripheral *peripheral in dataArr) {
        NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:@"w_peripheral.name"];
        if([name isEqualToString:peripheral.name]) {
            
            [self.manager XYconnectDevice:peripheral];
            self.manager.writePeripheral = peripheral;
            [Tools showAlert:self.view andTitle:@"连接成功"];
            i ++;
            break;
        }
    }
    if(i == 0) {
        
        [Tools showAlert:self.view andTitle:@"未找到打印机"];
    }
}

@end
