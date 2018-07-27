//
//  BLBaseCellNode.m
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <UIKit/UIKit.h>
#import "BLBaseCellNode.h"
@implementation BLCellNode

@end

@interface BLBaseCellNode () <UIGestureRecognizerDelegate>
@end

@implementation BLBaseCellNode

- (void)didLoad {
    [super didLoad];

    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    gr.cancelsTouchesInView = NO;
    gr.delegate = self;
    [self.view addGestureRecognizer:gr];
}

- (void)tapped:(UIGestureRecognizer *)gr {
    CGPoint point = [gr locationInView:self.view];
    point = CGPointMake(floor(point.x), floor(point.y));
    self.lastTouchUpPosition = point;
    self.lastTouchDownPosition = point;
}

- (void)configureWithModel:(id)model {
    
}
@end
