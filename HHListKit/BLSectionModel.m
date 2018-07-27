//
//  BLSectionModel.m
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//

#import "BLSectionModel.h"
#import "BLDataMonitor.h"

@interface BLSectionModel ()

/**
 已经显示在屏幕上的models
 */
@property (nonatomic, nullable, copy) NSArray *shownModels;

/**
 即将同步到屏幕显示的models，同步到UI后，置nil
 */
@property (nonatomic, nullable, copy) NSArray *toBeSynchronizedModels;

/**
 内部最新的models，反应当前最新的model状态
 */
@property (nonatomic) NSMutableArray *internalModels;
@property (nonatomic) BLDataMonitor *dataMonitor;

/**
 本section cell node的tap action
 */
@property (nonatomic, nullable) BLSectionModelTapActionBlock cellNodeTapAction;

/**
 本section的cell node creator
 */
@property (nonatomic, nullable) BLSectionModelCellNodeCreatorBlock cellNodeCreatorBlock;
@end

@implementation BLSectionModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _internalModels = [@[] mutableCopy];
        _dataMonitor = [[BLDataMonitor alloc] initWithMonitoredModels:self.internalModels];

    }
    return self;
}

- (instancetype)initWithCellNodeTapAction:(BLSectionModelTapActionBlock _Nullable)tapAction
                     cellNodeCreatorBlock:(BLSectionModelCellNodeCreatorBlock _Nullable)cellNodeCreatorBlock {
    self = [self init];
    if (self) {
        _cellNodeTapAction = tapAction;
        _cellNodeCreatorBlock = cellNodeCreatorBlock;
    }
    
    return self;
}

+ (instancetype)sectionModelWithCellNodeTapAction:(BLSectionModelTapActionBlock _Nullable)tapAction
                             cellNodeCreatorBlock:(BLSectionModelCellNodeCreatorBlock _Nullable)cellNodeCreatorBlock {
    return [[BLSectionModel alloc] initWithCellNodeTapAction:tapAction cellNodeCreatorBlock:cellNodeCreatorBlock];
}

#pragma mark - data mutating
- (void)appendNewModel:(id <BLCellNodeViewModelProtocol>)model {
    if (!model) {
        return;
    }
    if ([self modelExistsInCurrentModels:model]) {
        return;
    }
    [self.internalModels addObject:model];
    [self.dataMonitor operateModel:model operationType:BLSectionModelOperationTypeInsert];
}

- (void)appendNewModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models {
    if (!models.count) {
        return;
    }

    [models enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self appendNewModel:obj];
    }];
}

- (void)deleteModel:(id <BLCellNodeViewModelProtocol>)model {
    if (!model || ![self modelExistsInCurrentModels:model]) {
        return;
    }

    [self.internalModels removeObject:model];
    [self.dataMonitor operateModel:model operationType:BLSectionModelOperationTypeDelete];

}

- (void)deleteModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models {
    if (!models.count) {
        return;
    }
    
    [models enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self deleteModel:obj];
    }];
}

- (void)clearAllModels {
    [self.internalModels enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.dataMonitor operateModel:obj operationType:BLSectionModelOperationTypeDelete];
    }];

    [self.internalModels removeAllObjects];
}

- (void)insertModel:(id <BLCellNodeViewModelProtocol>)model atIndex:(NSInteger)index {
    if ([self modelExistsInCurrentModels:model]) {
        NSAssert(NO, @"model 已经在数组中");
        return;
    }
    if (self.internalModels.count < index) {
        NSAssert(NO, @"index 越界");
        return;
    } else if (self.internalModels.count == index - 1) {
        [self appendNewModel:model];
    }
    [self.internalModels insertObject:model atIndex:index];
    [self.dataMonitor operateModel:model operationType:BLSectionModelOperationTypeInsert];

}

- (void)markModelNeedsReload:(id <BLCellNodeViewModelProtocol>)model {
    if (!model) {
        return;
    }
    if (![self modelExistsInCurrentModels:model]) {
        NSAssert(NO, @"model 不在数组中");
        return;
    }
    [self.dataMonitor operateModel:model operationType:BLSectionModelOperationTypeUpdate];
}

- (void)markModelsNeedReload:(NSArray<id <BLCellNodeViewModelProtocol>> *)models {
    if (!models.count) {
        return;
    }
    [models enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self markModelNeedsReload:obj];
    }];
}

- (BLSectionPlaceholderModel *)addPlaceholderModel {
    BLSectionPlaceholderModel *placeholder = [BLSectionPlaceholderModel new];
    [self appendNewModel:placeholder];
    return placeholder;
}

- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                     footerHeight:(CGFloat)footerHeight {
    [self configureWithHeaderHeight:headerHeight headerColor:nil footerHeight:footerHeight footerColor:nil];
}

- (void)configureWithHeaderHeight:(CGFloat)headerHeight
                      headerColor:(nullable UIColor *)headerColor
                     footerHeight:(CGFloat)footerHeight
                      footerColor:(nullable UIColor *)footerColor {
    if (headerHeight > 0) {
        self.headerType = BLSectionModelFooterHeaderTypeFixHeightSpacer;
        self.headerHeight = headerHeight;
        self.headerSpacerColor = headerColor ?: [UIColor colorWithRed:242.f / 255.f green:242.f / 255.f blue:242.f / 255.f alpha:1];
    }
    
    if (footerHeight > 0) {
        self.footerType = BLSectionModelFooterHeaderTypeFixHeightSpacer;
        self.footerHeight = footerHeight;
        self.footerSpacerColor = footerColor ?: [UIColor colorWithRed:242.f / 255.f green:242.f / 255.f blue:242.f / 255.f alpha:1];
    }
}

- (void)configureWithHeaderNode:(nullable ASCellNode *)header
                     footerNode:(nullable ASCellNode *)footer {
    if (header) {
        self.headerType = BLSectionModelFooterHeaderTypeSelfCalculateHeightNode;
        self.header = header;
    }
    
    if (footer) {
        self.footerType = BLSectionModelFooterHeaderTypeSelfCalculateHeightNode;
        self.footer = footer;
    }
}
#pragma mark - data query
- (NSUInteger)indexForModel:(id <BLCellNodeViewModelProtocol>)model {
    return [self indexForModel:model inArray:self.internalModels];
}

- (NSUInteger)indexForModel:(id <BLCellNodeViewModelProtocol>)model inArray:(NSArray *)array {
    if (!model || !array.count) {
        return NSNotFound;
    }
    __block NSUInteger index = NSNotFound;
    [array enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == model) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (BOOL)modelExistsInCurrentModels:(id <BLCellNodeViewModelProtocol>)model {
    return [self modelExists:model inArray:self.internalModels];
}

- (BOOL)modelExists:(id <BLCellNodeViewModelProtocol>)model inArray:(NSArray<id <BLCellNodeViewModelProtocol>> *)array {
    return [self indexForModel:model inArray:array] != NSNotFound;
}

- (NSIndexSet *)indexesForModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)models {
    if (!models.count) {
        return nil;
    }
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    [models enumerateObjectsUsingBlock:^(id <BLCellNodeViewModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = [self indexForModel:obj];
        if (index != NSNotFound) {
            [indexes addIndex:index];
        }
    }];
    return [indexes copy];
}

- (NSArray<id <BLCellNodeViewModelProtocol>> *)models {
    return [self.internalModels copy];
}

- (BOOL)isFirstModelOfIndex:(NSInteger)index {
    return self.internalModels.count && index == 0;
}

- (BOOL)isLastModelOfIndex:(NSInteger)index {
    return index == self.internalModels.count - 1;
}

#pragma mark - data monitoring
- (void)willFetchChangedData {
    [self.dataMonitor willFetchChangedData];
}

- (void)didFetchChangedData {
    [self.dataMonitor didFetchChangedData];
}

- (void)dataDidSynchronizeToUI {
    [self.dataMonitor dataDidSynchronizeToUI];
    self.shownModels = self.toBeSynchronizedModels;
    self.toBeSynchronizedModels = nil;
}

- (void)dataWillSynchronizeToUI {
    [self.dataMonitor dataWillSynchronizeToUI];
    self.toBeSynchronizedModels = self.internalModels;
}

- (nullable NSIndexSet *)deletedIndexes {
    return self.dataMonitor.deletedIndexes;
}

- (nullable NSIndexSet *)updatedIndexes {
    return self.dataMonitor.updatedIndexes;
}

- (nullable NSIndexSet *)insertedIndexes {
    return self.dataMonitor.insertedIndexes;
}

- (BOOL)justPerformReloadTotally {
    return self.dataMonitor.justPerformReloadTotally;
}

- (BOOL)isDataChanged {
    return self.dataMonitor.isDataChanged;
}
@end
