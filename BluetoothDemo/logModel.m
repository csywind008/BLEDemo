//
//  logModel.m
//  BluetoothDemo
//
//  Created by xdong on 16/7/20.
//  Copyright © 2016年 xdong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "logModel.h"

@implementation logModel
- (instancetype)initWithMessage:(NSString *)text{
    self.message = text;
    
    self.cellHeight = [self stringHieght:text withfont:14 withwidth:[UIScreen mainScreen].bounds.size.width] - 10;
    return self;
}

- (CGFloat)stringHieght:(NSString *)aString withfont:(CGFloat)fontsize withwidth:(CGFloat)wid
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    [paragraphStyle setLineSpacing:6];
    NSDictionary *dic = @{
                          NSFontAttributeName : [UIFont systemFontOfSize:fontsize],
                          NSParagraphStyleAttributeName : paragraphStyle
                          };
    CGRect r = [aString boundingRectWithSize:CGSizeMake(wid, 2000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil];
    return r.size.height + 5;
}
@end
