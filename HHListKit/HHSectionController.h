//
//  HHSectionController.h
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//

#import "HHSectionModel.h"
#import "HHCellNodeModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HHSectionController : NSObject

/**
 * All the sections this section controller controls
 */
@property (nonatomic, copy, readonly) NSArray<HHSectionModel *> *sectionModels;

/**
 * All the sections that have been shown on screen
 * @warning Some inserted, updated or deleted sections may have not been synchronized to UI
 *      this property is used to fetch the models that corresponds to shown UI
 */
@property (nonatomic, copy, nullable, readonly) NSArray<HHSectionModel *> *shownSectionModels;

/**
 * The section models that will be synchronized to UI
 * This property contains all the section models not just the changed models if this property is not nil
 */
@property (nonatomic, copy, nullable, readonly) NSArray<HHSectionModel *> *toBeSynchronizedSectionModels;

/**
 * Boolean value indicating whether all the sections are empty
 */
@property(nonatomic, assign, readonly) BOOL isEmpty;

#pragma mark - section data mutating

/**
 * Insert section at the specified index
 *
 * @param sectionModel The section to be inserted
 * @param index The index the section to be inserted at
 */
- (void)insertSectionModel:(HHSectionModel *)sectionModel atIndex:(NSInteger)index;

/**
 * Insert section before the specified section
 *
 * @param sectionModel The section to be inserted
 * @param sectionModel2 The section before which the new section will be inserted
 */
- (void)insertSectionModel:(HHSectionModel *)sectionModel beforeModel:(HHSectionModel *)sectionModel2;

/**
 * Insert section after the specified section
 *
 * @param sectionModel The section to be inserted
 * @param sectionModel2 The section after which the new section will be inserted
 */
- (void)insertSectionModel:(HHSectionModel *)sectionModel afterModel:(HHSectionModel *)sectionModel2;

/**
 * Mark a section model needs to be reloaded
 *
 * @param sectionModel The section model to be reloaded
 */
- (void)markSectionModelNeedsReload:(HHSectionModel *)sectionModel;

/**
 * Add new section model
 *
 * @param sectionModel The section model to be added
 */
- (void)appendSectionModel:(HHSectionModel *)sectionModel;

/**
 * Delete new section model
 *
 * @param sectionModel The section model to be deleted
 */
- (void)deleteSectionModel:(HHSectionModel *)sectionModel;

#pragma mark - data query

/**
 * Fetch the indexPath of a model in a section
 *
 * @param model The model of which indexPath is queried
 * @param sectionModel The section model to which the queried model belongs
 * @return The indexPath of the queried model
 */
- (nullable NSIndexPath *)indexPathForModel:(id <HHCellNodeModelProtocol>)model
                             inSectionModel:(HHSectionModel *)sectionModel;

/**
 * Fetch the indexPathes of the models in a section
 *
 * @param models The models of which indexPathes are queried
 * @param sectionModel The section model to which the queried models belong
 * @return The indexPathes of the queried models
 */
- (NSArray<NSIndexPath *> *)indexPathesForModels:(NSArray<id <HHCellNodeModelProtocol>> *)models
                                  inSectionModel:(HHSectionModel *)sectionModel;

/**
 * Fetch the model at the specified indexPath relative to the current section models
 * @warning The indexPath is calculated relative to the current section models
 *      of which some model may have not be synchronized to UI
 */
- (nullable id <HHCellNodeModelProtocol>)modelForIndexPath:(NSIndexPath *)indexPath;

/**
 * Fetch the model at the specified indexPath relative to the shown section models
 * @warning The indexPath is calculated relative to the shown section models
 *
 * This method is recommended when you want to fetch the model corresponding to a shown cell,
 *      such as when you are handling the taping action of a cell
 */
- (nullable id <HHCellNodeModelProtocol>)shownModelForIndexPath:(NSIndexPath *)indexPath;


/**
 * The total count of sections in this section controller
 */
- (NSUInteger)sectionNumber;

/**
 * The section index of the specified section model
 * @param sectionModel The specified section model
 * @return The section index
 */
- (NSUInteger)sectionForSectionModel:(HHSectionModel *)sectionModel;

/**
 * The total count of models at the specified section index
 * @param section The specified section index
 * @return The total count of models
 */
- (NSUInteger)modelCountForSection:(NSUInteger)section;

/**
 * The total count of models in the specified section model
 * @param sectionModel The specified section model
 * @return The total count of models
 */
- (NSUInteger)modelCountForSectionModel:(HHSectionModel *)sectionModel;

/**
 * The section model at the specified section index
 *
 * @param section The specified sectiona
 * @return The section model
 */
- (nullable HHSectionModel *)sectionModelForSection:(NSInteger)section;

/**
 * Clear all the sections controlled by this section controller
 */
- (void)clearAllSections;

/**
 * Whether the cell at the specified indexPath is the first cell
 *
 *
 * @param indexPath The specified indexPath
 * @return Boolean value indivating Whether the cell at the specified indexPath is the first cell
 *
 * @warning The result is calculated relative to the current section models
 *      of which some model may have not be synchronized to UI
 */
- (BOOL)isFirstCellOfIndexPath:(NSIndexPath *)indexPath;

/**
 * Whether the cell at the specified indexPath is the last cell
 *
 *
 * @param indexPath The specified indexPath
 * @return Boolean value indivating Whether the cell at the specified indexPath is the last cell
 *
 * @warning The result is calculated relative to the current section models
 *      of which some model may have not be synchronized to UI
 */
- (BOOL)isLastCellOfIndexPath:(NSIndexPath *)indexPath;

/**
 * Whether the section model exists
 *
 * @param sectionModel The specified section model
 * @return Boolean value indicating whether the section model exists
 */
- (BOOL)sectionExists:(HHSectionModel *)sectionModel;

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
