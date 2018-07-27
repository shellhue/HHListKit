//
//  BLBaseCellNode.h
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//

#import "ASCellNode.h"
#import "BLCellNodeViewModelProtocol.h"
@interface BLCellNode : ASCellNode
@property (nonatomic) BOOL isLastCell;
@property (nonatomic) BOOL isFirstCell;
@end

@interface BLBaseCellNode : BLCellNode

/**
 *最近一次点击按下的位置，广告上报用
 */
@property (nonatomic) CGPoint lastTouchDownPosition;

/**
 *最近一次点击松手的位置，广告上报用
 */
@property (nonatomic) CGPoint lastTouchUpPosition;

- (void)configureWithModel:(id <BLCellNodeViewModelProtocol>)model;
@end
