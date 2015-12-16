//
//  ViewController.m
//  shakefun
//
//  Created by zm on 15/9/9.
//  Copyright (c) 2015年 zm. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "CollectViewController.h"
#import "URLEntity.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController
{
    AFURLSessionManager *downloadManager;
    NSURLSessionDownloadTask *downloadTask;
    NSMutableArray *sources;
    int currentIndex;
}
-(void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    sources = [[NSMutableArray alloc]init];
    
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:YES];
    
    [self becomeFirstResponder];
    
    if (!downloadManager) {
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"shakefun_downloadidentifier_%d", 1]];
        [configuration setAllowsCellularAccess:NO];//禁止使用蜂窝网络
        downloadManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        [downloadManager.reachabilityManager startMonitoring];
    }

    [self reloadSources];
    if (sources.count == 0) {
        currentIndex = 0;
    }
    else
    {
        currentIndex =  arc4random() % sources.count;
    }
    
    //[self.webViewBrowser setScalesPageToFit:YES];
    self.automaticallyAdjustsScrollViewInsets = NO;//去除顶部20像素空白条
    //self.webViewBrowser.opaque = NO;

//    CGRect rt = self.webViewBrowser.frame;
//    rt.size.width = self.view.frame.size.width;
    [self.webViewBrowser loadHTMLString:@"<div align=center><font color=#FF0000>Wellcom to ShakeFun! ^_! </font></div>" baseURL:nil];
    self.webViewBrowser.backgroundColor = [UIColor lightGrayColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNofitications:) name:@"shakefun_reload_urls" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNofitications:) name:UIDeviceOrientationDidChangeNotification object:nil];
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"shakefun_reload_urls"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIDeviceOrientationDidChangeNotification];
}
-(void)reloadSources
{
    [sources removeAllObjects];
    NSArray* allurls = [URLEntity MR_findAll];
    for (URLEntity *url in allurls) {
        [sources addObject:url.fullurl];
    }
}
-(void)processNofitications:(NSNotification *)notification
{
    NSLog(@"receive notification:%@", notification.name);
    if ([notification.name isEqualToString:@"shakefun_reload_urls"]) {
        [self reloadSources];
    }
    else if ([notification.name isEqualToString:UIDeviceOrientationDidChangeNotification])
    {
        [self buttonNextToggleWithIndex:currentIndex];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonNextToggle:(id)sender {
    if (sources.count <= 0) {
       UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请先采集数据->[Collect]" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [view show];
    }
    else
    {
        currentIndex = arc4random() % sources.count;
        [self buttonNextToggleWithIndex:currentIndex];
    }
}

- (IBAction)buttonCollectToggle:(id)sender {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CollectViewController* view = [sb instantiateViewControllerWithIdentifier:@"CollectViewController"];
    [self.navigationController pushViewController:view animated:YES];
}



- (void)buttonNextToggleWithIndex:(NSInteger)index {
    
    NSString* docPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileUrl = [sources objectAtIndex:index];
    NSString* file = [NSString stringWithFormat:@"%@/%@", docPath, [fileUrl lastPathComponent]];
    NSURL* url = [NSURL fileURLWithPath:file];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        fileUrl = [url absoluteString];
        //获取宽高
        UIImage *img = [UIImage imageWithContentsOfFile:file];
        //按webview窗口比例缩放
        CGRect rt = self.webViewBrowser.frame;
        //取小的宽度
        CGFloat w = rt.size.width > img.size.width ? img.size.width : rt.size.width;
        w = w - 20;
        CGFloat wh = w / img.size.width;
        NSString *content = [NSString stringWithFormat:@"<div align=center><img width=%f height=%f src=%@></div>", img.size.width * wh, img.size.height * wh, fileUrl];
        [self.webViewBrowser loadHTMLString:content baseURL:nil];
        //self.webViewBrowser.
    }
    else
    {
        //显示正在更新
        [self startDownload:index];
    }
   
}
#pragma shake action
- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    //检测到摇动
    NSLog(@"Go:%s", __FUNCTION__);
}

- (void) motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    //摇动取消
    NSLog(@"Go:%s", __FUNCTION__);
}

- (void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"Go:%s", __FUNCTION__);
    //摇动结束
    if (event.subtype == UIEventSubtypeMotionShake) {
        //something happens
        [self buttonNextToggle:nil];
    }
}

#pragma network
-(void)startDownload:(NSInteger)index
{
    static bool bFirst = YES;
    if (bFirst) {
        NSOperationQueue * operationQueue = downloadManager.operationQueue;//avoid retain cycle
        [downloadManager.reachabilityManager setReachabilityStatusChangeBlock :^ (AFNetworkReachabilityStatus status)
         {
             switch (status) {
                 case AFNetworkReachabilityStatusReachableViaWiFi:
                     NSLog(@"DownloadManager AFNetworkReachabilityStatusReachableViaWiFi");
                     [operationQueue setSuspended:NO];
                     break ;
                 case AFNetworkReachabilityStatusReachableViaWWAN:
                 case AFNetworkReachabilityStatusNotReachable:
                 default:
                     //suspud
                     [operationQueue setSuspended:YES];
                     NSLog(@"DownloadManager AFNetworkReachabilityStatusNotReachable");
                     break ;
             }
             
         }];
        bFirst = NO;
    }

    //下载文件保存位置
    NSString* docPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileUrl = [sources objectAtIndex:index];

    NSString* file = [NSString stringWithFormat:@"%@/%@", docPath, [fileUrl lastPathComponent]];
    NSLog(@"download file name is %@", file);
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        return;
     }
    NSURL *downurl = [NSURL URLWithString:fileUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:downurl];
    
    //监控下载进度，调试用
    NSProgress* progress = [[NSProgress alloc]init];
    //创建下载任务
    [SVProgressHUD showWithStatus:@"摇到一个大家伙，稍等片刻^_!"];
    downloadTask = [downloadManager downloadTaskWithRequest:request
                                           progress:&progress
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
                    {
                        
                        NSLog(@"destination:path=%@ targetPath:%@", file, targetPath);
                        return [NSURL fileURLWithPath:file];
                    }
                                  completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
                    {
                        NSLog(@"File downloaded to: %@ error:%@", filePath, error);
                        if (!error) {
                            
                            downloadTask = nil;
                        }
                        [SVProgressHUD dismiss];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self buttonNextToggleWithIndex:index];
                        });
                    }];
    
    //开始下载
    [downloadTask resume];
    // Observe fractionCompleted using KVO
    [progress addObserver:self
               forKeyPath:@"fractionCompleted"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"] && [object isKindOfClass:[NSProgress class]]) {
        NSProgress *progress = (NSProgress *)object;
        NSLog(@"download progress is %f", progress.fractionCompleted);
        if (progress.fractionCompleted >= 1.0f) {
            //下载完成后，移除观察者
            [progress removeObserver:self forKeyPath:@"fractionCompleted"];
        }
    }
}


@end


@implementation NSString (TMNSStringExtensionMethods)

- (NSArray *)componentsSeparatedFromString:(NSString *)fromString toString:(NSString *)toString
{
    if (!fromString || !toString || fromString.length == 0 || toString.length == 0) {
        return nil;
    }
    NSMutableArray *subStringsArray = [[NSMutableArray alloc] init];
    NSString *tempString = self;
    NSRange range = [tempString rangeOfString:fromString];
    while (range.location != NSNotFound) {
        tempString = [tempString substringFromIndex:(range.location + range.length)];
        range = [tempString rangeOfString:toString];
        if (range.location != NSNotFound) {
            [subStringsArray addObject:[tempString substringToIndex:range.location]];
            range = [tempString rangeOfString:fromString];
        }
        else
        {
            break;
        }
    }
    return subStringsArray;
}

@end