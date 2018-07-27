//
//  BLDataMonitor.h
//  BLKit
//
//  Created by 黄泽宇 on 26/03/2018.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, BLSectionModelOperationType) {
    BLSectionModelOperationTypeInsert = 0,
    BLSectionModelOperationTypeUpdate,
    BLSectionModelOperationTypeDelete
};
NS_ASSUME_NONNULL_BEGIN
@interface BLDataMonitor : NSObject
@property (nonatomic) BOOL justPerformReloadTotally;
@property (nonatomic, copy, readonly) NSArray *previousModels;
- (instancetype)initWithMonitoredModels:(NSMutableArray *)monitoredModels;

- (void)operateModel:(id)model operationType:(BLSectionModelOperationType)operationType;

- (void)willFetchChangedData;

- (void)didFetchChangedData;

- (void)dataDidSynchronizeToUI;

- (void)dataWillSynchronizeToUI;

- (nullable NSIndexSet *)deletedIndexes;

- (nullable NSIndexSet *)updatedIndexes;

- (nullable NSIndexSet *)insertedIndexes;

- (NSUInteger)indexForModelInPreviousState:(id)model;

- (BOOL)isDataChanged;
@end
NS_ASSUME_NONNULL_END
