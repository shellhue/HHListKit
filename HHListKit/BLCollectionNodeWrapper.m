//
//  BLCollectionNodeBoilerplate.m
//  BLKit
//
//  Created by 黄泽宇 on 17/03/2018.
//

#import "BLCollectionNodeWrapper.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "BLBaseCellNode.h"
#import "extobjc.h"
#import "UIColor+BLKit.h"
#import "Aspects.h"

typedef void (^BLCollectionNodeBatchUpdatingBlock)(BOOL finished);

@interface BLCollectionNodeWrapper () <ASCollectionDelegate, ASCollectionDataSource> {
    CFRunLoopObserverRef _runLoopObserver;
}
@property (nonatomic, weak) id <ASCollectionDelegate> collectionNodeDelegate;
@property (nonatomic, weak) id <ASCollectionDataSource> collectionDataSource;
@property (nonatomic) BLSectionController *sectionController;
@property (nonatomic, weak) UIViewController *contextVC;
@property (nonatomic) NSMutableArray<NSIndexPath *> *reloadedIndexPathes;
/**
 是否高亮点击
 */
@property (nonatomic) BOOL shouldHighlightSelecting;

/**
 是否正在更新
 */
@property (nonatomic) BOOL isPerformUpdating;

/**
 是否有人等待更新
 */
@property (nonatomic) BOOL waitingForUpdating;

/**
 排队等待更新的完成回调
 */
@property (nonatomic) NSMutableArray<BLCollectionNodeCompletionBlock> *completionBlocks;

/**
 最近一次等待请求的动画选项，是否需要动画
 */
@property (nonatomic) BOOL lastestWaitingAnimatingOption;

@end

@implementation BLCollectionNodeWrapper
#pragma mark - init
- (void)dealloc {
    [self disableAutoupdate];
}

- (instancetype)initWithSectionController:(BLSectionController *)sectionController
                    contextViewController:(UIViewController *)contextVC
                   collectionNodeDelegate:(id <ASCollectionDelegate>)delegate
                     collectionDataSource:(id <ASCollectionDataSource>)dataSource {
    NSParameterAssert((id)delegate == (id)dataSource);
    NSParameterAssert(sectionController);
    NSParameterAssert(contextVC);

    self = [super init];
    if (self) {
        _sectionController = sectionController;
        _collectionDataSource = dataSource;
        _collectionNodeDelegate = delegate;
        _contextVC = contextVC;
        _completionBlocks = [@[] mutableCopy];
        _reloadedIndexPathes = [@[] mutableCopy];
        
        _collectionNode = ({
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            flowLayout.minimumLineSpacing = 0;
            flowLayout.minimumInteritemSpacing = 0;
            ASCollectionNode *node = [[ASCollectionNode alloc] initWithCollectionViewLayout:flowLayout];
            [node registerSupplementaryNodeOfKind:UICollectionElementKindSectionHeader];
            [node registerSupplementaryNodeOfKind:UICollectionElementKindSectionFooter];
            node.view.alwaysBounceVertical = YES;
            node.allowsSelection = YES;
            node.delegate = self;
            node.dataSource = self;
            node.leadingScreensForBatching = 4;
            node.frame = UIScreen.mainScreen.bounds;
            @weakify(self);

            [node.view aspect_hookSelector:@selector(reloadData) withOptions:AspectPositionInstead usingBlock:^{
                @strongify(self);
                [self reloadData];
            } error:nil];
            
            node;
        });
    }
    return self;
}

- (void)setCollectionNode:(ASCollectionNode *)collectionNode {
    _collectionNode = collectionNode;
    collectionNode.delegate = self;
    collectionNode.dataSource = self;
}

#pragma mark - selector forward

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.collectionNodeDelegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.collectionNodeDelegate respondsToSelector:aSelector];
}

#pragma mark - collection node delegate and data source

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode {
    if ([self.collectionDataSource respondsToSelector:@selector(numberOfSectionsInCollectionNode:)]) {
        return [self.collectionDataSource numberOfSectionsInCollectionNode:collectionNode];
    }
    return self.sectionController.sectionNumber;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section {
    if ([self.collectionDataSource respondsToSelector:@selector(collectionNode:numberOfItemsInSection:)]) {
        return [self.collectionDataSource collectionNode:collectionNode numberOfItemsInSection:section];
    }
    return [self.sectionController modelCountForSection:section];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionDataSource respondsToSelector:@selector(collectionNode:nodeBlockForItemAtIndexPath:)]) {
        return [self.collectionDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
    }
    /* collection node perform batch update 是异步的，在perform batch update过程中，
     section controller 数据会变化，因此经常奔溃，但perform batch update在异步开始前，
     collection node会先准备所有数据，此时必须提取出section controller 的数据，让 block
     捕捉，从而防止异步过程中section controller数据变化导致的崩溃
     */
    BLCollectionNodeWrapper * __weak weakSelf = self;
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <BLCellNodeViewModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if (model) {
        model = sectionModel.models[indexPath.row]; // 保证model 一定是从section model中获取
    }
    BOOL isFirstCell = [self.sectionController isFirstCellOfIndexPath:indexPath];
    BOOL isLastCell = [self.sectionController isLastCellOfIndexPath:indexPath];
    return ^ASCellNode *(){
        BLCollectionNodeWrapper *this = weakSelf;
        if ([model respondsToSelector:@selector(cellNodeDelegate)] && ![model cellNodeDelegate] && [model respondsToSelector:@selector(setCellNodeDelegate:)]) {
            model.cellNodeDelegate = this.contextVC;
        }
        
        BLCellNode *cell;
        NSAssert([model respondsToSelector:@selector(cellNode)] || sectionModel.cellNodeCreatorBlock, @"model 和section model不能都不提供cell node");
        if ([model respondsToSelector:@selector(cellNode)]) {
            cell = [model cellNode];
        } else {
            cell = sectionModel.cellNodeCreatorBlock(model, indexPath);
        }
        cell.isFirstCell = isFirstCell;
        cell.isLastCell = isLastCell;
        if (this.shouldHighlightSelecting && !cell.selectedBackgroundView) {
            UIView *selectedBackgroundView = [UIView new];
            selectedBackgroundView.backgroundColor = UIColor.bl_216_216_216;
            cell.selectedBackgroundView = selectedBackgroundView;
        }
        
        if ([this.reloadedIndexPathes containsObject:indexPath]) {
            cell.neverShowPlaceholders = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                cell.neverShowPlaceholders = NO;
                [this.reloadedIndexPathes removeObject:indexPath];
                [cell invalidateCalculatedLayout];
            });
        }
        if ([cell isKindOfClass:[BLBaseCellNode class]]) {
            [(BLBaseCellNode *)cell configureWithModel:model];
        }
        NSAssert(cell, @"cell 不能为空");
        cell = cell ?: [BLCellNode new];
        return cell;
    };
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:didSelectItemAtIndexPath:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode didSelectItemAtIndexPath:indexPath];
        return;
    }
    [collectionNode deselectItemAtIndexPath:indexPath animated:YES];
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <BLCellNodeViewModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if ([model respondsToSelector:@selector(tapAction)] && model.tapAction) {
        model.tapAction(self.contextVC, model);
    } else if (sectionModel.cellNodeTapAction) {
        sectionModel.cellNodeTapAction(self.contextVC, model, indexPath);
    }
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:constrainedSizeForItemAtIndexPath:)]) {
        return [self.collectionNodeDelegate collectionNode:collectionNode
                         constrainedSizeForItemAtIndexPath:indexPath];
    }
    CGSize minItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), 0);
    CGSize maxItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), INFINITY);
    
    return ASSizeRangeMake(minItemSize, maxItemSize);
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionDataSource respondsToSelector:@selector(collectionNode:nodeForSupplementaryElementOfKind:atIndexPath:)]) {
        return [self.collectionDataSource collectionNode:collectionNode
                       nodeForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    
    if (kind == UICollectionElementKindSectionHeader) {
        if (sectionModel.headerType == BLSectionModelFooterHeaderTypeFixHeightSpacer) {
            ASCellNode *header = [ASCellNode new];
            if (@available(iOS 11.0, *)) {
                header.layer.zPosition = 0;
            }
            header.backgroundColor = sectionModel.headerSpacerColor;
            return  header;
        } else if (sectionModel.headerType == BLSectionModelFooterHeaderTypeFixHeightNode) {
            if (@available(iOS 11.0, *)) {
                sectionModel.header.layer.zPosition = 0;
            }
            return  sectionModel.header;
        } else if (sectionModel.headerType == BLSectionModelFooterHeaderTypeSelfCalculateHeightNode) {
            if (@available(iOS 11.0, *)) {
                sectionModel.header.layer.zPosition = 0;
            }
            return  sectionModel.header;
        }
    } else if (kind == UICollectionElementKindSectionFooter) {
        if (sectionModel.footerType == BLSectionModelFooterHeaderTypeFixHeightSpacer) {
            ASCellNode *footer = [ASCellNode new];
            footer.backgroundColor = sectionModel.footerSpacerColor;
            return  footer;
        } else if (sectionModel.footerType == BLSectionModelFooterHeaderTypeFixHeightNode) {
            return  sectionModel.footer;
        } else if (sectionModel.footerType == BLSectionModelFooterHeaderTypeSelfCalculateHeightNode) {
            return  sectionModel.footer;
        }
    }
    
    return nil;
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willDisplaySupplementaryElementWithNode:(ASCellNode *)node {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:willDisplaySupplementaryElementWithNode:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode willDisplaySupplementaryElementWithNode:node];
        return;
    }
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willDisplayItemWithNode:(ASCellNode *)node {
    if (self.collectionNodeDelegate && [self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:willDisplayItemWithNode:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode willDisplayItemWithNode:node];
    }
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didEndDisplayingItemWithNode:(ASCellNode *)node {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:didEndDisplayingItemWithNode:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode didEndDisplayingItemWithNode:node];
    }
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didEndDisplayingSupplementaryElementWithNode:(ASCellNode *)node {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:didEndDisplayingSupplementaryElementWithNode:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode didEndDisplayingSupplementaryElementWithNode:node];
        return;
    }
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section {
    id <ASCollectionDelegateFlowLayout> flowLayoutDelegate = (id <ASCollectionDelegateFlowLayout>)self.collectionNodeDelegate;
    if ([flowLayoutDelegate respondsToSelector:@selector(collectionNode:sizeRangeForHeaderInSection:)]) {
        return [flowLayoutDelegate collectionNode:collectionNode sizeRangeForHeaderInSection:section];
    }
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.headerType == BLSectionModelFooterHeaderTypeFixHeightSpacer) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.headerHeight));
    } else if (sectionModel.headerType == BLSectionModelFooterHeaderTypeFixHeightNode) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.headerHeight));
    } else if (sectionModel.headerType == BLSectionModelFooterHeaderTypeSelfCalculateHeightNode) {
        CGSize minItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), 0);
        CGSize maxItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), INFINITY);
        
        return ASSizeRangeMake(minItemSize, maxItemSize);
    }
    
    return ASSizeRangeZero;
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section {
    id <ASCollectionDelegateFlowLayout> flowLayoutDelegate = (id <ASCollectionDelegateFlowLayout>)self.collectionNodeDelegate;
    if ([flowLayoutDelegate respondsToSelector:@selector(collectionNode:sizeRangeForFooterInSection:)]) {
        return [flowLayoutDelegate collectionNode:collectionNode sizeRangeForFooterInSection:section];
    }
    
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.footerType == BLSectionModelFooterHeaderTypeFixHeightSpacer) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.footerHeight));
    } else if (sectionModel.footerType == BLSectionModelFooterHeaderTypeFixHeightNode) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.footerHeight));
    } else if (sectionModel.footerType == BLSectionModelFooterHeaderTypeSelfCalculateHeightNode) {
        CGSize minItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), 0);
        CGSize maxItemSize = CGSizeMake(CGRectGetWidth(collectionNode.frame), INFINITY);
        
        return ASSizeRangeMake(minItemSize, maxItemSize);
    }
    
    return ASSizeRangeZero;
}

- (NSArray<NSString *> *)collectionNode:(ASCollectionNode *)collectionNode supplementaryElementKindsInSection:(NSInteger)section {
    if ([self.collectionDataSource respondsToSelector:@selector(collectionNode:supplementaryElementKindsInSection:)]) {
        return [self.collectionDataSource collectionNode:collectionNode supplementaryElementKindsInSection:section];
    }
    
    BLSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    NSMutableArray *kinds = [@[] mutableCopy];
    if (sectionModel.headerType != BLSectionModelFooterHeaderTypeNone) {
        [kinds addObject:UICollectionElementKindSectionHeader];
    }
    
    if (sectionModel.footerType != BLSectionModelFooterHeaderTypeNone) {
        [kinds addObject:UICollectionElementKindSectionFooter];
    }
    return kinds;
}

#pragma mark - config
- (void)enableSelectHighlight {
    self.shouldHighlightSelecting = YES;
}

- (void)disableSelectHighlight {
    self.shouldHighlightSelecting = NO;
}

- (void)disableAutoupdate {
    if (_runLoopObserver) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _runLoopObserver, kCFRunLoopCommonModes);
        CFRelease(_runLoopObserver);
        _runLoopObserver = nil;
    }
}

- (void)enableAutoupdate {
    if (_runLoopObserver) {
        return;
    }
    // 添加runloop自动监听
    BLCollectionNodeWrapper * __weak weakSelf = self;
    _runLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting | kCFRunLoopExit, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        [weakSelf performUpdates];
    });
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), _runLoopObserver,  kCFRunLoopCommonModes);
}

#pragma mark - ui update 操作
- (void)reloadSections:(NSArray<BLSectionModel *>*)sectionModels {
    if (!sectionModels.count) {
        return;
    }
    
    [sectionModels enumerateObjectsUsingBlock:^(BLSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.sectionController markSectionModelNeedsReload:obj];
    }];
    [self performUpdatesWithAnimated:YES];
}

- (void)performUpdatesWithAnimated:(BOOL)animated completion:(nullable BLCollectionNodeCompletionBlock)completion {
    NSAssert([NSThread isMainThread], @"必须在主线程");
    if (completion) {
        [self.completionBlocks addObject:completion];
    }
    if (self.isPerformUpdating) {
        self.lastestWaitingAnimatingOption = animated;
        self.waitingForUpdating = YES;
        return;
    }
    [self _performUpdatesWithAnimated:animated];
}

- (void)_performUpdatesWithAnimated:(BOOL)animated {
    if (self.isPerformUpdating) {
        return;
    }
    self.isPerformUpdating = YES;
    NSAssert(NSThread.isMainThread, @"必须在主线程调用");
    [self.collectionNode waitUntilAllUpdatesAreProcessed];
    if (!self.sectionController.isDataChanged) {
        [self didFinishUpdatingWithFinished:YES];
        return;
    }
    [self.sectionController willFetchChangedData];
    [self addVisibleCellNodeToReloadedIndexPathes];
    if (self.sectionController.justPerformReloadTotally) {
        [self.sectionController didFetchChangedData];
        [self.sectionController dataWillSynchronizeToUI];
        [self.collectionNode reloadDataWithCompletion:^{
            [self.sectionController dataDidSynchronizeToUI];
            [self didFinishUpdatingWithFinished:YES];
        }];
    } else {
        [self.collectionNode performBatchAnimated:animated updates:^{
            [self.collectionNode reloadSections:self.sectionController.updatedSections];
            [self.collectionNode deleteSections:self.sectionController.deletedSections];
            [self.collectionNode insertSections:self.sectionController.insertedSections];
            [self.collectionNode reloadItemsAtIndexPaths:self.sectionController.updatedIndexPathes];
            [self.collectionNode deleteItemsAtIndexPaths:self.sectionController.deletedIndexPathes];
            [self.collectionNode insertItemsAtIndexPaths:self.sectionController.insertedIndexPathes];
            [self.sectionController didFetchChangedData];
            [self.sectionController dataWillSynchronizeToUI];
        } completion:^(BOOL finished) {
            [self.sectionController dataDidSynchronizeToUI];
            [self didFinishUpdatingWithFinished:finished];
        }];
    }
}

- (void)didFinishUpdatingWithFinished:(BOOL)finished {
    NSAssert(NSThread.isMainThread, @"必须在主线程调用");
    self.isPerformUpdating = NO;
    [self.reloadedIndexPathes removeAllObjects];
    if (self.waitingForUpdating) {
        self.waitingForUpdating = NO;
        [self _performUpdatesWithAnimated:self.lastestWaitingAnimatingOption];
        return;
    }
    [self.completionBlocks enumerateObjectsUsingBlock:^(BLCollectionNodeCompletionBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj(finished);
    }];
    [self.completionBlocks removeAllObjects];
}

- (void)addVisibleCellNodeToReloadedIndexPathes {
    [self.reloadedIndexPathes addObjectsFromArray:self.sectionController.updatedIndexPathes];
    if (self.sectionController.updatedSections.count) {
        [self.collectionNode.visibleNodes enumerateObjectsUsingBlock:^(__kindof ASCellNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [self.collectionNode indexPathForNode:obj];
            if (indexPath && [self.sectionController.updatedSections containsIndex:indexPath.section]) {
                [self.reloadedIndexPathes addObject:indexPath];
            }
        }];
    }
    
    if (self.sectionController.insertedSections.count == self.sectionController.sectionModels.count || self.sectionController.justPerformReloadTotally) {
        [self.collectionNode.visibleNodes enumerateObjectsUsingBlock:^(__kindof ASCellNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [self.collectionNode indexPathForNode:obj];
            if (indexPath) {
                [self.reloadedIndexPathes addObject:indexPath];
            }
        }];
    }

}

- (void)performUpdatesWithAnimated:(BOOL)animated {
    [self performUpdatesWithAnimated:animated completion:nil];
}

- (void)performUpdates {
    [self performUpdatesWithAnimated:NO];
}

- (void)reloadData {
    [self.sectionController setJustPerformReloadTotallyToYES];
    [self performUpdates];
}
@end
