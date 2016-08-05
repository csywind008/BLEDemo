//
//  logModel.h
//  BluetoothDemo
//
//  Created by xdong on 16/7/20.
//  Copyright © 2016年 xdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface logModel : NSObject
@property (nonatomic, copy)NSString *message;
@property (nonatomic, assign)float cellHeight;

- (instancetype)initWithMessage:(NSString *)text;
@end
