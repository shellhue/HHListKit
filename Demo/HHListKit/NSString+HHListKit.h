//
//  NSString+HHListKit.h
//  HHListKit
//
//  Created by shellhue on 01/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HHAttributesConfiguration;
typedef void (^HHAttributesConfigurationBlock)(HHAttributesConfiguration *configuration);

@interface HHAttributesConfiguration: NSObject
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) BOOL isBold;
@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) NSTextAlignment alignment;
@property (nonatomic) NSLineBreakMode lineBreakMode;
@property (nonatomic) CGFloat minimumLineHeight;

- (NSDictionary *)attributes;
@end

@interface NSString (HHListKit)
- (NSAttributedString *)hh_toAttributedStringWithConfiguration:(HHAttributesConfigurationBlock)configuration;

@end
