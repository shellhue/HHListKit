//
//  BLPlaceholderCellNodeModel.m
//  BLKit
//
//  Created by 黄泽宇 on 16/03/2018.
//

#import "BLCellNodeViewModel.h"
@interface BLCellNodeViewModel ()
@property (nonatomic) BLBaseCellNode *cellNode;
@property (nullable, copy) BLCellNodeViewModelTapAction simpleTapAction;
@property (nullable, copy) BLCellNodeCreatorBlock cellNodeCreator;

@end

@implementation BLCellNodeViewModel
- (instancetype)initWithCellNode:(BLBaseCellNode *)cellNode
                       tapAction:(BLCellNodeViewModelTapAction)tapAction {
    self = [super init];
    if (self) {
        _simpleTapAction = tapAction;
        _cellNode = cellNode;
    }
    return self;
}

- (instancetype)initWithCellNodeBlock:(BLCellNodeCreatorBlock)cellNodeCreatorBlock
                            tapAction:(nullable BLCellNodeViewModelTapAction)tapAction {
    self = [super init];
    if (self) {
        _cellNodeCreator = cellNodeCreatorBlock;
        _simpleTapAction = tapAction;
    }
    
    return self;
}

- (BLCellNodeTapAction)tapAction {
    BLCellNodeViewModel * __weak weakSelf = self;
    return ^(UIViewController *contextVC, id <BLCellNodeViewModelProtocol> cmodel) {
        BLCellNodeViewModel *strongSelf = weakSelf;
        if (strongSelf.simpleTapAction) {
            strongSelf.simpleTapAction();
        }
    };
}

- (BLBaseCellNode *)cellNode {
    if (_cellNode) {
        return _cellNode;
    } else if (self.cellNodeCreator) {
        return self.cellNodeCreator();
    }
    return nil;
}
@end

@implementation BLSectionPlaceholderModel
@end
