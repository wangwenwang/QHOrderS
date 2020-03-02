//
//  SelectionDeviceVC.m
//  Printer
//
//  Created by 李善忠 on 2017/10/20.
//  Copyright © 2017年 李善忠. All rights reserved.
//

#import "SelectionDeviceVC.h"
#import "SelectionDeviceCell.h"
#import "XYBLEManager.h"
#import <MBProgressHUD.h>
#import "AppDelegate.h"
#import "Tools.h"

@interface SelectionDeviceVC ()<XYBLEManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArr;
@property (nonatomic,strong) NSArray *rssiList;
@property (nonatomic,strong) XYBLEManager *manager;
//@property (weak, nonatomic) IBOutlet UIButton *refleshBtn;

@end

#define kCellName @"SelectionDeviceVC"

@implementation SelectionDeviceVC

#pragma mark - lazy
- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"蓝牙选择";
    self.manager = [XYBLEManager sharedInstance];
    self.manager.delegate = self;
    [self.manager XYstartScan];
    
    [self registerCell];
}


// 注册Cell
- (void)registerCell {
    
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - 事件

- (IBAction)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArr.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 71;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //    static NSString *cellId = kCellName;
    //    SelectionDeviceCell *cell = (SelectionDeviceCell *)[tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    CBPeripheral *peripheral = self.dataArr[indexPath.row];
    NSNumber *rssi =_rssiList[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"设备名称:%@        RSSI:%zd",peripheral.name, rssi.integerValue];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *peripheral = self.dataArr[indexPath.row];
    
    // 存储蓝牙连接，下次自动连接
    [[NSUserDefaults standardUserDefaults] setObject:peripheral.name forKey:@"w_peripheral.name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *message =  [NSString stringWithFormat:@"正在连接%@",peripheral.name];
    //    [ProgressHUD show:message];
    [Tools showAlert:self.view andTitle:message];
    // 连接周边
    
    
    [self.manager XYconnectDevice:peripheral];
    self.manager.writePeripheral = peripheral;
}

#pragma mark - XYSDKDelegate
- (void)XYdidUpdatePeripheralList:(NSArray *)peripherals RSSIList:(NSArray *)rssiList{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        _dataArr = [NSMutableArray arrayWithArray:peripherals];
        _rssiList = rssiList;
        [_tableView reloadData];
    });
}

/** 连接成功 */
- (void)XYdidConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"%s",__func__);
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:NO];
//        [ProgressHUD dismiss];
        NSNotification *notification =[NSNotification notificationWithName:ConnectBleSuccessNote object:nil userInfo:nil];
        //通过通知中心发送行程开始通知
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        // 返回主页控制器
        [self dismissViewControllerAnimated:YES completion:nil];
        if (_callBack){
            _callBack(nil);
        }
        
    });
    SharedAppDelegate.isConnectedBLE = YES;
    SharedAppDelegate.isConnectedWIFI = NO;
}

// 连接失败
- (void)XYdidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [Tools showAlert:self.view andTitle:@"连接失败"];
    
    //    [ProgressHUD dismiss];
    //    [ProgressHUD showError:@"连接失败"];
}

// 写入数据成功
- (void)XYdidWriteValueForCharacteristic:(CBCharacteristic *)character error:(NSError *)error {
    
}
// 断开连接
- (void)XYdidDisconnectPeripheral:(CBPeripheral *)peripheral isAutoDisconnect:(BOOL)isAutoDisconnect{
    
    if (isAutoDisconnect) {
        NSLog(@"自动断开...");
        [self dismissViewControllerAnimated:YES completion:nil];
        [[[UIAlertView alloc] initWithTitle:@"device disconnect" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        [self scanAgain:nil];
    }else {
        NSLog(@"手动断开...");
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //        [MBProgressHUD hideHUDForView:self.view animated:NO];
    });
    
    NSLog(@"%s",__func__);
}

- (IBAction)scanAgain:(id)sender {
    [self.dataArr removeAllObjects];
    [self.tableView reloadData];
    [self.manager XYdisconnectRootPeripheral];
    [self.manager XYstartScan];
}

- (void)dealloc {
    
    [self.manager XYstopScan];
}

@end
