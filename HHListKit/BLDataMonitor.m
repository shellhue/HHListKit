//
//  BLDataMonitor.m
//  BLKit
//
//  Created by 黄泽宇 on 26/03/2018.
//

#import "BLDataMonitor.h"
@interface BLDataMonitor ()

@property (nonatomic, copy) NSArray *previousModels;

@property (nonatomic) NSMutableArray *currentModels;

@property (nonatomic) NSMutableArray *deletedModels;
@property (nonatomic) NSMutableArray *updatedModels;
@property (nonatomic) NSMutableArray *insertedModels;

@property (nonatomic, copy) NSIndexSet *deletedIndexes;
@property (nonatomic, copy) NSIndexSet *updatedIndexes;
@property (nonatomic, copy) NSIndexSet *insertedIndexes;

@end
@implementation BLDataMonitor
- (instancetype)initWithMonitoredModels:(NSMutableArray *)monitoredModels {
    self = [super init];
    if (self) {
        _currentModels = monitoredModels;
        _deletedModels = [@[] mutableCopy];
        _updatedModels = [@[] mutableCopy];
        _insertedModels = [@[] mutableCopy];
    }
    return self;
}

- (void)willFetchChangedData {
    if (self.justPerformReloadTotally) {
        return;
    }
    NSMutableIndexSet *indexesForUpdating = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *indexesForDeleting = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *indexesForInserting = [NSMutableIndexSet indexSet];
    
    [self.updatedModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = [self indexForModel:obj inArray:self.previousModels];
        if (index != NSNotFound) {
            [indexesForUpdating addIndex:index];
        }
    }];
    
    [self.deletedModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = [self indexForModel:obj inArray:self.previousModels];
        if (index != NSNotFound) {
            [indexesForDeleting addIndex:index];
        }
    }];
    
    [self.insertedModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = [self indexForModel:obj inArray:self.currentModels];
        if (index != NSNotFound) {
            [indexesForInserting addIndex:index];
        }
    }];
    
    self.deletedIndexes = indexesForDeleting;
    self.insertedIndexes = indexesForInserting;
    self.updatedIndexes = indexesForUpdating;
}

- (void)didFetchChangedData {
    [self.updatedModels removeAllObjects];
    [self.deletedModels removeAllObjects];
    [self.insertedModels removeAllObjects];
    self.deletedIndexes = nil;
    self.insertedIndexes = nil;
    self.updatedIndexes = nil;
    self.justPerformReloadTotally = NO;
}

- (void)dataWillSynchronizeToUI {
    self.previousModels = self.currentModels;
}

- (void)dataDidSynchronizeToUI {
    
}

- (void)operateModel:(id)model operationType:(BLSectionModelOperationType)operationType {
    // 每次对model进行更新、删除、插入操作，都需要判断该model是否已经被更新、删除或者插入，确保一个model只处于一个状态
    if (!model) {
        return;
    }
    switch (operationType) {
        case BLSectionModelOperationTypeInsert: {
            if ([self modelExists:model inArray:self.insertedModels]) {
                return;
            }
            [self.insertedModels addObject:model];
            NSUInteger indexForUpdating = [self indexForModel:model inArray:self.updatedModels];
            NSUInteger indexForDeleting = [self indexForModel:model inArray:self.deletedModels];
            if (indexForDeleting != NSNotFound) {
                // 此种情况属于，先删除，再添加，有可能属于位置移动，直接标记为整个section reload
                [self.deletedModels removeObjectAtIndex:indexForDeleting];
                self.justPerformReloadTotally = YES;
            }
            if (indexForUpdating != NSNotFound) {
                NSAssert(NO, @"刚更新，接着就添加，此种情况不存在，currentModels有model存在时，无法再次添加");
                [self.updatedModels removeObjectAtIndex:indexForUpdating];
            }
        }
            break;
        case BLSectionModelOperationTypeUpdate: {
            if ([self modelExists:model inArray:self.updatedModels]) {
                return;
            }
            NSUInteger indexForInserting = [self indexForModel:model inArray:self.insertedModels];
            NSUInteger indexForDeleting = [self indexForModel:model inArray:self.deletedModels];
            if (indexForDeleting != NSNotFound) {
                NSAssert(NO, @"刚删除，又立马更新，此种情况不存在");
                [self.deletedModels removeObjectAtIndex:indexForDeleting];
            }
            if (indexForInserting == NSNotFound) {
                [self.updatedModels addObject:model];
            } else {
                // 属于刚添加，就更新model的情况，此种情况存在，但不能算作update，应该算作insert
            }
        } break;
        case BLSectionModelOperationTypeDelete: {
            if ([self modelExists:model inArray:self.deletedModels]) {
                return;
            }
            NSUInteger indexForInserting = [self indexForModel:model inArray:self.insertedModels];
            NSUInteger indexForUpdating = [self indexForModel:model inArray:self.updatedModels];
            if (indexForInserting != NSNotFound) {
                // 刚添加，接着就删除，此时应该没有任何变化
                [self.insertedModels removeObjectAtIndex:indexForInserting];
            } else {
                [self.deletedModels addObject:model];
            }
            if (indexForUpdating != NSNotFound) {
                [self.updatedModels removeObjectAtIndex:indexForUpdating];
            }
        } break;
        default:
            break;
    }
}

#pragma mark - data query
- (NSUInteger)indexForModel:(id)model {
    return [self indexForModel:model inArray:self.currentModels];
}

- (NSUInteger)indexForModel:(id)model inArray:(NSArray *)array {
    if (!model || !array.count) {
        return NSNotFound;
    }
    __block NSUInteger index = NSNotFound;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == model) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (NSUInteger)indexForModelInPreviousState:(id)model {        
    return [self indexForModel:model inArray:self.previousModels];
}

- (BOOL)modelExistsInCurrentModels:(id)model {
    return [self modelExists:model inArray:self.currentModels];
}

- (BOOL)modelExists:(id)model inArray:(NSArray *)array {
    return [self indexForModel:model inArray:array] != NSNotFound;
}

- (BOOL)isDataChanged {
    return self.deletedModels.count || self.insertedModels.count || self.updatedModels.count || self.justPerformReloadTotally;
}
@end
