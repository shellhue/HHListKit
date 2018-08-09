//
//  SimpleViewController.m
//  HHListKit
//
//  Created by shellhue on 01/08/2018.
//  Copyright © 2018 shellhue. All rights reserved.
//

#import "SettingViewController.h"
#import "HHTableNodeWrapper.h"
#import "HHSectionController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "HHSettingAvatarCellNode.h"
#import "HHSettingCommonModel.h"

@interface SettingViewController ()
@property (nonatomic) HHTableNodeWrapper *wrapper;
@property (nonatomic) HHSectionController *sectionController;
@property (nonatomic) HHSectionModel *middleSection;
@property (nonatomic) HHSectionModel *walletSection;

@property (nonatomic) HHSettingCommonModel *walletModel;
@end

@implementation SettingViewController
- (instancetype)init {
    self = [super initWithNode:[ASDisplayNode new]];
    if (self) {
        _sectionController = [HHSectionController new];
        _wrapper = [[HHTableNodeWrapper alloc] initWithSectionController:self.sectionController
                                                containingViewController:self
                                                           tableDelegate:nil
                                                         tableDataSource:nil];
        [self.wrapper enableAutoupdate];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.node.backgroundColor = [UIColor colorWithRed:235.f / 255.f green:235.f / 255.f blue:235.f / 255.f alpha:1];
    [self.node addSubnode:self.wrapper.tableNode];
    self.wrapper.tableNode.backgroundColor = UIColor.clearColor;
    [self configureSections];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.title = @"我";
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ADD" style:UIBarButtonItemStylePlain target:self action:@selector(didTapAdd)];
    UIBarButtonItem *refreshRightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(didTapRefresh)];
    self.navigationItem.rightBarButtonItems = @[rightButtonItem, refreshRightButtonItem];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.wrapper.tableNode.frame = self.node.bounds;
    
}

- (void)didTapAdd {
    [self.middleSection appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"收藏" iconName:@"collect" tapAction:^{
        NSLog(@"Collect is tapped");
    }]];
}

- (void)didTapRefresh {
    static NSInteger count = 0;
    self.walletModel.name = [NSString stringWithFormat:@"钱包%ld", count];
    [self.walletSection markModelNeedsReload:self.walletModel];
    count += 1;
}

- (void)configureSections {
    HHSectionModel *avatarSection = ({
        HHSectionModel *section = [HHSectionModel sectionModelWithCellNodeCreatorBlock:^HHCellNode *(SettingViewController *containingVC, id<HHCellNodeModelProtocol> model) {
            return [HHSettingAvatarCellNode new];
        } cellNodeTapAction:^(SettingViewController *containingVC, id<HHCellNodeModelProtocol> model) {
            NSLog(@"Avatar cell is tapped");
        }];
        [section configureWithHeaderHeight:15
                              footerHeight:20];
        [section addPlaceholderModel]; // one model one cell, no model no cell
        section;
    });
    
    self.walletSection = ({
        HHSectionModel *section = [HHSectionModel new];
        [section configureWithHeaderHeight:0
                              footerHeight:20];
        self.walletModel = [[HHSettingCommonModel alloc] initWithName:@"钱包" iconName:@"wallet" tapAction:^{
            NSLog(@"Wallet is tapped");
        }];
        [section appendNewModel:self.walletModel];
        section;
    });
    
    self.middleSection = ({
        HHSectionModel *section = [HHSectionModel new];
        [section configureWithHeaderHeight:0
                              footerHeight:20];
        [section appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"收藏" iconName:@"collect" tapAction:^{
            NSLog(@"Collect is tapped");
        }]];
        [section appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"相册" iconName:@"album" tapAction:^{
            NSLog(@"Album is tapped");
        }]];
        [section appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"卡包" iconName:@"cardwallet" tapAction:^{
            NSLog(@"Cardwallet is tapped");
        }]];
        [section appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"表情" iconName:@"emoji" tapAction:^{
            NSLog(@"Emoji is tapped");
        }]];
        section;
    });
    
    HHSectionModel *settingSection = ({
        HHSectionModel *section = [HHSectionModel new];
        [section configureWithHeaderHeight:0
                              footerHeight:20];
        [section appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"设置" iconName:@"setting" tapAction:^{
            NSLog(@"Setting is tapped");
        }]];
        section;
    });
    
    [self.sectionController appendSectionModel:avatarSection];
    [self.sectionController appendSectionModel:self.walletSection];
    [self.sectionController appendSectionModel:self.middleSection];
    [self.sectionController appendSectionModel:settingSection];
}

@end
