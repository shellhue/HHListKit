//
//  HHSettingCommonCellNode.m
//  HHListKit
//
//  Created by shellhue on 02/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import "HHSettingCommonCellNode.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "HHSettingCommonModel.h"
#import "NSString+HHListKit.h"

@interface HHSettingCommonCellNode ()
@property (nonatomic) ASImageNode *iconImageNode;
@property (nonatomic) ASTextNode *nameTextNode;
@property (nonatomic) ASImageNode *rightArrowImageNode;

@property (nonatomic) ASDisplayNode *topSeparatorLine;
@property (nonatomic) ASDisplayNode *bottomSeparatorLine;
@end

@implementation HHSettingCommonCellNode
- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticallyManagesSubnodes = YES;
        self.backgroundColor = UIColor.whiteColor;
        _iconImageNode = ({
            ASImageNode *node = [ASImageNode new];
            node.style.preferredSize = CGSizeMake(25, 25);
            
            node;
        });
        
        _nameTextNode = ({
            ASTextNode *node = [ASTextNode new];

            node;
        });
        
        _rightArrowImageNode = ({
            ASImageNode *node = [ASImageNode new];
            node.image = [UIImage imageNamed:@"rightarrow"];
            node.style.preferredSize = CGSizeMake(15, 15);
            
            node;
        });

        _topSeparatorLine = ({
            ASDisplayNode *node = [ASDisplayNode new];
            node.backgroundColor = [UIColor colorWithRed:220.f / 255.f green:220.f / 255.f blue:220.f / 255.f alpha:1];
            node.style.height = ASDimensionMake(0.5);
            
            node;
        });
        
        _bottomSeparatorLine = ({
            ASDisplayNode *node = [ASDisplayNode new];
            node.backgroundColor = [UIColor colorWithRed:220.f / 255.f green:220.f / 255.f blue:220.f / 255.f alpha:1];
            node.style.height = ASDimensionMake(0.5);
            
            node;
        });
    }
    return self;
}

- (void)hh_configureWithModel:(HHSettingCommonModel *)model {
    self.iconImageNode.image = [UIImage imageNamed:model.iconName];
    self.nameTextNode.attributedText = [model.name hh_toAttributedStringWithConfiguration:^(HHAttributesConfiguration *configuration) {
        configuration.fontSize = 16.f;
        configuration.color = UIColor.blackColor;
    }];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    self.nameTextNode.style.flexGrow = 1.f;
    self.nameTextNode.style.flexShrink = 1.f;
    ASStackLayoutSpec *contentStack = [ASStackLayoutSpec
                                       stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                       spacing:8
                                       justifyContent:ASStackLayoutJustifyContentSpaceBetween
                                       alignItems:ASStackLayoutAlignItemsCenter
                                       children:@[self.iconImageNode, self.nameTextNode, self.rightArrowImageNode]];
    ASInsetLayoutSpec *contentInset = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5, 20, 5, 10) child:contentStack];
    NSMutableArray *children = @[].mutableCopy;
    if (self.isFirstCell) {
        [children addObject:self.topSeparatorLine];
    }
    [children addObject:contentInset];
    if (self.isLastCell) {
        [children addObject:self.bottomSeparatorLine];
    } else {
        [children addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, 20, 0, 0) child:self.bottomSeparatorLine]];
    }
    ASStackLayoutSpec *mainStack = [ASStackLayoutSpec
                                    stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                    spacing:4
                                    justifyContent:ASStackLayoutJustifyContentStart
                                    alignItems:ASStackLayoutAlignItemsStretch
                                    children:children];
    return mainStack;
}
@end
