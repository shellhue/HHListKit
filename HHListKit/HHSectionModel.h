//
//  HHSectionModel.h
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//
#import <AsyncDisplayKit/ASCellNode.h>
#import "HHCellNodeModelProtocol.h"
#import "HHCellNode.h"
#import "NSObject+HHCellNodeModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HHSectionCellNodeTapAction)(id model, __kindof UIViewController *containingVC);
typedef HHCellNode *__nonnull (^HHSectionCellNodeBlock)(id model, __kindof UIViewController *containingVC);

typedef NS_ENUM(NSUInteger, HHSectionModelFooterHeaderType) {
    /**
     * No header(footer) type
     */
    HHSectionModelFooterHeaderTypeNone = 0,
    
    /**
     * Fixed height spacer header(footer) type, spacer color can be customized
     */
    HHSectionModelFooterHeaderTypeFixedHeightSpacer,
    
    /**
     * Fixed height header(footer) type, header(footer) node and its fixed height should be supplied
     */
    HHSectionModelFooterHeaderTypeFixedHeightNode,
    
    /**
     * Height self calculated header(footer) type, header(footer) node should be supplied
     */
    HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode,
};

@interface HHSectionModel <__covariant CellNodeModel> : NSObject

/**
 * The current models in this section
 */
@property (nonatomic, copy, readonly) NSArray<id <HHCellNodeModelProtocol>> *models;

/**
 * The models that has been shown on screen
 *
 */
@property (nonatomic, copy, nullable, readonly) NSArray<id <HHCellNodeModelProtocol>> *shownModels;

/**
 * The models that will be synchronized to UI
 * This property contains all the models not just the changed models if this property is not nil
 */
@property (nonatomic, copy, nullable, readonly) NSArray<id <HHCellNodeModelProtocol>> *toBeSynchronizedModels;

/**
 * Cell tap action of the cells of this section model, can be nil
 */
@property (nonatomic, copy, nullable, readonly) HHSectionCellNodeTapAction cellNodeTapAction;

/**
 * Cell node creator block of the cells of this section model, can be nil
 * @warning Executed on background thread
 */
@property (nonatomic, copy, nullable, readonly) HHSectionCellNodeBlock cellNodeBlock;
#pragma mark - Header Footer

/**
 * Header type
 */
@property (nonatomic, assign) HHSectionModelFooterHeaderType headerType;

/**
 * Header node
 */
@property (nonatomic, strong, nullable) ASCellNode *header;

/**
 * Fixed header height
 */
@property (nonatomic, assign) CGFloat headerHeight;

/**
 * Header spacer color
 */
@property (nonatomic, strong, nullable) UIColor *headerSpacerColor;

/**
 * Footer type
 */
@property (nonatomic, assign) HHSectionModelFooterHeaderType footerType;

/**
 * Footer node
 */
@property (nonatomic, strong, nullable) ASCellNode *footer;

/**
 * Fixed footer height
 */
@property (nonatomic, assign) CGFloat footerHeight;

/**
 * Footer spacer color
 */
@property (nonatomic, strong, nullable) UIColor *footerSpacerColor;

#pragma mark - init

/**
 * @warning Model must implement HHCellNodeModelProtocol when this initialization method is used
 */
- (instancetype)init;

/**
 * Init method
 *
 * @param cellNodeCreatorBlock The cell node creator block of the cell in this section
 * @param tapAction The cell node tap action of the cell in this section
 * @return HHSectionModel instance
 *
 * @warning Model need not to implement HHCellNodeModelProtocol when this initialization method is used
 */
+ (instancetype)sectionModelWithCellNodeCreatorBlock:(HHSectionCellNodeBlock)cellNodeCreatorBlock
                                   cellNodeTapAction:(nullable HHSectionCellNodeTapAction)tapAction;

#pragma mark - data mutating

/**
 * Clear all the models in this section
 */
- (void)clearAllModels;

/**
 * Add new model
 *
 * @param model The model to be added
 */
- (void)appendNewModel:(id<HHCellNodeModelProtocol>)model;

/**
 * Add new models
 *
 * @param models The models to be added
 */
- (void)appendNewModels:(NSArray<id<HHCellNodeModelProtocol>> *)models;

/**
 * Delete a model
 *
 * @param model The model to be deleted
 */
- (void)deleteModel:(id<HHCellNodeModelProtocol>)model;

/**
 * Delete models
 *
 * @param models The models to be deleted
 */
- (void)deleteModels:(NSArray<id<HHCellNodeModelProtocol>> *)models;

/**
 * Insert model at index
 *
 * @param model The model to be inserted
 * @param index The index at which the model to be inserted
 */
- (void)insertModel:(id<HHCellNodeModelProtocol>)model atIndex:(NSInteger)index;

/**
 * Mark a model needs to be reloaded
 *
 * @param model The model to be reloaded
 */
- (void)markModelNeedsReload:(id <HHCellNodeModelProtocol>)model;

/**
 * Mark models need to be reloaded
 *
 * @param models The models to be reloaded
 */
- (void)markModelsNeedReload:(NSArray<id<HHCellNodeModelProtocol>> *)models;

/**
 * Add placeholder model
 * This will be useful when section has cells but no corresponding models
 *
 * @return The added placeholder model
 */
- (id<HHCellNodeModelProtocol>)addPlaceholderModel;

/**
 * Add fixed height header(footer) spacer with default color
 *
 * @param headerHeight Fixed header spacer height
 * @param footerHeight Fixed footer spacer height
 */
- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                     footerHeight:(CGFloat)footerHeight;

/**
 * Add fixed height header(footer) spacer with default color
 *
 * @param headerHeight Fixed header spacer height
 * @param headerColor Header spacer color
 * @param footerHeight Fixed footer spacer height
 * @param footerColor Footer spacer color
 */
- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                      headerColor:(nullable UIColor *)headerColor
                     footerHeight:(CGFloat)footerHeight
                      footerColor:(nullable UIColor *)footerColor;

/**
 * Add height self calculated header(footer)
 *
 * @param header Header node
 * @param footer Header node
 */
- (void)configureWithHeaderNode:(nullable ASCellNode *)header
                     footerNode:(nullable ASCellNode *)footer;
#pragma mark - data query

/**
 * The index of a model
 *
 * @param model The model be queried
 * @return The index of the model
 */
- (NSUInteger)indexForModel:(id<HHCellNodeModelProtocol>)model;

/**
 * The indexes of a model
 *
 * @param models The models be queried
 * @return The indexes of the models
 */
- (nullable NSIndexSet *)indexesForModels:(NSArray<id<HHCellNodeModelProtocol>> *)models;

/**
 * Whether the model at the specified index is the first model
 *
 * @param index The specified index
 * @return Boolean value indicating whether the corresponding model is the first one
 */
- (BOOL)isFirstModelOfIndex:(NSInteger)index;

/**
 * Whether the model at the specified index is the last model
 *
 * @param index The specified index
 * @return Boolean value indicating whether the corresponding model is the last one
 */
- (BOOL)isLastModelOfIndex:(NSInteger)index;

#pragma mark - data monitoring (__private)
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
