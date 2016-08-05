//
//  BLEManager.h
//  BluetoothDemo
//
//  Created by xdong on 16/7/12.
//  Copyright © 2016年 xdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define INSULINK_NAME                       @"Insulink"
#define INSULINK_SERVICE_UUID               @"D000"
#define INSULINK_CHARACTER_INSULINK         @"D001"
#define INSULINK_CHARACTER_RESPONSE         @"D002"
#define INSULINK_CHARACTER_TIME             @"D003"

typedef void (^ConnectResultHandler)(BOOL success,NSError *error);

@protocol BLEDiscoveryDelegate <NSObject>

- (void) didDiscoveryPeripheral;
- (void) logMessage:(NSString *)text;

//- (void) bluetoothIsAvaliable:(BOOL)isAvaliable;

@end

@protocol BLECharacteristicManagerDelegate <NSObject>

@optional
/*!
 *  @method peripheral:didDiscoverCharacteristicsForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the characteristic(s).
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;

/*!
 *  @method peripheral:didUpdateValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/*!
 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/*!
 *  @method peripheral:didUpdateValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error;

@end

@interface BLEManager : NSObject
@property (nonatomic ,weak) id<BLEDiscoveryDelegate> discoveryDelegate;
@property (nonatomic ,strong) id<BLECharacteristicManagerDelegate> characteristicManagerDelegate;

@property (nonatomic ,strong) CBPeripheral *myPerpherral;  // 当前连接的设备
@property (nonatomic ,strong) CBService	*myService;        // 选择的服务
@property (nonatomic ,strong) CBCharacteristic *myCharacteristic; // 选择的特征
@property (nonatomic ,strong) CBCentralManager *centerManager;
@property (nonatomic ,strong) NSMutableArray *perpherralList; // 扫描到的外设
@property (nonatomic ,strong) NSMutableArray *serviceList;    // 扫描到的服务
@property (nonatomic ,strong) NSMutableArray *characteristicList;   // 特征数组
@property (nonatomic ,strong) NSMutableArray *characteristicProperties;
@property (nonatomic ,strong) NSArray  *characteristicDescriptors;

@property (nonatomic ,copy) ConnectResultHandler connectHandler;
@property (nonatomic ,assign) BOOL isTimeOutAlert;
@property (nonatomic ,assign) int bpmValue;

+ (id)sharedManager;
- (id)init;
- (void)startScanning;
- (void)stopScanning;
- (void)disConnect;
- (void) clearDevices;

- (CBCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid;

- (void) connectPeripheral:(CBPeripheral*)peripheral CompletionBlock:(void (^)(BOOL success, NSError *error))completionHandler;

-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value;

-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic;
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic;
@end
