//
//  ServiceTools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ServiceTools.h"
#import <AFNetworking.h>
#import "Tools.h"
#import "AppDelegate.h"
#import "IOSToVue.h"
#import "ViewController.h"

@interface ServiceTools()

@property (strong, nonatomic) AppDelegate *app;

@property (strong, nonatomic) UIWebView *webview;

@end;

@implementation ServiceTools

- (instancetype)init {
    
    if(self = [super init]) {
        
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)queryAppVersion {
    
    WeakSelf;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        while (1) {
            
            if([Tools getServerAddress]) {
                
                NSString *url = [NSString stringWithFormat:@"%@%@", [Tools getServerAddress], @"queryAppVersion.do"];
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
                NSString *params = @"{\"tenantCode\":\"KDY\"}";
                NSDictionary *parameters = @{@"params" : params};
                NSLog(@"接口:%@|zip检测参数：%@", url, parameters);
                
                [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                    nil;
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    NSLog(@"请求成功---%@", responseObject);
                    int status = [responseObject[@"status"] intValue];
                    NSString *Msg = responseObject[@"Msg"];
                    if(status == 1) {
                        
                        NSDictionary *dict = responseObject[@"data"];
                        NSString *server_zipVersion = dict[@"zipVersionNo"];
                        NSString *currZipVersion = [Tools getZipVersion];
                        int c = [Tools compareVersion:server_zipVersion andLocati:currZipVersion];
                        if(c == 1) {
                        
                            // 设置 webView 为 nil，解决UIWebview调用reload导致JSContext失效的问题
                            UIViewController *rootViewController = [Tools getRootViewController];
                            if([rootViewController isKindOfClass:[ViewController class]]) {
                                
                                ViewController *vc = (ViewController *)rootViewController;
                                [vc.webView removeFromSuperview];
                                vc.webView = nil;
                            }
                            NSString *server_zipDownloadUrl = dict[@"zipDownloadUrl"];
                            NSLog(@"更新zip...");
                            
                            if([weakSelf.delegate respondsToSelector:@selector(downloadStart)]) {
                                [weakSelf.delegate downloadStart];
                            }
                            [self downZip:server_zipDownloadUrl andVersion:server_zipVersion];
                        }
                    }else {
                        if([weakSelf.delegate respondsToSelector:@selector(failureOfLogin:)]) {
                            [weakSelf.delegate failureOfLogin:Msg];
                        }
                    }
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"请求失败---%@", error);
                    if([weakSelf.delegate respondsToSelector:@selector(failureOfLogin:)]) {
                        
                        [weakSelf.delegate failureOfLogin:@"请求失败"];
                    }
                }];
                break;
            }else {
                
                NSLog(@"服务器地址为空，延迟1秒访问zip版本接口");
                sleep(1);
            }
        }
    });
}

- (void)downZip:(NSString *)urlStr andVersion:(NSString *)version {
    
    WeakSelf;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    // 需要删除文件的物理地址
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *path = [NSString stringWithFormat:@"%@/dist.zip", paths.firstObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDelete = [fileManager removeItemAtPath:path error:nil];
    if (isDelete) {
        
        // 删除文件成功
        NSLog(@"删除文件成功");
    }else{
       
        // 删除文件失败
        NSLog(@"删除文件失败");
    }
    
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if([self.delegate respondsToSelector:@selector(downloadProgress:)]) {
            
            [weakSelf.delegate downloadProgress:downloadProgress.fractionCompleted];
        }
    }  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"File downloaded to: %@", filePath);
        if([weakSelf.delegate respondsToSelector:@selector(downloadCompletion:andFilePath:)]) {
            
            [weakSelf.delegate downloadCompletion:version andFilePath:filePath.path];
        }
    }];
    [downloadTask resume];
}

@end
