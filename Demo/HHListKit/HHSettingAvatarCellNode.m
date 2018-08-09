//
//  HHSettingAvatarCellNode.m
//  HHListKit
//
//  Created by shellhue on 01/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import "HHSettingAvatarCellNode.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "NSString+HHListKit.h"

@interface HHSettingAvatarCellNode ()
@property (nonatomic) ASImageNode *avatarImageNode;
@property (nonatomic) ASImageNode *rightArrowImageNode;
@property (nonatomic) ASTextNode *nickTextNode;
@property (nonatomic) ASTextNode *wechatNumberTextNode;
@property (nonatomic) ASImageNode *qrCodeImageNode;

@property (nonatomic) ASDisplayNode *topSeparatorLine;
@property (nonatomic) ASDisplayNode *bottomSeparatorLine;
@end

@implementation HHSettingAvatarCellNode
- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticallyManagesSubnodes = YES;
        self.backgroundColor = UIColor.whiteColor;
        _avatarImageNode = ({
            ASImageNode *node = [ASImageNode new];
            node.image = [UIImage imageNamed:@"avatar"];
            node.style.preferredSize = CGSizeMake(50, 50);
            node.cornerRadius = 4.f;
            node.clipsToBounds = YES;

            node;
        });
        
        _rightArrowImageNode = ({
            ASImageNode *node = [ASImageNode new];
            node.image = [UIImage imageNamed:@"rightarrow"];
            node.style.preferredSize = CGSizeMake(15, 15);

            node;
        });
        
        _nickTextNode = ({
            ASTextNode *node = [ASTextNode new];
            node.attributedText = [@"轻墨" hh_toAttributedStringWithConfiguration:^(HHAttributesConfiguration *configuration) {
                configuration.color = UIColor.blackColor;
                configuration.fontSize = 18.f;
            }];
            node;
        });
        
        _wechatNumberTextNode = ({
            ASTextNode *node = [ASTextNode new];
            node.attributedText = [@"微信号：huang342341" hh_toAttributedStringWithConfiguration:^(HHAttributesConfiguration *configuration) {
                configuration.color = UIColor.blackColor;
                configuration.fontSize = 14.f;
            }];
            node;
        });
        
        _qrCodeImageNode = ({
            ASImageNode *node = [ASImageNode new];
            node.image = [UIImage imageNamed:@"qrcode"];
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

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    ASStackLayoutSpec *nickStack = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:4
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStretch
                                      children:@[self.nickTextNode, self.wechatNumberTextNode]];
    nickStack.style.flexGrow = 1.f;
    nickStack.style.flexShrink = 1.f;
    ASStackLayoutSpec *contentStack = [ASStackLayoutSpec
                                       stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                       spacing:8
                                       justifyContent:ASStackLayoutJustifyContentSpaceBetween
                                       alignItems:ASStackLayoutAlignItemsCenter
                                       children:@[self.avatarImageNode, nickStack, self.qrCodeImageNode, self.rightArrowImageNode]];
    ASInsetLayoutSpec *contentInset = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10) child:contentStack];
    ASStackLayoutSpec *mainStack = [ASStackLayoutSpec
                                    stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                    spacing:4
                                    justifyContent:ASStackLayoutJustifyContentStart
                                    alignItems:ASStackLayoutAlignItemsStretch
                                    children:@[self.topSeparatorLine, contentInset, self.bottomSeparatorLine]];
    return mainStack;
}
@end
