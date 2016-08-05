//
//  BLEManager.m
//  BluetoothDemo
//
//  Created by xdong on 16/7/12.
//  Copyright © 2016年 xdong. All rights reserved.
//

#define DEVICE_CONNECTION_TIMEOUT   (10)

#import "BLEManager.h"
@interface BLEManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

@end

@implementation BLEManager

+ (id)sharedManager {
    static BLEManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init])
    {
        self.centerManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.perpherralList = [[NSMutableArray alloc] init];
        self.serviceList = [[NSMutableArray alloc] init];
    }
    return self;
}

// 开始扫描设备
- (void)startScanning{
    
    if((NSInteger)[_centerManager state] == CBCentralManagerStatePoweredOn){
        /*
         第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
         - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
         */
        NSDictionary *options=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        [_centerManager scanForPeripheralsWithServices:nil options:options];
    }
}

// 停止扫描
- (void)stopScanning{
    [_centerManager stopScan];
}

- (void)disConnect{
    if (_myPerpherral) {
        [_centerManager cancelPeripheralConnection:_myPerpherral];
    }
}

- (CBCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid{
    if (_myService && _myService.characteristics) {
        for (CBCharacteristic *characteristic in _myService.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:uuid]) {
                return characteristic;
            }
        }
    }
    return nil;
}

- (void) connectPeripheral:(CBPeripheral*)peripheral CompletionBlock:(void (^)(BOOL success, NSError *error))completionHandler
{
    if((NSInteger)[_centerManager state] == CBCentralManagerStatePoweredOn)
    {
        _connectHandler = completionHandler;
        
        if ([peripheral state] == CBPeripheralStateDisconnected){
            [_centerManager connectPeripheral:peripheral options:nil];
        }else{
            [_centerManager cancelPeripheralConnection:peripheral];
        }
        
        [self performSelector:@selector(timeOutMethodForConnect) withObject:nil afterDelay:DEVICE_CONNECTION_TIMEOUT];
    }
}

-(void)cancelTimeOutAlert
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOutMethodForConnect) object:nil];
}

-(void)timeOutMethodForConnect
{
    _isTimeOutAlert = YES;
    [self cancelTimeOutAlert];
    [self disconnectPeripheral:_myPerpherral];
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"连接超时" forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:@"" code:100 userInfo:errorDetail];
    _connectHandler(NO,error);
}

- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
    if(peripheral)
    {
        [_centerManager cancelPeripheralConnection:peripheral];
    }
}

- (void) clearDevices{
    [_perpherralList removeAllObjects];
    [_serviceList removeAllObjects];
    _myPerpherral = nil;
    _myService = nil;
    _myCharacteristic = nil;
}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前两个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     */
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSString *text = [NSString stringWithFormat:@"该字段不可写！"];
        [_discoveryDelegate logMessage:text];
    }
}

-(void)peripheralWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![_perpherralList containsObject:peripheral]) {
        
        NSString *bleName = nil;
        if ([advertisementData valueForKey:CBAdvertisementDataLocalNameKey] != nil)
        {
            bleName = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
        }
        
        NSString *text = [NSString stringWithFormat:@"发现peripheralName:%@,advertisementDataName:%@",peripheral.name,bleName];
        NSLog(@"%@",text);
        
        if (!bleName || [bleName length] < 1) {
            bleName = peripheral.name;
        }
        
        if([bleName isEqualToString:INSULINK_NAME])
        {
            if (peripheral.state != CBPeripheralStateConnected && peripheral.state != CBPeripheralStateConnecting) {
                NSString *text = [NSString stringWithFormat:@"发现%@",peripheral.name];
                NSLog(@"%@",text);
                [_discoveryDelegate logMessage:text];
                
                [_perpherralList addObject:peripheral];
                [self connectPeripheral:peripheral CompletionBlock:^(BOOL success, NSError *error) {
                    if (success) {
                    }else{
                        if (error) {
                            NSString *text = [NSString stringWithFormat:@"连接失败--原因:%@",error.localizedDescription];
                            [_discoveryDelegate logMessage:text];
                            [self clearDevices];
                            // 连接失败或断开连接继续扫描进行重连
                            [self startScanning];
                        }
                    }
                }];
                [_discoveryDelegate didDiscoveryPeripheral];
            }
        }
    }
}

#pragma mark CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    // 扫描到设备
    [self peripheralWithPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    _myPerpherral = peripheral;
    _myPerpherral.delegate = self;

    //连接外设成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [_myPerpherral discoverServices:nil];
    NSString *text = [NSString stringWithFormat:@"成功连接%@",peripheral.name];
    [_discoveryDelegate logMessage:text];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self cancelTimeOutAlert];
    _connectHandler(NO,error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self cancelTimeOutAlert];
    
    /*  Check whether the disconnection is done by the device */
    if (error == nil && !_isTimeOutAlert)
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"deviceDisconnectedAlert" forKey:NSLocalizedDescriptionKey];
        NSError *disconnectError = [NSError errorWithDomain:@"" code:100 userInfo:errorDetail];
        _connectHandler(NO,disconnectError);
    }
    else
    {
        _isTimeOutAlert = NO;
        _connectHandler(NO,error);
    }
    [self clearDevices];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
            
        case CBCentralManagerStateUnknown:
            
            break;
            
        case CBCentralManagerStateUnsupported:
            
            break;
            
        case CBCentralManagerStateUnauthorized:
            
            break;
            
        case CBCentralManagerStatePoweredOff:
        {
            NSString *text = [NSString stringWithFormat:@"蓝牙处于关闭状态"];
            [_discoveryDelegate logMessage:text];
        }
            break;
            
        case CBCentralManagerStateResetting:
            
            break;
            
        case CBCentralManagerStatePoweredOn:
        {
            NSString *text = [NSString stringWithFormat:@"蓝牙已开启"];
            [_discoveryDelegate logMessage:text];
            // 如果蓝牙是开启的,立即开始扫描
            [self startScanning];
        }
            
            break;
    }
}

#pragma mark CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    [self cancelTimeOutAlert];
    if(error == nil)
    {
        for (CBService *service in peripheral.services)
        {
            if (![_serviceList containsObject:service]) {
                [_serviceList addObject:service];
                //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
                [_myPerpherral discoverCharacteristics:nil forService:service];
                _connectHandler(YES,nil);
            }
        }
    }
    else
    {
        _connectHandler(NO,error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error == nil) {
        _connectHandler(YES,nil);
        if ([_characteristicManagerDelegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
            [_characteristicManagerDelegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([_characteristicManagerDelegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)])
        [_characteristicManagerDelegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([_characteristicManagerDelegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)])
        [_characteristicManagerDelegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([_characteristicManagerDelegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)])
        [_characteristicManagerDelegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    if ([_characteristicManagerDelegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
        [_characteristicManagerDelegate peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
    }
}

@end
