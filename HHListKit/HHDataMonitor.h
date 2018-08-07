//
//  HHDataMonitor.h
//  HHListKit
//
//  Created by shelllhue on 26/03/2018.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, HHDataOperationType) {
    /**
     * Model inserting operation
     */
    HHDataOperationTypeInsert = 0,
    
    /**
     * Model updating operation
     */
    HHDataOperationTypeUpdate,
    
    /**
     * Model deleting operation
     */
    HHDataOperationTypeDelete
};

NS_ASSUME_NONNULL_BEGIN
@interface HHDataMonitor : NSObject

/**
 * Boolean value indicating whether reload totally
 */
@property (nonatomic, assign) BOOL justPerformReloadTotally;

/**
 * The models before changing
 * HHDataMonitor will monitor the changing between the previous models
 *      and the current models
 */
@property (nonatomic, copy, nullable, readonly) NSArray *previousModels;

/**
 * Initializing method
 *
 * @param monitoredModels The montored models array
 * @return HHDataMonitor instance
 */
- (instancetype)initWithMonitoredModels:(NSMutableArray *)monitoredModels;

/**
 * Operate model with the specified operation type
 *
 * @param model The operated model
 * @param operationType The operation type
 */
- (void)operateModel:(id)model operationType:(HHDataOperationType)operationType;

/**
 * Notify the monitor that the changed data will be fetched
 */
- (void)willFetchChangedData;

/**
 * Notify the monitor that the changed data has been fetched
 */
- (void)didFetchChangedData;

/**
 * Notify the monitor that the changed data will be synchronizing to UI
 */
- (void)dataWillSynchronizeToUI;

/**
 * Notify the monitor that the changed data has been synchronized to UI
 */
- (void)dataDidSynchronizeToUI;

/**
 * Fetch the deleted indexes
 */
- (nullable NSIndexSet *)deletedIndexes;

/**
 * Fetch the updated indexes
 */
- (nullable NSIndexSet *)updatedIndexes;

/**
 * Fetch the inserted indexes
 */
- (nullable NSIndexSet *)insertedIndexes;

/**
 * Fetch the index of the model in previous models
 */
- (NSUInteger)indexForModelInPreviousState:(id)model;

/**
 * Boolean value indicating whether the data is changed
 */
- (BOOL)isDataChanged;
@end
NS_ASSUME_NONNULL_END
