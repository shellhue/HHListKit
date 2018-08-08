//
//  HHTableNodeWrapper.m
//  HHListKit
//
//  Created by 黄泽宇 on 08/08/2018.
//  Copyright © 2018 黄泽宇. All rights reserved.
//

#import "HHTableNodeWrapper.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "HHCellNode.h"
#import "Aspects.h"

typedef void (^HHTableNodeBatchUpdatingBlock)(BOOL finished);

@interface HHTableNodeWrapper () <ASTableDelegate, ASTableDataSource> {
    CFRunLoopObserverRef _runLoopObserver;
}
@property (nonatomic, weak) id <ASTableDelegate> tableDelegate;
@property (nonatomic, weak) id <ASTableDataSource> tableDataSource;
@property (nonatomic, strong) HHSectionController *sectionController;
@property (nonatomic, weak) UIViewController *containingVC;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *reloadedIndexPathes;

@property (nonatomic, assign) BOOL shouldHighlightSelecting;
@property (nonatomic, assign) BOOL isPerformUpdating;
@property (nonatomic, assign) BOOL waitingForUpdating;
@property (nonatomic, assign) BOOL lastestWaitingAnimatingOption;
@property (nonatomic, strong) NSMutableArray<HHTableNodeUpdateCompletion> *completionBlocks;

@end

@implementation HHTableNodeWrapper
#pragma mark - init
- (void)dealloc {
    [self disableAutoupdate];
}

- (instancetype)initWithSectionController:(HHSectionController *)sectionController
                 containingViewController:(UIViewController *)containingVC
                            tableDelegate:(nullable id <ASTableDelegate>)delegate
                          tableDataSource:(nullable id <ASTableDataSource>)dataSource {
    NSParameterAssert((id)delegate == (id)dataSource);
    NSParameterAssert(sectionController);
    NSParameterAssert(containingVC);
    
    self = [super init];
    if (self) {
        _sectionController = sectionController;
        _tableDelegate = delegate;
        _tableDataSource = dataSource;
        _containingVC = containingVC;
        _completionBlocks = [@[] mutableCopy];
        _reloadedIndexPathes = [@[] mutableCopy];
        
        _tableNode = ({
            ASTableNode *node = [ASTableNode new];
            node.view.separatorStyle = UITableViewCellSeparatorStyleNone;
            node.view.alwaysBounceVertical = YES;
            node.allowsSelection = YES;
            node.delegate = self;
            node.dataSource = self;
            node.leadingScreensForBatching = 4;
            node.frame = UIScreen.mainScreen.bounds;
            
            HHTableNodeWrapper * __weak weakSelf = self;
            [node.view aspect_hookSelector:@selector(reloadData) withOptions:AspectPositionInstead usingBlock:^{
                [weakSelf reloadData];
            } error:nil];
            
            node;
        });
    }
    return self;
}

- (void)setTableNode:(ASTableNode *)tableNode {
    _tableNode = tableNode;
    tableNode.delegate = self;
    tableNode.dataSource = self;
}

#pragma mark - selector forward
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.tableDelegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.tableDelegate respondsToSelector:aSelector];
}

#pragma mark - collection node delegate and data source

- (NSInteger)numberOfSectionsInTableNode:(ASTableNode *)tableNode {
    if ([self.tableDataSource respondsToSelector:@selector(numberOfSectionsInTableNode:)]) {
        return [self.tableDataSource numberOfSectionsInTableNode:tableNode];
    }
    return self.sectionController.sectionNumber;
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section {
    if ([self.tableDataSource respondsToSelector:@selector(tableNode:numberOfRowsInSection:)]) {
        return [self.tableDataSource tableNode:tableNode numberOfRowsInSection:section];
    }
    return [self.sectionController modelCountForSection:section];
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.tableDataSource respondsToSelector:@selector(tableNode:nodeBlockForRowAtIndexPath:)]) {
        return [self.tableDataSource tableNode:tableNode nodeBlockForRowAtIndexPath:indexPath];
    }
    /**
     * When collection node performs batch update, it first calls this method on main thread synchronizely,
     * and then store all he node blocks. The stored node blocks will be executed on background
     * thread asynchronizely during drawing. Since data can change between the storing and
     * executing of node blocks, all the data should be fetched before storing of node blocks
     * and then catched by the node blocks. Otherwise, it will crash.
     */
    HHTableNodeWrapper * __weak weakSelf = self;
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <HHCellNodeModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if (model) {
        model = sectionModel.models[indexPath.row]; // 保证model 一定是从section model中获取
    }
    BOOL isFirstCell = [self.sectionController isFirstCellOfIndexPath:indexPath];
    BOOL isLastCell = [self.sectionController isLastCellOfIndexPath:indexPath];
    UIView *selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor colorWithRed:216.f / 255.f green:216.f / 255.f blue:216.f / 255.f alpha:1];
    selectedBackgroundView.frame = self.tableNode.frame;
    return ^ASCellNode *(){
        HHTableNodeWrapper *this = weakSelf;
        
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

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.tableDelegate respondsToSelector:@selector(tableNode:didSelectRowAtIndexPath:)]) {
        [self.tableDelegate tableNode:tableNode didSelectRowAtIndexPath:indexPath];
        return;
    }
    [tableNode deselectRowAtIndexPath:indexPath animated:YES];
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:indexPath.section];
    id <HHCellNodeModelProtocol> model = [self.sectionController modelForIndexPath:indexPath];
    if ([model respondsToSelector:@selector(cellNodeTapAction)]) {
        model.cellNodeTapAction(self.containingVC);
    } else if (sectionModel.cellNodeTapAction) {
        sectionModel.cellNodeTapAction(model, self.containingVC);
    }
}

- (ASSizeRange)tableNode:(ASTableNode *)tableNode constrainedSizeForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.tableDelegate respondsToSelector:@selector(tableNode:constrainedSizeForRowAtIndexPath:)]) {
        return [self.tableDelegate tableNode:tableNode
                         constrainedSizeForRowAtIndexPath:indexPath];
    }
    CGSize minRowsize = CGSizeMake(CGRectGetWidth(tableNode.frame), 0);
    CGSize maxRowsize = CGSizeMake(CGRectGetWidth(tableNode.frame), INFINITY);
    
    return ASSizeRangeMake(minRowsize, maxRowsize);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer && sectionModel.footerSpacerColor) {
        UIView *view = [UIView new];
        view.backgroundColor = sectionModel.footerSpacerColor;
        return view;
    } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightView) {
        return sectionModel.footerView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
        return sectionModel.footerHeight;
    } else if (sectionModel.footerType == HHSectionModelFooterHeaderTypeFixedHeightView) {
        return sectionModel.footerHeight;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer && sectionModel.headerSpacerColor) {
        UIView *view = [UIView new];
        view.backgroundColor = sectionModel.headerSpacerColor;
        return view;
    } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightView) {
        return sectionModel.headerView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    HHSectionModel *sectionModel = [self.sectionController sectionModelForSection:section];
    if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightSpacer) {
        return sectionModel.headerHeight;
    } else if (sectionModel.headerType == HHSectionModelFooterHeaderTypeFixedHeightView) {
        return sectionModel.headerHeight;
    }
    return 0;
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
    HHTableNodeWrapper * __weak weakSelf = self;
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

- (void)performUpdatesWithAnimated:(BOOL)animated completion:(nullable HHTableNodeUpdateCompletion)completion {
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
    [self.tableNode waitUntilAllUpdatesAreProcessed];
    if (!self.sectionController.isDataChanged) {
        [self didFinishUpdatingWithFinished:YES];
        return;
    }
    [self.sectionController willFetchChangedData];
    [self addVisibleCellNodeToReloadedIndexPathes];
    if (self.sectionController.justPerformReloadTotally) {
        [self.sectionController didFetchChangedData];
        [self.sectionController dataWillSynchronizeToUI];
        [self.tableNode reloadDataWithCompletion:^{
            [self.sectionController dataDidSynchronizeToUI];
            [self didFinishUpdatingWithFinished:YES];
        }];
    } else {
        [self.tableNode performBatchAnimated:animated updates:^{
            [self.tableNode reloadSections:self.sectionController.updatedSections withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableNode deleteSections:self.sectionController.deletedSections withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableNode insertSections:self.sectionController.insertedSections withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableNode reloadRowsAtIndexPaths:self.sectionController.updatedIndexPathes withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableNode deleteRowsAtIndexPaths:self.sectionController.deletedIndexPathes withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableNode insertRowsAtIndexPaths:self.sectionController.insertedIndexPathes withRowAnimation:UITableViewRowAnimationAutomatic];
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
    [self.completionBlocks enumerateObjectsUsingBlock:^(HHTableNodeUpdateCompletion  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj(finished);
    }];
    [self.completionBlocks removeAllObjects];
}

- (void)addVisibleCellNodeToReloadedIndexPathes {
    [self.reloadedIndexPathes addObjectsFromArray:self.sectionController.updatedIndexPathes];
    if (self.sectionController.updatedSections.count) {
        [self.tableNode.visibleNodes enumerateObjectsUsingBlock:^(__kindof ASCellNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [self.tableNode indexPathForNode:obj];
            if (indexPath && [self.sectionController.updatedSections containsIndex:indexPath.section]) {
                [self.reloadedIndexPathes addObject:indexPath];
            }
        }];
    }
    
    if (self.sectionController.insertedSections.count == self.sectionController.sectionModels.count || self.sectionController.justPerformReloadTotally) {
        [self.tableNode.visibleNodes enumerateObjectsUsingBlock:^(__kindof ASCellNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPath = [self.tableNode indexPathForNode:obj];
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
