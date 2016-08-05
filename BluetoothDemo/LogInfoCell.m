//
//  LogInfoCell.m
//  BluetoothDemo
//
//  Created by xdong on 16/7/20.
//  Copyright © 2016年 xdong. All rights reserved.
//

#import "LogInfoCell.h"

@implementation LogInfoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView{
    self.label = [[UILabel alloc] init];
    _label.textColor = [UIColor blueColor];
    _label.font = [UIFont systemFontOfSize:14];
    _label.numberOfLines = 0;
    [self.contentView addSubview:_label];
}

- (void)layoutSubviews{
    _label.frame = CGRectMake(5, 0, self.contentView.frame.size.width - 10, self.contentView.frame.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
