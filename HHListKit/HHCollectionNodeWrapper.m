//
//  HHCollectionNodeBoilerplate.m
//  HHListKit
//
//  Created by shelllhue on 17/03/2018.
//

#import "HHCollectionNodeWrapper.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "HHCellNode.h"
#import "Aspects.h"

typedef void (^HHCollectionNodeBatchUpdatingBlock)(BOOL finished);

@interface HHCollectionNodeWrapper () <ASCollectionDelegate, ASCollectionDataSource> {
    CFRunLoopObserverRef _runLoopObserver;
}
@property (nonatomic, weak) id <ASCollectionDelegate> collectionNodeDelegate;
@property (nonatomic, weak) id <ASCollectionDataSource> collectionDataSource;
@property (nonatomic, strong) HHSectionController *sectionController;
@property (nonatomic, weak) UIViewController *containingVC;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *reloadedIndexPathes;

@property (nonatomic, assign) BOOL shouldHighlightSelecting;
@property (nonatomic, assign) BOOL isPerformUpdating;
@property (nonatomic, assign) BOOL waitingForUpdating;
@property (nonatomic, assign) BOOL lastestWaitingAnimatingOption;
@property (nonatomic, strong) NSMutableArray<HHCollectionNodeUpdateCompletion> *completionBlocks;

@end

@implementation HHCollectionNodeWrapper
#pragma mark - init
- (void)dealloc {
    [self disableAutoupdate];
}

- (instancetype)initWithSectionController:(HHSectionController *)sectionController
                    containingViewController:(UIViewController *)containingVC
                   collectionNodeDelegate:(id <ASCollectionDelegate>)delegate
                     collectionDataSource:(id <ASCollectionDataSource>)dataSource {
    NSParameterAssert((id)delegate == (id)dataSource);
    NSParameterAssert(sectionController);
    NSParameterAssert(containingVC);

    self = [super init];
    if (self) {
        _sectionController = sectionController;
        _collectionDataSource = dataSource;
        _collectionNodeDelegate = delegate;
        _containingVC = containingVC;
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
            
            HHCollectionNodeWrapper * __weak weakSelf = self;
            [node.view aspect_hookSelector:@selector(reloadData) withOptions:AspectPositionInstead usingBlock:^{
                [weakSelf reloadData];
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
    /**
     * When collection node performs batch update, it first calls this method on main thread synchronizely,
     * and then store all he node blocks. The stored node blocks will be executed on background
     * thread asynchronizely during drawing. Since data can change between the storing and
     * executing of node blocks, all the data should be fetched before storing of node blocks
     * and then catched by the node blocks. Otherwise, it will crash.
     */
    HHCollectionNodeWrapper * __weak weakSelf = self;
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <HHCellNodeModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if (model) {
        model = sectionModel.models[indexPath.row]; // 保证model 一定是从section model中获取
    }
    BOOL isFirstCell = [self.sectionController isFirstCellOfIndexPath:indexPath];
    BOOL isLastCell = [self.sectionController isLastCellOfIndexPath:indexPath];
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor colorWithRed:216.f / 255.f green:216.f / 255.f blue:216.f / 255.f alpha:1];
    selectedBackgroundView.frame = self.collectionNode.frame;
    return ^ASCellNode *(){
        HHCollectionNodeWrapper *this = weakSelf;

        HHCellNode *cell;
        NSAssert([model respondsToSelector:@selector(cellNodeBlock)] || sectionModel.cellNodeBlock, @"None of model or section model provides cell node creator block");
        if ([model respondsToSelector:@selector(cellNodeBlock)]) {
            cell = model.cellNodeBlock(this.containingVC);
        } else if (sectionModel.cellNodeBlock) {
            cell = sectionModel.cellNodeBlock(model, this.containingVC);
        }
        cell.isFirstCell = isFirstCell;
        cell.isLastCell = isLastCell;
        if (this.shouldHighlightSelecting && !cell.selectedBackgroundView) {
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
        if ([cell isKindOfClass:[HHCellNode class]]) {
            [(HHCellNode *)cell hh_configureWithModel:model];
        }
        NSAssert(cell, @"cell 不能为空");
        cell = cell ?: [HHCellNode new];
        return cell;
    };
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.collectionNodeDelegate respondsToSelector:@selector(collectionNode:didSelectItemAtIndexPath:)]) {
        [self.collectionNodeDelegate collectionNode:collectionNode didSelectItemAtIndexPath:indexPath];
        return;
    }
    [collectionNode deselectItemAtIndexPath:indexPath animated:YES];
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <HHCellNodeModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if ([model respondsToSelector:@selector(cellNodeTapAction)]) {
        model.cellNodeTapAction(self.containingVC);
    } else if (sectionModel.cellNodeTapAction) {
        sectionModel.cellNodeTapAction(model, self.containingVC);
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
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    
    if (kind == UICollectionElementKindSectionHeader) {
        if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
            ASCellNode *header = [ASCellNode new];
            if (@available(iOS 11.0, *)) {
                header.layer.zPosition = 0;
            }
            header.backgroundColor = sectionModel.headerSpacerColor;
            return  header;
        } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightNode) {
            if (@available(iOS 11.0, *)) {
                sectionModel.header.layer.zPosition = 0;
            }
            return  sectionModel.header;
        } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode) {
            if (@available(iOS 11.0, *)) {
                sectionModel.header.layer.zPosition = 0;
            }
            return  sectionModel.header;
        }
    } else if (kind == UICollectionElementKindSectionFooter) {
        if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
            ASCellNode *footer = [ASCellNode new];
            footer.backgroundColor = sectionModel.footerSpacerColor;
            return  footer;
        } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightNode) {
            return  sectionModel.footer;
        } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode) {
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
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.headerHeight));
    } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightNode) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.headerHeight));
    } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode) {
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
    
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.footerHeight));
    } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightNode) {
        return  ASSizeRangeMake(CGSizeMake(collectionNode.frame.size.width, sectionModel.footerHeight));
    } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeHeightSelfCalculatedNode) {
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
    
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    NSMutableArray *kinds = [@[] mutableCopy];
    if (sectionModel.headerType != HHSectionModelFooterHeaderTypeNone) {
        [kinds addObject:UICollectionElementKindSectionHeader];
    }
    
    if (sectionModel.footerType != HHSectionModelFooterHeaderTypeNone) {
        [kinds addObject:UICollectionElementKindSectionFooter];
    }
    return kinds;
}

#pragma mark - config
- (void)enableSelectingHighlight {
    self.shouldHighlightSelecting = YES;
}

- (void)disableSelectingHighlight {
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
    // add runloop monitor
    HHCollectionNodeWrapper * __weak weakSelf = self;
    _runLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting | kCFRunLoopExit, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        [weakSelf performUpdates];
    });
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), _runLoopObserver,  kCFRunLoopCommonModes);
}

#pragma mark - ui updating
- (void)reloadSections:(NSArray<HHSectionModel *>*)sectionModels {
    if (!sectionModels.count) {
        return;
    }
    
    [sectionModels enumerateObjectsUsingBlock:^(HHSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.sectionController markSectionModelNeedsReload:obj];
    }];
    [self performUpdatesWithAnimated:YES];
}

- (void)performUpdatesWithAnimated:(BOOL)animated completion:(nullable HHCollectionNodeUpdateCompletion)completion {
    NSAssert(NSThread.isMainThread, @"Should be called on main thread!");
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
    NSAssert(NSThread.isMainThread, @"Should be called on main thread!");
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
    NSAssert(NSThread.isMainThread, @"Should be called on main thread!");
    self.isPerformUpdating = NO;
    [self.reloadedIndexPathes removeAllObjects];
    if (self.waitingForUpdating) {
        self.waitingForUpdating = NO;
        [self _performUpdatesWithAnimated:self.lastestWaitingAnimatingOption];
        return;
    }
    [self.completionBlocks enumerateObjectsUsingBlock:^(HHCollectionNodeUpdateCompletion  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
