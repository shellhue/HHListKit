//
//  BLCollectionNodeBoilerplate.h
//  BLKit
//
//  Created by 黄泽宇 on 17/03/2018.
//

#import <Foundation/Foundation.h>
#import "ASCollectionNode.h"
#import "BLSectionController.h"
#import "BLSectionModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BLCollectionNodeCompletionBlock)(BOOL finished);

@interface BLCollectionNodeWrapper : NSObject
@property (nonatomic) ASCollectionNode *collectionNode;
@property (nonatomic, readonly) BLSectionController *sectionController;

#pragma mark - init
- (instancetype)initWithSectionController:(BLSectionController *)sectionController
                    contextViewController:(UIViewController *)contextVC
                   collectionNodeDelegate:(nullable id <ASCollectionDelegate>)delegate
                     collectionDataSource:(nullable id <ASCollectionDataSource>)dataSource;

#pragma mark - config

/**
 开启点击cell高亮
 */
- (void)enableSelectHighlight;

/**
 关闭点击cell高亮
 */
- (void)disableSelectHighlight;

/**
 关闭自动刷新
 */
- (void)disableAutoupdate;

/**
 开启自动刷新
 */
- (void)enableAutoupdate;

#pragma mark - update view
- (void)reloadSections:(NSArray<BLSectionModel *> *)sectionModels;

- (void)performUpdatesWithAnimated:(BOOL)animated;

- (void)performUpdatesWithAnimated:(BOOL)animated
                        completion:(nullable BLCollectionNodeCompletionBlock)completion;

- (void)performUpdates;

- (void)reloadData;
@end
NS_ASSUME_NONNULL_END
