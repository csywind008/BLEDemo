//
//  RootViewController.m
//  BluetoothDemo
//
//  Created by xdong on 16/6/12.
//  Copyright © 2016年 xdong. All rights reserved.
//

#import "RootViewController.h"
#import "CenterViewController.h"
#import "PeripheralViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeCustom];
    scanButton.frame = CGRectMake((screenWidth - 180) / 2, 100, 180, 50);
    [scanButton setTitle:@"连接外设" forState:UIControlStateHighlighted];
    [scanButton setTitle:@"连接外设" forState:UIControlStateNormal];
    [scanButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [scanButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [scanButton addTarget:self action:@selector(center) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanButton];
    
    UIButton *disConnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    disConnectButton.frame = CGRectMake((screenWidth - 180) / 2, 250, 180, 50);
    [disConnectButton setTitle:@"本机作为外设" forState:UIControlStateHighlighted];
    [disConnectButton setTitle:@"本机作为外设" forState:UIControlStateNormal];
    [disConnectButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [disConnectButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [disConnectButton addTarget:self action:@selector(peripheral) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:disConnectButton];

    // Do any additional setup after loading the view.
}

- (void)center{
    CenterViewController *viewVC = [[CenterViewController alloc] init];
    [self.navigationController pushViewController:viewVC animated:YES];
}

- (void)peripheral{
    PeripheralViewController *peripheral = [[PeripheralViewController alloc] init];
    [self.navigationController pushViewController:peripheral animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
