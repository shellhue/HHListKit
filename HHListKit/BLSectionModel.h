//
//  BLSectionModel.h
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//
#import "ASCellNode.h"
#import "BLCellNodeViewModelProtocol.h"
#import "BLModel.h"
#import "BLBaseCellNode.h"
#import "BLCellNodeViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BLSectionModelTapActionBlock)(UIViewController *context, id model, NSIndexPath *indexPath);
typedef BLCellNode * _Nonnull (^BLSectionModelCellNodeCreatorBlock)(id model, NSIndexPath *indexPath);

typedef NS_ENUM(NSUInteger, BLSectionModelFooterHeaderType) {
    // 无footer或header，默认情况
    BLSectionModelFooterHeaderTypeNone = 0,
    // 只是固定高度的占位分割符，需要提供高度和占位符颜色
    BLSectionModelFooterHeaderTypeFixHeightSpacer,
    // 固定高度的node，需要提供node和固定高度
    BLSectionModelFooterHeaderTypeFixHeightNode,
    // 高度自我计算的node，需要提供node
    BLSectionModelFooterHeaderTypeSelfCalculateHeightNode,
};

@interface BLSectionModel <__covariant T> : NSObject
@property (nonatomic, readonly) NSArray<id <BLCellNodeViewModelProtocol>> *models;

/**
 已经显示在屏幕上的models
 */
@property (nonatomic, nullable, copy, readonly) NSArray *shownModels;

/**
 即将同步到屏幕显示的models，同步到UI后，置nil
 */
@property (nonatomic, nullable, copy, readonly) NSArray *toBeSynchronizedModels;

@property (nonatomic) BLSectionModelFooterHeaderType headerType;
@property (nullable, nonatomic) ASCellNode *header;
@property (nonatomic) CGFloat headerHeight;
@property (nonatomic) UIColor *headerSpacerColor;

@property (nonatomic) BLSectionModelFooterHeaderType footerType;
@property (nullable, nonatomic) ASCellNode *footer;
@property (nonatomic) CGFloat footerHeight;
@property (nonatomic) UIColor *footerSpacerColor;

/**
 本section cell node的tap action
 */
@property (nonatomic, nullable, readonly) BLSectionModelTapActionBlock cellNodeTapAction;

/**
 本section的cell node creator
 */
@property (nonatomic, nullable, readonly) BLSectionModelCellNodeCreatorBlock cellNodeCreatorBlock;

#pragma mark - init

/**
 使用本初始化方法，mode 必须实现 BLCellNodeViewModelProtocol 的CellNode方法，
 其他方法可实现可不实现
 
 此方法适用于复杂，有复用页面的实现，如贝聊的推荐feed流，老师端家长端共用，
 而两端cell node的tap action不同，cellNodeCreator不同，model也不同，
 就非常适用该方法
 */
- (instancetype)init;

/**
 使用本方法初始化，model可以不实现BLCellNodeViewModelProtocol的任何方法
 
 注意内存循环引用
 
 此方法适用于简单，无复用页面的实现，如贝聊的推荐feed流，老师端家长端共用，
 cell node的tap action两端不同，cellNodeCreator也不同，就不适用此方法
 */
+ (instancetype)sectionModelWithCellNodeTapAction:(BLSectionModelTapActionBlock _Nullable)tapAction
                             cellNodeCreatorBlock:(BLSectionModelCellNodeCreatorBlock _Nullable)cellNodeCreatorBlock;

#pragma mark - data mutating
- (void)appendNewModel:(id <BLCellNodeViewModelProtocol>)model;

- (void)appendNewModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models;

- (void)deleteModel:(id <BLCellNodeViewModelProtocol>)model;

- (void)deleteModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models;

- (void)insertModel:(id <BLCellNodeViewModelProtocol>)model atIndex:(NSInteger)index;

- (void)clearAllModels;

- (void)markModelNeedsReload:(id <BLCellNodeViewModelProtocol>)model;

- (void)markModelsNeedReload:(NSArray<id <BLCellNodeViewModelProtocol>> *)models;

/**
 添加占位model
 
 适用于，一个section没有model，cell node通过section model的cellNodeCreatorBlock 创建

 @return 占位的model
 */
- (BLSectionPlaceholderModel *)addPlaceholderModel;

- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                     footerHeight:(CGFloat)footerHeight;

- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                      headerColor:(nullable UIColor *)headerColor
                     footerHeight:(CGFloat)footerHeight
                      footerColor:(nullable UIColor *)footerColor;

- (void)configureWithHeaderNode:(nullable ASCellNode *)header
                     footerNode:(nullable ASCellNode *)footer;
#pragma mark - data query
- (NSUInteger)indexForModel:(id <BLCellNodeViewModelProtocol>)model;

- (nullable NSIndexSet *)indexesForModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models;

- (BOOL)isFirstModelOfIndex:(NSInteger)index;

- (BOOL)isLastModelOfIndex:(NSInteger)index;


#pragma mark - data monitoring
- (void)willFetchChangedData;

- (void)didFetchChangedData;

- (void)dataDidSynchronizeToUI;

- (void)dataWillSynchronizeToUI;

- (nullable NSIndexSet *)deletedIndexes;

- (nullable NSIndexSet *)updatedIndexes;

- (nullable NSIndexSet *)insertedIndexes;

- (BOOL)justPerformReloadTotally;

- (BOOL)isDataChanged;
@end
NS_ASSUME_NONNULL_END
