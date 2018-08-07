//
//  HHSectionModel.m
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//

#import "HHSectionModel.h"
#import "HHDataMonitor.h"

@interface HHSectionModel ()
@property (nonatomic, copy, nullable) NSArray *shownModels;
@property (nonatomic, copy, nullable) NSArray *toBeSynchronizedModels;
@property (nonatomic, strong) NSMutableArray *internalModels;
@property (nonatomic, strong) HHDataMonitor *dataMonitor;
@property (nonatomic, copy, nullable) HHSectionCellNodeTapAction cellNodeTapAction;
@property (nonatomic, copy, nullable) HHSectionCellNodeBlock cellNodeBlock;
@end

@implementation HHSectionModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _internalModels = [@[] mutableCopy];
        _dataMonitor = [[HHDataMonitor alloc] initWithMonitoredModels:self.internalModels];

    }
    return self;
}

- (instancetype)initWithCellNodeCreatorBlock:(HHSectionCellNodeBlock)cellNodeCreatorBlock
                           cellNodeTapAction:(nullable HHSectionCellNodeTapAction)tapAction
{
    self = [self init];
    if (self) {
        _cellNodeTapAction = tapAction;
        _cellNodeBlock = cellNodeCreatorBlock;
    }
    
    return self;
}

+ (instancetype)sectionModelWithCellNodeCreatorBlock:(HHSectionCellNodeBlock)cellNodeCreatorBlock
                                   cellNodeTapAction:(nullable HHSectionCellNodeTapAction)tapAction {
    return [[HHSectionModel alloc] initWithCellNodeCreatorBlock:cellNodeCreatorBlock cellNodeTapAction:tapAction];
}

#pragma mark - data mutating
- (void)appendNewModel:(id <HHCellNodeModelProtocol>)model {
    if (!model) {
        return;
    }
    if ([self modelExistsInCurrentModels:model]) {
        return;
    }
    [self.internalModels addObject:model];
    [self.dataMonitor operateModel:model operationType:HHDataOperationTypeInsert];
}

- (void)appendNewModels:(NSArray<id <HHCellNodeModelProtocol>> *)models {
    if (!models.count) {
        return;
    }

    [models enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self appendNewModel:obj];
    }];
}

- (void)deleteModel:(id <HHCellNodeModelProtocol>)model {
    if (!model || ![self modelExistsInCurrentModels:model]) {
        return;
    }

    [self.internalModels removeObject:model];
    [self.dataMonitor operateModel:model operationType:HHDataOperationTypeDelete];

}

- (void)deleteModels:(NSArray<id <HHCellNodeModelProtocol>> *)models {
    if (!models.count) {
        return;
    }
    
    [models enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self deleteModel:obj];
    }];
}

- (void)clearAllModels {
    [self.internalModels enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.dataMonitor operateModel:obj operationType:HHDataOperationTypeDelete];
    }];

    [self.internalModels removeAllObjects];
}

- (void)insertModel:(id <HHCellNodeModelProtocol>)model atIndex:(NSInteger)index {
    if ([self modelExistsInCurrentModels:model]) {
        NSAssert(NO, @"Model already exists!");
        return;
    }
    if (self.internalModels.count < index) {
        NSAssert(NO, @"Index out of bounds!");
        return;
    } else if (self.internalModels.count == index - 1) {
        [self appendNewModel:model];
    }
    [self.internalModels insertObject:model atIndex:index];
    [self.dataMonitor operateModel:model operationType:HHDataOperationTypeInsert];

}

- (void)markModelNeedsReload:(id <HHCellNodeModelProtocol>)model {
    if (!model) {
        return;
    }
    if (![self modelExistsInCurrentModels:model]) {
        NSAssert(NO, @"Model does not exist!");
        return;
    }
    [self.dataMonitor operateModel:model operationType:HHDataOperationTypeUpdate];
}

- (void)markModelsNeedReload:(NSArray<id <HHCellNodeModelProtocol>> *)models {
    if (!models.count) {
        return;
    }
    [models enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self markModelNeedsReload:obj];
    }];
}

- (id <HHCellNodeModelProtocol>)addPlaceholderModel {
    id <HHCellNodeModelProtocol> placeholder = [NSObject new];
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
        self.headerType = HHSectionModelFooterHeaderTypeFixedHeightSpacer;
        self.headerHeight = headerHeight;
        self.headerSpacerColor = headerColor ?: [UIColor colorWithRed:242.f / 255.f green:242.f / 255.f blue:242.f / 255.f alpha:1];
    }
    
    if (footerHeight > 0) {
        self.footerType = HHSectionModelFooterHeaderTypeFixedHeightSpacer;
        self.footerHeight = footerHeight;
        self.footerSpacerColor = footerColor ?: [UIColor colorWithRed:242.f / 255.f green:242.f / 255.f blue:242.f / 255.f alpha:1];
    }
}

- (void)configureWithHeaderNode:(nullable ASCellNode *)header
                     footerNode:(nullable ASCellNode *)footer {
    if (header) {
        self.headerType = HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode;
        self.header = header;
    }
    
    if (footer) {
        self.footerType = HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode;
        self.footer = footer;
    }
}
#pragma mark - data query
- (NSUInteger)indexForModel:(id <HHCellNodeModelProtocol>)model {
    return [self indexForModel:model inArray:self.internalModels];
}

- (NSUInteger)indexForModel:(id <HHCellNodeModelProtocol>)model inArray:(NSArray *)array {
    if (!model || !array.count) {
        return NSNotFound;
    }
    __block NSUInteger index = NSNotFound;
    [array enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == model) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (BOOL)modelExistsInCurrentModels:(id <HHCellNodeModelProtocol>)model {
    return [self modelExists:model inArray:self.internalModels];
}

- (BOOL)modelExists:(id <HHCellNodeModelProtocol>)model inArray:(NSArray<id <HHCellNodeModelProtocol>> *)array {
    return [self indexForModel:model inArray:array] != NSNotFound;
}

- (NSIndexSet *)indexesForModels:(NSArray<id <HHCellNodeModelProtocol>> *)models {
    if (!models.count) {
        return nil;
    }
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    [models enumerateObjectsUsingBlock:^(id <HHCellNodeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = [self indexForModel:obj];
        if (index != NSNotFound) {
            [indexes addIndex:index];
        }
    }];
    return [indexes copy];
}

- (NSArray<id <HHCellNodeModelProtocol>> *)models {
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
