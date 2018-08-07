//
//  HHDataMonitor.m
//  HHListKit
//
//  Created by shelllhue on 26/03/2018.
//

#import "HHDataMonitor.h"
@interface HHDataMonitor ()

@property (nonatomic, copy, nullable) NSArray *previousModels;
@property (nonatomic, strong) NSMutableArray *currentModels;

@property (nonatomic, strong) NSMutableArray *deletedModels;
@property (nonatomic, strong) NSMutableArray *updatedModels;
@property (nonatomic, strong) NSMutableArray *insertedModels;

@property (nonatomic, copy, nullable) NSIndexSet *deletedIndexes;
@property (nonatomic, copy, nullable) NSIndexSet *updatedIndexes;
@property (nonatomic, copy, nullable) NSIndexSet *insertedIndexes;

@end
@implementation HHDataMonitor
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

- (void)operateModel:(id)model operationType:(HHDataOperationType)operationType {
    // Every operated model should be checked so that every model is assured to be in just one operated state
    if (!model) {
        return;
    }
    switch (operationType) {
        case HHDataOperationTypeInsert: {
            if ([self modelExists:model inArray:self.insertedModels]) {
                return;
            }
            [self.insertedModels addObject:model];
            NSUInteger indexForUpdating = [self indexForModel:model inArray:self.updatedModels];
            NSUInteger indexForDeleting = [self indexForModel:model inArray:self.deletedModels];
            if (indexForDeleting != NSNotFound) {
                // The model is first deleted and then added again, it may be moving operation which is not supported, so just marked as needing reload totally
                [self.deletedModels removeObjectAtIndex:indexForDeleting];
                self.justPerformReloadTotally = YES;
            }
            if (indexForUpdating != NSNotFound) {
                [self.updatedModels removeObjectAtIndex:indexForUpdating];
            }
        }
            break;
        case HHDataOperationTypeUpdate: {
            if ([self modelExists:model inArray:self.updatedModels]) {
                return;
            }
            NSUInteger indexForInserting = [self indexForModel:model inArray:self.insertedModels];
            NSUInteger indexForDeleting = [self indexForModel:model inArray:self.deletedModels];
            if (indexForDeleting != NSNotFound) {
                [self.deletedModels removeObjectAtIndex:indexForDeleting];
            }
            if (indexForInserting == NSNotFound) {
                [self.updatedModels addObject:model];
            }
        } break;
        case HHDataOperationTypeDelete: {
            if ([self modelExists:model inArray:self.deletedModels]) {
                return;
            }
            NSUInteger indexForInserting = [self indexForModel:model inArray:self.insertedModels];
            NSUInteger indexForUpdating = [self indexForModel:model inArray:self.updatedModels];
            if (indexForInserting != NSNotFound) {
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
