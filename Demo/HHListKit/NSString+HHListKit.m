//
//  NSString+HHListKit.m
//  HHListKit
//
//  Created by shellhue on 01/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import "NSString+HHListKit.h"

@implementation HHAttributesConfiguration
- (instancetype)init {
    self = [super init];
    if (self) {
        _fontSize = 14.f;
        _isBold = NO;
        _color = UIColor.blackColor;
        _lineSpacing = 0.f;
        _alignment = NSTextAlignmentLeft;
        _lineBreakMode = NSLineBreakByCharWrapping;
    }
    
    return self;
}

- (void)check {
    self.fontSize = self.fontSize <= 0 ? 14 : self.fontSize;
    self.color = self.color ?: UIColor.blackColor;
    self.lineSpacing = self.lineSpacing < 0 ? 0.f : self.lineSpacing;
    if (self.alignment != NSTextAlignmentLeft &&
        self.alignment != NSTextAlignmentCenter &&
        self.alignment != NSTextAlignmentRight) {
        self.alignment = NSTextAlignmentLeft;
    }
}

- (UIFont *)font {
    return self.isBold ? [UIFont boldSystemFontOfSize:self.fontSize] :  [UIFont systemFontOfSize:self.fontSize];
}

- (NSParagraphStyle *)paragraphStyle {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = self.alignment;
    style.lineSpacing = self.lineSpacing;
    style.lineBreakMode = self.lineBreakMode;
    style.minimumLineHeight = self.minimumLineHeight;
    return [style copy];
}

- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    [self check];
    return @{
             NSFontAttributeName: [self font],
             NSForegroundColorAttributeName: self.color,
             NSParagraphStyleAttributeName: [self paragraphStyle]
             };
}
@end

@implementation NSString (HHListKit)
- (NSAttributedString *)hh_toAttributedStringWithConfiguration:(HHAttributesConfigurationBlock)configuration {
    HHAttributesConfiguration *attributesConfiguration = [HHAttributesConfiguration new];
    if (configuration) {
        configuration(attributesConfiguration);
    }
    
    return [[NSAttributedString alloc] initWithString:self attributes:[attributesConfiguration attributes]];
}
@end
