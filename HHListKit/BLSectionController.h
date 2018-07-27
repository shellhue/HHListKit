//
//  BLSectionController.h
//  BLKit
//
//  Created by 黄泽宇 on 06/03/2018.
//

#import "BLSectionModel.h"
#import "BLCellNodeViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^BLCellNodeViewModelTapAction)(void);
typedef BLBaseCellNode * _Nonnull(^BLCellNodeCreatorBlock)(void);

@interface BLSectionController : NSObject
@property (nonatomic, readonly) NSArray<BLSectionModel *> *sectionModels;
/**
 已经显示到屏幕上的section
 */
@property (nonatomic, nullable, copy, readonly) NSArray<BLSectionModel *> *shownSectionModels;

/**
 即将同步到屏幕显示的sections，同步到UI后，置nil
 */
@property (nonatomic, nullable, copy, readonly) NSArray<BLSectionModel *> *toBeSynchronizedSectionModels;

/**
 是否为空，没有任何数据
 */
@property(nonatomic, assign, readonly) BOOL isEmpty;

#pragma mark - section data mutating
- (void)insertSectionModel:(BLSectionModel *)sectionModel atIndex:(NSInteger)index;

- (void)insertSectionModel:(BLSectionModel *)sectionModel beforeModel:(BLSectionModel *)sectionModel2;

- (void)insertSectionModel:(BLSectionModel *)sectionModel afterModel:(BLSectionModel *)sectionModel2;

- (void)markSectionModelNeedsReload:(BLSectionModel *)sectionModel;

- (void)appendSectionModel:(BLSectionModel *)sectionModel;

- (void)deleteSectionModel:(BLSectionModel *)sectionModel;

#pragma mark - data query
- (nullable NSIndexPath *)indexPathForModel:(id <BLCellNodeViewModelProtocol>)model
                             inSectionModel:(BLSectionModel *)sectionModel;

- (NSArray<NSIndexPath *> *)indexPathesForModels:(NSArray<id <BLCellNodeViewModelProtocol>> *)model
                                  inSectionModel:(BLSectionModel *)sectionModel;
/**
 此处model有可能仍未绘制到屏幕上，相对于当前数据
 */
- (nullable id <BLCellNodeViewModelProtocol>)modelForIndexPath:(NSIndexPath *)indexPath;

/**
 已经绘制到屏幕上的model，相对于已经显示的数据
 */
- (nullable id <BLCellNodeViewModelProtocol>)shownModelForIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)sectionNumber;

- (NSUInteger)sectionForSectionModel:(BLSectionModel *)sectionModel;

- (NSUInteger)modelCountForSection:(NSUInteger)section;

- (NSUInteger)modelCountForSectionModel:(BLSectionModel *)sectionModel;

- (nullable BLSectionModel *)sectionModelForSection:(NSInteger)section;

- (void)clearAllSections;

- (BOOL)isFirstCellOfIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isLastCellOfIndexPath:(NSIndexPath *)indexPath;

- (BOOL)sectionExists:(BLSectionModel *)sectionModel;

#pragma mark - 数据自动监听
- (NSArray<NSIndexPath *> *)deletedIndexPathes;
- (NSArray<NSIndexPath *> *)insertedIndexPathes;
- (NSArray<NSIndexPath *> *)updatedIndexPathes;

- (nullable NSIndexSet *)deletedSections;
- (nullable NSIndexSet *)insertedSections;
- (nullable NSIndexSet *)updatedSections;

- (void)dataDidSynchronizeToUI;
- (void)dataWillSynchronizeToUI;

- (void)willFetchChangedData;
- (void)didFetchChangedData;

- (BOOL)justPerformReloadTotally;
- (void)setJustPerformReloadTotallyToYES;
- (BOOL)isDataChanged;
@end
NS_ASSUME_NONNULL_END
