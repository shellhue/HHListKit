//
//  HHTableNodeWrapper.h
//  HHListKit
//
//  Created by 黄泽宇 on 08/08/2018.
//  Copyright © 2018 黄泽宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASTableNode.h>
#import "HHSectionController.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^HHTableNodeUpdateCompletion)(BOOL finished);

@interface HHTableNodeWrapper : NSObject

/**
 * The wrapped table node
 * Table node will be created when HHTableNodeWrapper is initialized and
 *      set up with normal configuration, but you can set your customized collection node
 *      as well.
 */
@property (nonatomic, strong) ASTableNode *tableNode;

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
                            tableDelegate:(nullable id <ASTableDelegate>)delegate
                          tableDataSource:(nullable id <ASTableDataSource>)dataSource;

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
                        completion:(nullable HHTableNodeUpdateCompletion)completion;

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
