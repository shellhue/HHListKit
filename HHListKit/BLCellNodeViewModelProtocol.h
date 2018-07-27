//
//  BLCellNodeViewModelProtocol.h
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//

@class BLBaseCellNode;
NS_ASSUME_NONNULL_BEGIN
@protocol BLCellNodeViewModelProtocol;
typedef void (^BLCellNodeTapAction)(__kindof UIViewController *contextVC, id <BLCellNodeViewModelProtocol> model);

@protocol BLCellNodeViewModelProtocol <NSObject>

@optional
@property (nonatomic, readonly) BLBaseCellNode *cellNode;
@property (nullable, nonatomic, copy, readonly) BLCellNodeTapAction tapAction;
@property (nonatomic, weak) id cellNodeDelegate;

@end
NS_ASSUME_NONNULL_END
