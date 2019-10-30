//
//  ViewController.m
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <SSZipArchive.h>
#import "Tools.h"
#import "XHVersion.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WXApi.h>
#import "IOSToVue.h"
#import "LMGetLoc.h"
#import "CheckOrderPathViewController.h"

#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#import <AddressBookUI/ABPersonViewController.h>
#import <ContactsUI/ContactsUI.h>

#import "YBLocationPickerViewController.h"

#import <MapKit/MKMapItem.h>
#import <BMKLocationkit/BMKLocationComponent.h>

#import <LMProgressView.h>
#import "ServiceTools.h"

@interface ViewController ()<UIGestureRecognizerDelegate, UIWebViewDelegate, ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, ServiceToolsDelegate>

@property (strong, nonatomic) AppDelegate *app;

@property (nonatomic, strong)UIView *downView;

@property (nonatomic, strong)LMProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addWebView];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    
    NSLog(@"ScreenHeight:%f", ScreenHeight);
    NSString *imageName = @"";
    
    if(ScreenHeight == 480) {
        
        // iPhone4S
        imageName = @"640 × 960";
    }else if(ScreenHeight == 568){
        
        // iPhone5S、iPhoneSE
        imageName = @"640 × 1136";
    }else if(ScreenHeight == 667){
        
        // iPhone6、iPhone6S、iPhone7、iPhone8
        imageName = @"750 × 1334";
    }else if(ScreenHeight == 736){
        
        // iPhone6P、iPhone6SP、iPhone7P、iPhone8P
        imageName = @"1242 × 2208";
    }else if(ScreenHeight == 812){
        
        // iPhoneX、iPhoneXS
        imageName = @"1125 × 2436";
    }else if(ScreenHeight == 896){
        
        // iPhoneXR
        imageName = @"1242 × 2688";
    }else {
        
        // iPhoneXSMAX
        imageName = @"1242 × 2688";
        [Tools showAlert:self.view andTitle:@"未知设备" andTime:5];
    }
    
    [imageV setImage:[UIImage imageNamed:imageName]];
    [imageV setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self.view addSubview:imageV];
    
    [UIView animateWithDuration:0.8 delay:0.8 options:0 animations:^{
        
        [imageV setAlpha:0];
    } completion:^(BOOL finished) {
        
        [imageV removeFromSuperview];
    }];
}


#pragma mark - 检查版本

- (void)checkZipVersion {
    
    NSString *currVersion = [Tools getZipVersion];
    if(currVersion == nil) {
        NSLog(@"初次检查zip版本，设置默认");
        [Tools setZipVersion:kUserDefaults_ZipVersion_local_defaultValue];
    }else{
        NSLog(@"本地zip版本：%@", currVersion);
    }
    
    ServiceTools *s = [[ServiceTools alloc] init];
    s.delegate = self;
    UIViewController *rootViewController = ((AppDelegate*)([UIApplication sharedApplication].delegate)).window.rootViewController;
    if([rootViewController isKindOfClass:[ViewController class]]) {
        
        [s queryAppVersion:YES];
    }
}


#pragma mark GET方法

- (void)addWebView {
    
    if(_webView == nil) {
        
        _webView = [[UIWebView alloc] init];
        [_webView setFrame:CGRectMake(0, kStatusHeight, ScreenWidth, ScreenHeight - kStatusHeight - SafeAreaBottomHeight)];
        _webView.delegate = self;
        [self.view addSubview:_webView];
        
        // 初始化信息
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // 长按5秒，开启webview编辑模式
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        longPress.minimumPressDuration = 2;
        [_webView addGestureRecognizer:longPress];
        
        NSString *unzipPath = [Tools getUnzipPath];
        NSLog(@"unzipPath:%@", unzipPath);
        
        NSString *checkFilePath = [unzipPath  stringByAppendingPathComponent:@"dist/index.html"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:checkFilePath] && [[Tools getLastVersion] isEqualToString:[Tools getCFBundleShortVersionString]]) {
            
            NSLog(@"HTML已存在，无需解压");
        } else {
            
            NSLog(@"第一次加载，或版本有更新，解压");
            NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
            NSLog(@"zipPath:%@", zipPath);
            [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
        }
        [Tools setLastVersion];
        
        // 加载URL
        NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
        NSURL *url = [[NSURL alloc] initWithString:filePath];
        
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
        // 禁用弹簧效果
        for (id subview in _webView.subviews){
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
            }
        }
        // 取消右侧，下侧滚动条，去处上下滚动边界的黑色背景
        for (UIView *_aView in [_webView subviews]) {
            if ([_aView isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)_aView setShowsVerticalScrollIndicator:NO];
                // 右侧的滚动条
                [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
                // 下侧的滚动条
                for (UIView *_inScrollview in _aView.subviews) {
                    if ([_inScrollview isKindOfClass:[UIImageView class]]) {
                        _inScrollview.hidden = YES;  // 上下滚动出边界时的黑色的图片
                    }
                }
            }
        }
    }
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [Tools closeWebviewEdit:_webView];
}


// webViewDidFinishLoad方法晚于vue的mounted函数 0.3秒左右，不采用
- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    __weak __typeof(self)weakSelf = self;
    
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * first = @"";
        NSString * second = @"";
        NSString * third = @"";
        NSString * fourth = @"";
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            first = jsVal.toString;
            break;
        }
        @try {
            JSValue *jsVal = args[1];
            second = jsVal.toString;
        } @catch (NSException *exception) { }
        @try {
            JSValue *jsVal = args[2];
            third = jsVal.toString;
        } @catch (NSException *exception) { }
        @try {
            JSValue *jsVal = args[3];
            fourth = jsVal.toString;
        } @catch (NSException *exception) { }
        
        if([first isEqualToString:@"微信登录"]) {
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_tms";
            dispatch_async(dispatch_get_main_queue(), ^{
                [WXApi sendReq:req];
            });
        }
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        else if([first isEqualToString:@"登录页面已加载"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                    
                    // 微信
                    NSLog(@"设备已安装【微信】");
                }else {
                    
                    // 移除微信按钮
                    [IOSToVue TellVueWXInstall_Check_Ajax:weakSelf.webView andIsInstall:@"NO"];
                }
            });
            
            // 发送APP版本号
            [IOSToVue TellVueVersionShow:weakSelf.webView andVersion:[NSString stringWithFormat:@"版本:%@", [Tools getCFBundleShortVersionString]]];
            
            // 发送设备标识
            [IOSToVue TellVueDevice:weakSelf.webView andDevice:@"iOS"];
        }
        // 导航
        else if([first isEqualToString:@"导航"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self navigationOnclick:[third doubleValue] andLng:[second doubleValue] andAddress:fourth];
            });
        }
        // 查看路线
        else if([first isEqualToString:@"查看路线"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{

                [weakSelf showLocLine:second andShipmentCode:third andShipmentStatus:fourth];
            });
        }
        // 服务器地址
        else if([first isEqualToString:@"服务器地址"]) {
            
            [Tools setServerAddress:second];
        }
        // 记住帐号密码，开始定位
        else if([first isEqualToString:@"记住帐号密码"]) {
            
//            if(!_service) {
//                _service = [[ServiceTools alloc] init];
//            }
//            _service.delegate = self;
            
            // 检查更新
            [XHVersion checkNewVersion];
        }
        // 获取当前位置页面已加载，预留接口，防止js获取当前位置出问题
        else if([first isEqualToString:@"获取当前位置页面已加载"]) {
            
            [[[LMGetLoc alloc] init] startLoc:^(NSString * _Nonnull address, double lng, double lat) {
                
                [IOSToVue TellVueCurrAddress:webView andAddress:address andLng:lng andLat:lat];
            }];
        }
        // 调用通讯录
        else if([first isEqualToString:@"调用通讯录"]) {
            
            if(SystemVersion >= 10.0){
                //iOS 10
                //    AB_DEPRECATED("Use CNContactPickerViewController from ContactsUI.framework instead")
                CNContactPickerViewController * contactVc = [CNContactPickerViewController new];
                contactVc.delegate = self;
                [self presentViewController:contactVc animated:YES completion:^{
                    
                }];
            } else {
                
                ABPeoplePickerNavigationController *nav = [[ABPeoplePickerNavigationController alloc] init];
                nav.peoplePickerDelegate = self;
                if(SystemVersion > 8.0){
                    nav.predicateForSelectionOfPerson = [NSPredicate predicateWithValue:false];
                }
                [self presentViewController:nav animated:YES completion:nil];
            }
        }
        // 调用发送位置
        else if([first isEqualToString:@"调用发送位置"]) {
            
            YBLocationPickerViewController *picker = [[YBLocationPickerViewController alloc] init];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self presentViewController:nav animated:YES completion:^{ }];
                
                picker.locationSelectBlock = ^(id locationInfo, YBLocationPickerViewController *locationPickController) {
                    NSLog(@"%@",locationInfo);
                    
                    //返回name address pt pt为坐标
                    double LONGITUDE = [locationInfo[@"LONGITUDE"] doubleValue];
                    double LATITUDE = [locationInfo[@"LATITUDE"] doubleValue];
                    NSString *address = [NSString stringWithFormat:@"%@（%@附近）",locationInfo[@"pt"], locationInfo[@"address"]];
                    [IOSToVue TellVueSendLocation:weakSelf.webView andAddress:address andLng:LONGITUDE andLat:LATITUDE];
                };
            });
        }
        // 检查更新
        else if([first isEqualToString:@"检查APP和VUE版本更新"]) {
            
            // 检查zip更新
            dispatch_async(dispatch_get_main_queue(), ^{

                [self checkZipVersion];
            });
            
            // 检查AppStore更新
            [XHVersion checkNewVersion];
            
            // 2.如果你需要自定义提示框,请使用下面方法
            [XHVersion checkNewVersionAndCustomAlert:^(XHAppInfo *appInfo) {
                
                NSLog(@"新版本信息:\n 版本号 = %@ \n 更新时间 = %@\n 更新日志 = %@ \n 在AppStore中链接 = %@\n AppId = %@ \n bundleId = %@" ,appInfo.version,appInfo.currentVersionReleaseDate,appInfo.releaseNotes,appInfo.trackViewUrl,appInfo.trackId,appInfo.bundleId);
            } andNoNewVersionBlock:^(XHAppInfo *appInfo) {
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"已经是最新版本" message:@"" delegate:self cancelButtonTitle:@"确定", nil];
                [alertView show];
#endif
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经是最新版本" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }]];
                [self presentViewController:alert animated:YES completion:nil];
#endif
            }];
        }
        NSLog(@"js传ios：%@   %@   %@   %@",first, second, third, fourth);
    };
}


#pragma mark 长按手势事件

-(void)longPress:(UILongPressGestureRecognizer *)sender{
    
    __weak __typeof(self)weakSelf = self;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        NSLog(@"打开编辑模式");
        [Tools openWebviewEdit:_webView];
        
        // 开启编辑模式后30秒将关闭
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            usleep(30 * 1000000);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"关闭编辑模式");
                [Tools closeWebviewEdit:weakSelf.webView];
            });
        });
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

// 查看路线
- (void)showLocLine:(NSString *)shipmentId andShipmentCode:(NSString *)shipmentCode andShipmentStatus:(NSString *)shipmentStatus {
    
    CheckOrderPathViewController *vc = [[CheckOrderPathViewController alloc] init];
    vc.orderIDX = shipmentId;
    vc.shipmentCode = shipmentCode;
    vc.shipmentStatus = shipmentStatus;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - iOS 10 联系人选择

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty{
    
    NSString *givenName = contactProperty.contact.givenName;
    NSString *familyName = contactProperty.contact.familyName;
    NSString *fullName = [NSString stringWithFormat:@"%@%@", givenName, familyName];
    
    NSString *tel = [contactProperty.value stringValue];
    tel = [tel stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    [IOSToVue TellVueContactPeople:self.webView andAddress:fullName andLng:tel];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - iOS 10以下 联系人选择

// 选择联系人某个属性时调用（展开详情）
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    CFStringRef lastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString *fir = CFBridgingRelease(firstName);
    NSString *las = CFBridgingRelease(lastName);
    
    NSString *fullName = [NSString stringWithFormat:@"%@%@", las ? las : @"", fir ? fir : @""];
    
    ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSString *tel = (__bridge_transfer NSString *)  ABMultiValueCopyValueAtIndex(multi, identifier);
    tel = [tel stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    [IOSToVue TellVueContactPeople:self.webView andAddress:fullName andLng:tel];
    
    NSLog(@"");
}

// 导航
- (void)navigationOnclick:(double)lat andLng:(double)lng andAddress:(NSString *)address {
    
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        CLLocationCoordinate2D clBaidu = CLLocationCoordinate2DMake(lat, lng);
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&&poiname=%@&poiid=BGVIS&lat=%f&lon=%f&dev=0&style=2", @"配货易订单", address, clBaidu.latitude, clBaidu.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        // 高德转百度坐标
        CLLocationCoordinate2D clGaode = CLLocationCoordinate2DMake(lat, lng);
        CLLocationCoordinate2D clBaidu = [self gaoDeToBd:clGaode];
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString =[[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=%@&mode=driving&coord_type=gcj02", clBaidu.latitude, clBaidu.longitude, @""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%@&directionsmode=driving",@"导航测试",@"nav123456", address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    //选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil])];
    
    NSInteger index = maps.count;
    
    for (int i = 0; i < index; i++) {
        
        NSString * title = maps[i][@"title"];
        
        //苹果原生地图方法
        if (i == 0) {
            
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                // 起点
                MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
                
                // 终点
                CLGeocoder *geo = [[CLGeocoder alloc] init];
                [geo geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                    
                    CLPlacemark *endMark=placemarks.firstObject;
                    MKPlacemark *mkEndMark=[[MKPlacemark alloc]initWithPlacemark:endMark];
                    MKMapItem *endItem=[[MKMapItem alloc]initWithPlacemark:mkEndMark];
                    NSDictionary *dict=@{
                                         MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                                         MKLaunchOptionsMapTypeKey:@(0),
                                         MKLaunchOptionsShowsTrafficKey:@(YES)
                                         };
                    [MKMapItem openMapsWithItems:@[currentLocation,endItem] launchOptions:dict];
                }];
            }];
            [alert addAction:action];
            
            continue;
        }
        
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        
        [alert addAction:action];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

// 百度地图经纬度转换为高德地图经纬度
- (CLLocationCoordinate2D)bdToGaoDe:(CLLocationCoordinate2D)location {
    
    double bd_lat = location.latitude;
    double bd_lon = location.longitude;
    double PI = 3.14159265358979324 * 3000.0 / 180.0;
    double x = bd_lon - 0.0065, y = bd_lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * PI);
    double theta = atan2(y, x) - 0.000003 * cos(x * PI);
    return CLLocationCoordinate2DMake(z * sin(theta), z * cos(theta));
}

// 高德地图经纬度转换为百度地图经纬度
- (CLLocationCoordinate2D)gaoDeToBd:(CLLocationCoordinate2D)location {
    
    BMKLocationCoordinateType srctype = BMKLocationCoordinateTypeBMK09LL;
    BMKLocationCoordinateType destype = BMKLocationCoordinateTypeWGS84;
    return [BMKLocationManager BMKLocationCoordinateConvert:location SrcType:srctype DesType:destype];
}


#pragma mark - ServiceToolsDelegate

// 开始下载zip
- (void)downloadStart {
    
    if(!_downView) {
        _downView = [[UIView alloc] init];
    }
    [_downView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [_downView setBackgroundColor:RGB(145, 201, 249)];
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).window addSubview:_downView];
    
    _progressView = [[LMProgressView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(((AppDelegate*)([UIApplication sharedApplication].delegate)).window.frame), CGRectGetHeight(((AppDelegate*)([UIApplication sharedApplication].delegate)).window.frame))];
    [_downView addSubview:_progressView];
}

// 下载zip进度
- (void)downloadProgress:(double)progress {
    
    WeakSelf;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.progressView.progress = progress;
    });
}

// 下载zip完成
- (void)downloadCompletion:(NSString *)version andFilePath:(NSString *)filePath {
    
    WeakSelf;
    
    NSLog(@"解压中...");
    NSString *unzipPath = [Tools getUnzipPath];
    BOOL unzip_b = [SSZipArchive unzipFileAtPath:filePath toDestination:unzipPath];
    if(unzip_b) {
        
        NSLog(@"解压完成，开始刷新APP内容...");
    }else {
        
        NSLog(@"解压失败");
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"延迟0.5秒");
        usleep(500000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIViewController *rootViewController = [Tools getRootViewController];
            if([rootViewController isKindOfClass:[ViewController class]]) {
                
                ViewController *vc = (ViewController *)rootViewController;
                [vc addWebView];
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                
                weakSelf.downView.alpha = 0.0f;
            }completion:^(BOOL finished){
                
                [weakSelf.downView removeFromSuperview];
                if(unzip_b) {
                    
                    [Tools setZipVersion:version];
                }else {
                    
                    NSLog(@"zip解压失败，不更新zip版本号");
                }
            }];
            NSLog(@"刷新内容完成");
        });
    });
}

@end
