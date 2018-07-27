//
//  BLPlaceholderCellNodeModel.h
//  BLKit
//
//  Created by 黄泽宇 on 16/03/2018.
//

#import "BLCellNodeViewModelProtocol.h"
#import "BLBaseCellNode.h"
NS_ASSUME_NONNULL_BEGIN
typedef void (^BLCellNodeViewModelTapAction)(void);
typedef BLBaseCellNode * _Nonnull(^BLCellNodeCreatorBlock)(void);

@interface BLCellNodeViewModel : NSObject <BLCellNodeViewModelProtocol>
@property (nonatomic, weak) id cellNodeDelegate;

/**
 通过cellNode创建view model
 适合cellNode创建后，没有数据更新的情景
 
 tap action中注意循环引用

 @param cellNode view model所对应的cell node
 @param tapAction cell node的点击响应
 */
- (instancetype)initWithCellNode:(BLBaseCellNode *)cellNode
                       tapAction:(nullable BLCellNodeViewModelTapAction)tapAction;

/**
 通过cellNodeBlock创建view model
 适合cellNode创建后，还会有数据更新的情景
 
 cellNodeCreatorBlock和tap action中注意循环引用
 
 @param cellNodeCreatorBlock view model所对应的cell node creator block
 @param tapAction cell node的点击响应
 */
- (instancetype)initWithCellNodeBlock:(BLCellNodeCreatorBlock)cellNodeCreatorBlock
                            tapAction:(nullable BLCellNodeViewModelTapAction)tapAction;
@end

@interface BLSectionPlaceholderModel: NSObject <BLCellNodeViewModelProtocol>

@end
NS_ASSUME_NONNULL_END
