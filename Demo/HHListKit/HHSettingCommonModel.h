//
//  HHSettingCommonModel.h
//  HHListKit
//
//  Created by shellhue on 02/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HHCellNodeModelProtocol.h"

@interface HHSettingCommonModel : NSObject <HHCellNodeModelProtocol>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *iconName;

- (instancetype)initWithName:(NSString *)name
                    iconName:(NSString *)iconName
                   tapAction:(dispatch_block_t)tapAction;
@end
