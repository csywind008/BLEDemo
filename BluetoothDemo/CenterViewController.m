//
//  CenterViewController.m
//  BluetoothDemo
//
//  Created by xdong on 16/6/12.
//  Copyright © 2016年 xdong. All rights reserved.
//

/*
 * 功能说明:连接外设设备
 */

#import "CenterviewController.h"
#import "PeripheralViewController.h"
#import "BLEManager.h"
#import "logModel.h"
#import "LogInfoCell.h"

@interface CenterViewController ()<BLEDiscoveryDelegate,BLECharacteristicManagerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic ,strong) UITableView *table;
@property (nonatomic ,strong) NSMutableArray *logArray;
@property (nonatomic ,strong) BLEManager *manager;
@property (nonatomic ,assign) unsigned long indexNum; // 序号
@end

@implementation CenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [[BLEManager sharedManager] init];
    self.logArray = [NSMutableArray array];
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    UIButton *reConnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    reConnectButton.frame = CGRectMake(50, 64, 75, 50);
    [reConnectButton setTitle:@"重新连接" forState:UIControlStateHighlighted];
    [reConnectButton setTitle:@"重新连接" forState:UIControlStateNormal];
    [reConnectButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [reConnectButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [reConnectButton addTarget:self action:@selector(startScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reConnectButton];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    clearButton.frame = CGRectMake(screenWidth - 50 - 75, 64, 75, 50);
    [clearButton setTitle:@"清空" forState:UIControlStateHighlighted];
    [clearButton setTitle:@"清空" forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [clearButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clearButton];
    
    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 64 + 50, screenWidth, screenHeight - 64 - 50)];
    _table.delegate = self;
    _table.dataSource = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_table];
    
    [[BLEManager sharedManager] setDiscoveryDelegate:self];
    [[BLEManager sharedManager] setCharacteristicManagerDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [_manager disConnect];
}

// 重新连接
- (void)startScan{
    [_manager stopScanning];
    
    [_manager clearDevices];
    [_manager startScanning];
//    [_manager.myPerpherral readValueForCharacteristic:[_manager getCharacteristicWithUUID:INSULINK_CHARACTER_TIME]];
}

// 清空
- (void)clearAction{
    [_logArray removeAllObjects];
    [_table reloadData];
}

// 写入时间
- (void)writeTime{
    long long time = [[NSDate date] timeIntervalSince1970];
    NSString *timeStr = [self ToHex:time];
    NSData *data = [self hexToBytes:timeStr];
    NSString *text = [NSString stringWithFormat:@"写入时间:%@",[self getFullStringFromDate:time]];
    [self logHandleWithMessage:text];
    [_manager writeCharacteristic:_manager.myPerpherral characteristic:[_manager getCharacteristicWithUUID:INSULINK_CHARACTER_TIME] value:data];
}

/**
 *  读取数据
 *  数据长度6字节,第一个字节为序号,第2-5个字节为时间戳,最后一个字节为值
 *  @param str 16进制字符串
 */
- (void)readData:(NSString *)str{
    NSString *indexStr = [str substringWithRange:NSMakeRange(0, 2)];
    NSString *timeStr = [str substringWithRange:NSMakeRange(2, 8)];
    NSString *valueStr = [str substringWithRange:NSMakeRange(10, 2)];
    _indexNum = strtoul([indexStr UTF8String], 0, 16);
    long long time = [self readTime:timeStr];
    unsigned long value = strtoul([valueStr UTF8String], 0, 16);
    NSString *text = [NSString stringWithFormat:@"数据(%ld):%ld,%@",_indexNum,value,[self getFullStringFromDate:time]];
    [self logHandleWithMessage:text];
    
    if (indexStr) {
        // 回传序号
        NSString *index = [self ToHex:_indexNum];
        NSData *data = [self hexToBytes:index];
        [_manager writeCharacteristic:_manager.myPerpherral characteristic:[_manager getCharacteristicWithUUID:INSULINK_CHARACTER_RESPONSE] value:data];
    }
}

// 读取时间
- (long long)readTime:(NSString *)str{
    
    NSString *timeHexStr = @"";
    // 传过来的是逆序的,需要调整再转换
    for (int i = (int)str.length - 2; i >= 0; i -= 2) {
        NSString *temp = [str substringWithRange:NSMakeRange(i, 2)];
        timeHexStr = [timeHexStr stringByAppendingString:temp];
    }
    
    long long result = strtoul([timeHexStr UTF8String], 0, 16);
//    NSLog(@"读取到时间:%@",[self getFullStringFromDate:result]);
    return result;
}

- (NSString *)getFullStringFromDate:(long long)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:date];
    return dateStr;
}

// 16进制字符串转为NSData
- (NSData *)hexToBytes:(NSString *)str
{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = (int)str.length - 2; idx >= 0; idx-=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [str substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

// 10进制转为16进制字符串
- (NSString *)ToHex:(long long)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    //不够一个字节凑0
    if(str.length == 1){
        return [NSString stringWithFormat:@"0%@",str];
    }else{
        return str;
    }
}

#pragma mark discoveryDelegate
- (void)didDiscoveryPeripheral{
//    [_table reloadData];
}

- (void)logMessage:(NSString *)text{
    [self logHandleWithMessage:text];
}

// 输出log
- (void)logHandleWithMessage:(NSString *)text{
    
    if (_logArray.count > 200) {
        [_logArray removeObjectsInRange:NSMakeRange(0, 100)];
        [_table reloadData];
    }
    
    if ([text isEqualToString:@""]) {
        return;
    }
    logModel *model = [[logModel alloc] initWithMessage:text];
    if (model) {
        NSLog(@"%@",text);
        [_logArray addObject:model];
        [_table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(_logArray.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [_table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(_logArray.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark BLECharacteristicManagerDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [[BLEManager sharedManager] setMyService:service];
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSString *text = [NSString stringWithFormat:@"发现特征 uuid:%@",characteristic.UUID];
        [self logHandleWithMessage:text];
        
        if ([characteristic.UUID.UUIDString isEqualToString:INSULINK_CHARACTER_INSULINK]) {
            [self writeTime];
            [_manager notifyCharacteristic:peripheral characteristic:characteristic];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *str = [NSString stringWithFormat:@"%@",characteristic.value];
    str = [[[str stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([characteristic.UUID.UUIDString isEqualToString:INSULINK_CHARACTER_INSULINK]) {
        // 读取序号,时间,剂量
        [self readData:str];
    }else if ([characteristic.UUID.UUIDString isEqualToString:INSULINK_CHARACTER_TIME]){
        // 只读取时间
        [self readTime:str];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *text = @"";
    if ([characteristic.UUID.UUIDString isEqualToString:INSULINK_CHARACTER_RESPONSE]) {
        if (error == nil) {
            text = [NSString stringWithFormat:@"序号回传成功"];
        }else{
            text = [NSString stringWithFormat:@"序号回传失败,原因:%@",error.localizedDescription];
        }
    }else if ([characteristic.UUID.UUIDString isEqualToString:INSULINK_CHARACTER_TIME]){
        if (error == nil) {
            text = [NSString stringWithFormat:@"时间写入成功"];
        }else{
            text = [NSString stringWithFormat:@"时间写入失败,原因:%@",error.localizedDescription];
        }
    }
    [self logHandleWithMessage:text];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableView-DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _logArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"cell";
    LogInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[LogInfoCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    logModel *model = _logArray[indexPath.row];
    cell.label.text = model.message;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    logModel *model = _logArray[indexPath.row];
    return model.cellHeight;
}

@end

