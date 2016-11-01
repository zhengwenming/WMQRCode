//
//  ViewController.m
//  WMQRCode
//
//  Created by 郑文明 on 16/11/1.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "ViewController.h"
#import "WMQRCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *centerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    centerBtn.frame = CGRectMake(0, 0, 100, 40);
    centerBtn.backgroundColor = [UIColor redColor];
    [centerBtn addTarget:self action:@selector(scanQrcode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:centerBtn];
    centerBtn.center = self.view.center;
    
}

-(void)scanQrcode{
    [self.navigationController pushViewController:[WMQRCodeViewController new] animated:YES];
}
@end
