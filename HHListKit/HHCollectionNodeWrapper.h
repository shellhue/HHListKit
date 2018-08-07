//
//  HHCollectionNodeWrapper
//  HHListKit
//
//  Created by shelllhue on 17/03/2018.
//
#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASCollectionNode.h>
#import "HHSectionController.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^HHCollectionNodeUpdateCompletion)(BOOL finished);

@interface HHCollectionNodeWrapper : NSObject

/**
 * The wrapped collection node
 * Collection node will be created when HHCollectionNodeWrapper is initialized and
 *      set up with normal configuration, but you can set your customized collection node
 *      as well.
 */
@property (nonatomic, strong) ASCollectionNode *collectionNode;

/**
 * The section controller that is binded with this wrapper
 */
@property (nonatomic, strong, readonly) HHSectionController *sectionController;

#pragma mark - init

/**
 * Initialization method
 *
 * @param sectionController The binded section controller
 * @param containingVC The view controller that contains the wrapped collection node
 * @param delegate The delegate of the wrapped collection node
 * @param dataSource The dataSource of the wrapped collection node
 *
 * @return HHCollectionNodeWrapper instance
 */
- (instancetype)initWithSectionController:(HHSectionController *)sectionController
                 containingViewController:(UIViewController *)containingVC
                   collectionNodeDelegate:(nullable id <ASCollectionDelegate>)delegate
                     collectionDataSource:(nullable id <ASCollectionDataSource>)dataSource;

#pragma mark - config

/**
 * Enable selecting highlight
 */
- (void)enableSelectingHighlight;

/**
 * Disable selecting highlight
 */
- (void)disableSelectingHighlight;

/**
 * Disable auto update
 */
- (void)disableAutoupdate;

/**
 * enable auto update
 */
- (void)enableAutoupdate;

#pragma mark - update view

/**
 * Reload sections
 *
 * @param sectionModels Section models to be reloaded
 */
- (void)reloadSections:(NSArray<HHSectionModel *> *)sectionModels;

/**
 * Perform update with animated option
 *
 * @param animated Whether animating the updating
 */
- (void)performUpdatesWithAnimated:(BOOL)animated;

/**
 * Perform update with animated option
 *
 * @param animated Whether animating the updating
 * @param completion Completion block called on completion of updating
 */
- (void)performUpdatesWithAnimated:(BOOL)animated
                        completion:(nullable HHCollectionNodeUpdateCompletion)completion;

/**
 * Perform update without animation
 */
- (void)performUpdates;

/**
 * Reload data
 */
- (void)reloadData;
@end
NS_ASSUME_NONNULL_END
