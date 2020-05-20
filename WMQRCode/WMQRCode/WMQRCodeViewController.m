
//
//  WMQRCodeViewController.m
//  WMQRCode
//
//  Created by 郑文明 on 16/11/1.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "WMQRCodeViewController.h"
#import "SVProgressHUD.h"


#define kDeviceVersion [[UIDevice currentDevice].systemVersion floatValue]

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kNavbarHeight ((kDeviceVersion>=7.0)? 64 :44 )

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define kSCREEN_MAX_LENGTH (MAX(kScreenWidth, kScreenHeight))
#define kSCREEN_MIN_LENGTH (MIN(kScreenWidth, kScreenHeight))

#define IS_IPHONE4 (IS_IPHONE && kSCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE5 (IS_IPHONE && kSCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE6 (IS_IPHONE && kSCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE6P (IS_IPHONE && kSCREEN_MAX_LENGTH == 736.0)

@import AVFoundation;


@interface WMQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    UILabel * introLab;
    BOOL isLightOn;
    UIButton *mineQRCode;
    UIButton *theLightBtn;
    BOOL hasTheVC;
    BOOL isFirst;
    BOOL isUp;
    int num;
    AVCaptureVideoPreviewLayer *preView;
    AVCaptureDevice *captureDevice;
    NSTimer * timer;


}
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,weak) AVCaptureMetadataOutput *output;
@property (nonatomic,retain) UIImageView *lineIV;
/** 扫描支持的编码格式的数组 */
@property (nonatomic, strong) NSMutableArray * metadataObjectTypes;

@end

@implementation WMQRCodeViewController
- (NSMutableArray *)metadataObjectTypes{
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = [NSMutableArray arrayWithObjects:AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode, nil];
        
        // >= iOS 8
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            [_metadataObjectTypes addObjectsFromArray:@[AVMetadataObjectTypeInterleaved2of5Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypeDataMatrixCode]];
        }
    }
    
    return _metadataObjectTypes;
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:^{
        // [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
    }];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    //[[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
    viewController.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    viewController.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    NSDictionary *attributeDic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:17.0], NSFontAttributeName, nil];
    navigationController.navigationBar.titleTextAttributes = attributeDic;
}
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    ;
    [self dismissViewControllerAnimated:NO completion:^{
        //[[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
    }];
    NSString *stringValue = [self stringFromFileImage:image];
    [self checkQRcode:stringValue];
    
}

- (void)rightBarButtonItemPressed:(UIButton *)sender {
    
    // if (kDeviceVersion<=7.0) {
    // }
    // else {
    // self.detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    // }
    
    UIImagePickerController *pickCtr = [[UIImagePickerController alloc] init];
    pickCtr.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickCtr.delegate= self;
    pickCtr.allowsEditing = NO;
    pickCtr.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil];
    [self presentViewController:pickCtr animated:YES completion:^{
        
    }];
    NSArray *vcs = self.navigationController.viewControllers;
    NSLog(@"vcs = %@",vcs);
}
-(void)initUI{
    isFirst=YES;
    isUp = NO;
    num =0;
    // 自定义导航右按钮
    NSString *name = [@"Resource.bundle" stringByAppendingPathComponent:@"fromPhoto"];
    UIImage *fromPhoto = [UIImage imageNamed:name];
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, fromPhoto.size.width, fromPhoto.size.height);
    [rightButton setImage:fromPhoto forState:UIControlStateNormal];
    [rightButton setImage:fromPhoto forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(rightBarButtonItemPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightButton];

}
- (void)startSessionRightNow:(NSNotification*)notification {
    //[timer resumeTimer];
    [self creatTimer];
    [_session startRunning];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(isFirst)
    {
        [self creatTimer];
        [_session startRunning];
    }
    isFirst=NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self deleteTimer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"startSession" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
#pragma mark - 删除timer
- (void)deleteTimer
{
    if (timer) {
        [timer invalidate];
        timer=nil;
    }
}
#pragma mark - 创建timer
- (void)creatTimer
{
    if (!timer) {
        timer=[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animation) userInfo:nil repeats:YES];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(startSessionRightNow:) name:@"startSession" object:nil];
    if (!isFirst) {
        [self creatTimer];
        [_session startRunning];
    }
}
- (void)viewDidLoad {
    self.navigationItem.title = @"扫一扫";

    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    [super viewDidLoad];

    [self initUI];
    [self setupDevice];
}
-(void)setupDevice{
    //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error;
    //2.用captureDevice创建输入流input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return ;
    }
    
    //创建会话
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];

    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    
    //预览视图
    preView = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    //设置预览图层填充方式
    [preView setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    preView.frame = CGRectMake(kNavbarHeight / 2, kNavbarHeight + 30, self.view.frame.size.width - kNavbarHeight, self.view.frame.size.width - kNavbarHeight);
    [self.view.layer insertSublayer:preView atIndex:0];

 

    
    //输出
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    if ([_session canAddOutput:output]) {
        [_session addOutput:output];
    }
    self.output = output;
    
    NSArray *arrTypes = output.availableMetadataObjectTypes;
    NSLog(@"%@",arrTypes);
    
    if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode] || [_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
        output.metadataObjectTypes = self.metadataObjectTypes;
        // [_session startRunning];
    } else {
        [_session stopRunning];
        //        rightButton.enabled = NO;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"抱歉!" message:@"相机权限被拒绝，请前往设置-隐私-相机启用此应用的相机权限。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        return;
    }
    

    UIImageView *codeFrame = [[UIImageView alloc] initWithFrame:preView.frame];
    codeFrame.contentMode = UIViewContentModeScaleAspectFit;
    NSString *name = [@"Resource.bundle" stringByAppendingPathComponent:@"codeframe"];

    [codeFrame setImage:[UIImage imageNamed:name]];
    [self.view addSubview:codeFrame];
    
    introLab = [[UILabel alloc] initWithFrame:CGRectMake(preView.frame.origin.x, preView.frame.origin.y + preView.frame.size.height, preView.frame.size.width, 40)];
    introLab.numberOfLines = 1;
    introLab.textAlignment = NSTextAlignmentCenter;
    introLab.textColor = [UIColor whiteColor];
    introLab.adjustsFontSizeToFitWidth = YES;
    introLab.text = @"将二维码/条码放入框内，即可自动扫描";
    [self.view addSubview:introLab];
    
    //我的二维码按钮
    mineQRCode = [UIButton buttonWithType:UIButtonTypeCustom];
    mineQRCode.frame = CGRectMake(self.view.frame.size.width / 2 - 100 / 2, introLab.frame.origin.y+introLab.frame.size.height - 5, 100, introLab.frame.size.height);
    [mineQRCode setTitle:@"我的二维码" forState:UIControlStateNormal];
    [mineQRCode setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [mineQRCode addTarget:self action:@selector(showTheQRCodeOfMine:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mineQRCode];
    mineQRCode.hidden = YES;
    
    //theLightBtn
    theLightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
 
    theLightBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 100 / 2, mineQRCode.frame.origin.y + mineQRCode.frame.size.height + 20, 100, introLab.frame.size.height);
    NSString *lightName = [@"Resource.bundle" stringByAppendingPathComponent:@"light"];
    NSString *lightonName = [@"Resource.bundle" stringByAppendingPathComponent:@"lighton"];

    [theLightBtn setImage:[UIImage imageNamed:lightName] forState:UIControlStateNormal];
    [theLightBtn setImage:[UIImage imageNamed:lightonName] forState:UIControlStateSelected];
    [theLightBtn addTarget:self action:@selector(lightOnOrOff:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:theLightBtn];
    
    if (![captureDevice isTorchAvailable]) {
        theLightBtn.hidden = YES;
    }
    // Start
    _lineIV = [[UIImageView alloc] initWithFrame:CGRectMake(preView.frame.origin.x, preView.frame.origin.y, preView.frame.size.width, 5)];
    NSString *lineName = [@"Resource.bundle" stringByAppendingPathComponent:@"line"];

    _lineIV.image = [UIImage imageNamed:lineName];
    [self.view addSubview:_lineIV];
    
    
    //开始扫描
    [_session startRunning];
}
//手电筒🔦的开和关
- (void)lightOnOrOff:(UIButton *)sender {
    sender.selected = !sender.selected;
    isLightOn = 1 - isLightOn;
    if (isLightOn) {
        [self turnOnLed:YES];
    }else {
        [self turnOffLed:YES];
    }
}

//打开手电筒
- (void) turnOnLed:(bool)update {
    [captureDevice lockForConfiguration:nil];
    [captureDevice setTorchMode:AVCaptureTorchModeOn];
    [captureDevice unlockForConfiguration];
}
//关闭手电筒
- (void) turnOffLed:(bool)update {
    [captureDevice lockForConfiguration:nil];
    [captureDevice setTorchMode: AVCaptureTorchModeOff];
    [captureDevice unlockForConfiguration];
}
- (void)showTheQRCodeOfMine:(UIButton *)sender {
    NSLog(@"showTheQRCodeOfMine");
}
- (void)animation {    
    if (isUp == NO) {
        num ++;
        _lineIV.frame = CGRectMake(preView.frame.origin.x, preView.frame.origin.y + 2 * num, preView.frame.size.width, 5);
         if (2 * num >= preView.frame.size.height) {
             isUp = YES;
        }
    }else {
        num --;
        _lineIV.frame = CGRectMake(preView.frame.origin.x, preView.frame.origin.y + 2 * num, preView.frame.size.width, 5);
        if (num == 0) {
            isUp = NO;
        }
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            NSLog(@"stringValue = %@",metadataObj.stringValue);
            [self checkQRcode:metadataObj.stringValue];
        }else{
            NSLog(@"stringValue = %@",metadataObj.stringValue);
            [self checkQRcode:metadataObj.stringValue];
            
        }
    }
    [_session stopRunning];
    [self performSelector:@selector(startReading) withObject:nil afterDelay:0.5];
}

-(void)startReading{
    [_session startRunning];
}
-(void)stopReading{
    [_session stopRunning];
}
/**
 * 判断二维码
 */
- (void)checkQRcode:(NSString *)str{
    
    if (str.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"找不到二维码" message:@"导入的图片里并没有找到二维码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([str hasPrefix:@"http"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    }else{
        //弹出一个view显示二维码内容
        [SVProgressHUD showInfoWithStatus:str];
    }
    [SVProgressHUD dismissWithDelay:1.0];

}
/**
 * 将二维码图片转化为字符
 */
- (NSString *)stringFromFileImage:(UIImage *)img{
    int exifOrientation;
    switch (img.imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh }; // TODO: read doc for more tuneups
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:detectorOptions];
    
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:img.CGImage]];
    
    CIQRCodeFeature * qrStr  = (CIQRCodeFeature *)features.firstObject;
    //只返回第一个扫描到的二维码
    return qrStr.messageString;
}
-(void)dealloc{
    NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
