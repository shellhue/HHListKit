//
//  HHSectionController.m
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//

#import "HHSectionController.h"
#import "HHDataMonitor.h"

@interface HHSectionController ()
@property (nonatomic, copy, nullable) NSArray<HHSectionModel *> *shownSectionModels;
@property (nonatomic, copy, nullable) NSArray<HHSectionModel *> *toBeSynchronizedSectionModels;
@property (nonatomic, strong) NSMutableArray<HHSectionModel *> *internalSectionModels;
@property (nonatomic, strong) HHDataMonitor *dataMonitor;

@end
@implementation HHSectionController
- (instancetype)init {
    self = [super init];
    if (self) {
        _internalSectionModels = [@[] mutableCopy];
        _dataMonitor = [[HHDataMonitor alloc] initWithMonitoredModels:self.internalSectionModels];
    }
    return self;
}

#pragma mark - section model mutating

- (void)clearAllSections {
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.dataMonitor operateModel:obj operationType:HHDataOperationTypeDelete];
    }];
    [self.internalSectionModels removeAllObjects];
}

- (void)appendSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel) {
        return;
    }
    if ([self sectionExists:sectionModel]) {
        return;
    }
    [self.internalSectionModels addObject:sectionModel];
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeInsert];
}

- (void)deleteSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel) {
        return;
    }
    if (![self sectionExists:sectionModel]) {
        return;
    }
    [self.internalSectionModels removeObject:sectionModel];
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeDelete];

}

- (void)markSectionModelNeedsReload:(HHSectionModel *)sectionModel {
    if (!sectionModel) {
        return;
    }
    if (![self sectionExists:sectionModel]) {
        return;
    }
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeUpdate];
}

- (void)appendNewModels:(NSArray<id <HHCellNodeModelProtocol>> *)models forSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel || !models.count) {
        return;
    }
    [sectionModel appendNewModels:models];
}

- (void)deleteModel:(id <HHCellNodeModelProtocol>)model fromSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel || !model) {
        return;
    }
    [sectionModel deleteModel:model];
}

- (void)deleteModels:(NSArray<id <HHCellNodeModelProtocol>> *)models fromSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel || !models.count) {
        return;
    }
    [sectionModel deleteModels:models];
}

- (void)insertSectionModel:(HHSectionModel *)sectionModel atIndex:(NSInteger)index {
    if (!sectionModel) {
        return;
    }
    if ([self sectionExists:sectionModel]) {
        return;
    }
    if (self.internalSectionModels.count < index) {
        return;
    }
    [self.internalSectionModels insertObject:sectionModel atIndex:index];
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeInsert];
}

- (void)insertSectionModel:(HHSectionModel *)sectionModel beforeModel:(HHSectionModel *)sectionModel2 {
    if (!sectionModel || !sectionModel2) {
        return;
    }
    if ([self sectionExists:sectionModel] || ![self sectionExists:sectionModel2]) {
        return;
    }
    NSInteger index = [self sectionForSectionModel:sectionModel2];
    [self.internalSectionModels insertObject:sectionModel atIndex:index];
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeInsert];

}

- (void)insertSectionModel:(HHSectionModel *)sectionModel afterModel:(HHSectionModel *)sectionModel2 {
    if (!sectionModel || !sectionModel2) {
        return;
    }
    if ([self sectionExists:sectionModel] || ![self sectionExists:sectionModel2]) {
        return;
    }
    NSInteger index = [self sectionForSectionModel:sectionModel2];
    if (index == self.internalSectionModels.count - 1) {
        [self.internalSectionModels addObject:sectionModel];
    } else {
        [self.internalSectionModels insertObject:sectionModel atIndex:index + 1];
    }
    [self.dataMonitor operateModel:sectionModel operationType:HHDataOperationTypeInsert];
}

#pragma mark - data query

- (BOOL)isEmpty {
    BOOL isEmpty = YES;
    for(HHSectionModel *model in self.sectionModels){
        if(model.models.count){
           isEmpty = NO;
            break;
        }
    }
    return isEmpty;
}

- (nullable NSIndexPath *)indexPathForModel:(id <HHCellNodeModelProtocol>)model inSectionModel:(HHSectionModel *)sectionModel {
    NSInteger section = [self sectionForSectionModel:sectionModel];
    NSInteger index = [sectionModel indexForModel:model];
    if (section == NSNotFound || index == NSNotFound) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:index inSection:section];
}

- (NSArray<NSIndexPath *> *)indexPathesForModels:(NSArray<id <HHCellNodeModelProtocol>> *)models inSectionModel:(HHSectionModel *)sectionModel {
    if (!models.count) {
        return @[];
    }
    NSMutableArray<NSIndexPath *> *indexPathes = [@[] mutableCopy];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [self indexPathForModel:obj inSectionModel:sectionModel];
        if (indexPath) {
            [indexPathes addObject:indexPath];
        }
    }];
    return [indexPathes copy];
}

- (nullable id <HHCellNodeModelProtocol>)modelForIndexPath:(NSIndexPath *)indexPath {
    if (![self isValidIndexPath:indexPath]) {
        return nil;
    }
    
    return self.sectionModels[indexPath.section].models[indexPath.row];
}

- (nullable id <HHCellNodeModelProtocol>)shownModelForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= self.shownSectionModels.count) {
        return nil;
    }
    if (indexPath.row >= self.shownSectionModels[indexPath.section].shownModels.count) {
        return nil;
    }
    return self.shownSectionModels[indexPath.section].shownModels[indexPath.row];
}

- (BOOL)isValidIndexPath:(NSIndexPath *)indexPath {
    return [self isValidSection:indexPath.section] &&
    indexPath.row < [self modelCountForSection:indexPath.section] &&
    indexPath.row >= 0;
}

- (BOOL)isValidSection:(NSInteger)section {
    return section < self.sectionNumber && section >= 0;
}

- (NSUInteger)sectionNumber {
    return self.internalSectionModels.count;
}

- (NSUInteger)modelCountForSection:(NSUInteger)section {
    if (![self isValidSection:section]) {
        return NSNotFound;
    }
    return self.internalSectionModels[section].models.count;
}

- (NSUInteger)modelCountForSectionModel:(HHSectionModel *)sectionModel {
    return sectionModel.models.count;
}

- (NSArray<HHSectionModel *> *)sectionModels {
    return [self.internalSectionModels copy];
}

- (nullable HHSectionModel *)sectionModelForSection:(NSInteger)section {
    if (![self isValidSection:section]) {
        return nil;
    }
    
    return self.internalSectionModels[section];
}

- (NSUInteger)sectionForSectionModel:(HHSectionModel *)sectionModel {
    if (!sectionModel) {
        return NSNotFound;
    }
    __block NSUInteger index = NSNotFound;
    [self.internalSectionModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == sectionModel) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (BOOL)sectionExists:(HHSectionModel *)sectionModel {
    return [self sectionForSectionModel:sectionModel] != NSNotFound;
}

- (BOOL)isFirstCellOfIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return NO;
    }
    
    if (![self isValidIndexPath:indexPath]) {
        return NO;
    }
    
    return [self.internalSectionModels[indexPath.section] isFirstModelOfIndex:indexPath.row];
}

- (BOOL)isLastCellOfIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return NO;
    }
    
    if (![self isValidIndexPath:indexPath]) {
        return NO;
    }
    
    return [self.internalSectionModels[indexPath.section] isLastModelOfIndex:indexPath.row];
}

#pragma mark - data monitoring
- (void)willFetchChangedData {
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj,
                                                             NSUInteger idx,
                                                             BOOL * _Nonnull stop) {
        if (obj.justPerformReloadTotally) {
            [self.dataMonitor operateModel:obj operationType:HHDataOperationTypeUpdate];
            [obj didFetchChangedData];
        } else {
            [obj willFetchChangedData];
        }
    }];
    [self.dataMonitor willFetchChangedData];

}

- (void)didFetchChangedData {
    [self.dataMonitor didFetchChangedData];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj didFetchChangedData];
    }];
}

- (void)dataDidSynchronizeToUI {
    self.shownSectionModels = self.toBeSynchronizedSectionModels;
    self.toBeSynchronizedSectionModels = nil;
    [self.dataMonitor dataDidSynchronizeToUI];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj dataDidSynchronizeToUI];
    }];
}

- (void)dataWillSynchronizeToUI {
    self.toBeSynchronizedSectionModels = self.internalSectionModels;
    [self.dataMonitor dataWillSynchronizeToUI];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj dataWillSynchronizeToUI];
    }];
}

- (NSArray<NSIndexPath *> *)deletedIndexPathes {
    __block NSMutableArray<NSIndexPath *> *indexPathes = [@[] mutableCopy];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger section = [self.dataMonitor indexForModelInPreviousState:obj];
        if (section == NSNotFound) {
            return;
        }
        [obj.deletedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [indexPathes addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
        }];
    }];

    return [indexPathes copy];
}

- (NSArray<NSIndexPath *> *)updatedIndexPathes {
    __block NSMutableArray<NSIndexPath *> *indexPathes = [@[] mutableCopy];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger section = [self.dataMonitor indexForModelInPreviousState:obj];
        if (section == NSNotFound) {
            return;
        }
        [obj.updatedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [indexPathes addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
        }];
    }];
    
    return [indexPathes copy];
}

- (NSArray<NSIndexPath *> *)insertedIndexPathes {
    __block NSMutableArray<NSIndexPath *> *indexPathes = [@[] mutableCopy];
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger section = [self sectionForSectionModel:obj];
        if (section == NSNotFound) {
            return;
        }
        [obj.insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [indexPathes addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
        }];
    }];
    
    return [indexPathes copy];
}

- (nullable NSIndexSet *)deletedSections {
    return self.dataMonitor.deletedIndexes;
}

- (nullable NSIndexSet *)updatedSections {
    return self.dataMonitor.updatedIndexes;
}

- (nullable NSIndexSet *)insertedSections {
    return self.dataMonitor.insertedIndexes;
}

- (BOOL)justPerformReloadTotally {
    return self.dataMonitor.justPerformReloadTotally;
}

- (void)setJustPerformReloadTotallyToYES {
    self.dataMonitor.justPerformReloadTotally = YES;
}

- (BOOL)isDataChanged {
    __block BOOL changed = NO;
    [self.internalSectionModels enumerateObjectsUsingBlock:^(HHSectionModel *obj, NSUInteger idx, BOOL *stop) {
        changed = changed ?: obj.isDataChanged;
    }];
    changed = changed ?: self.dataMonitor.isDataChanged;
    return changed;
}
@end
