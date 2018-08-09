//
//  HHSettingCommonModel.m
//  HHListKit
//
//  Created by shellhue on 02/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import "HHSettingCommonModel.h"
#import "SettingViewController.h"
#import "HHSettingCommonCellNode.h"

@interface HHSettingCommonModel ()
@property (nonatomic, copy) dispatch_block_t tapAction;
@end
@implementation HHSettingCommonModel
- (instancetype)initWithName:(NSString *)name
                    iconName:(NSString *)iconName
                   tapAction:(dispatch_block_t)tapAction {
    self = [super init];
    if (self) {
        self.name = name;
        self.iconName = iconName;
        self.tapAction = tapAction;
    }
    return self;
}

- (HHCellNodeBlock)cellNodeBlock {
    return ^HHCellNode *(SettingViewController *containingVC) {
        return [HHSettingCommonCellNode new];
    };
}

- (HHCellNodeTapAction)cellNodeTapAction {
    return ^(SettingViewController *containingVC) {
        self.tapAction();
    };
}


@end
