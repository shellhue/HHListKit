HHListKit
==============

A data-driven ASCollectionNode and ASTableNode wrapper for building fast and flexible lists.

Main Features
==============

- Smooth asynchronous user interfaces due to texture backing
- Never need call `performBatchUpdates(_:, completion:)` or `reloadData()` again
- Manage section easily
- Create lists with multiple data types

Usage
==============

#### 1. Firstly, create list wrapper and layout the wrapped list node
```objc
@interface ViewController ()
@property (nonatomic) HHTableNodeWrapper *listWrapper; // the list wrapper
@property (nonatomic) HHSectionController *sectionController; // the binded section controller

// saved section which will change dynamicly
@property (nonatomic) HHSectionModel *middleSection;
@property (nonatomic) HHSectionModel *walletSection;

// saved model that will change dynamicly
@property (nonatomic) HHSettingCommonModel *walletModel;
@end

@implementation ViewController
- (instancetype)init {
    self = [super initWithNode:[ASDisplayNode new]];
    if (self) {
        _sectionController = [HHSectionController new];
        _listWrapper = [[HHTableNodeWrapper alloc] initWithSectionController:self.sectionController
                                                containingViewController:self
                                                           tableDelegate:nil
                                                         tableDataSource:nil];
        [self.listWrapper enableAutoupdateWithAutoupdatingAnimated:NO]; // enable autoupdate
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // add the wrapped list node to supernode
    [self.node addSubnode:self.listWrapper.tableNode];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // layout the wrapped list node
    self.listWrapper.tableNode.frame = self.node.bounds;
    
}
@end
```


#### 2. Secondly, configure sections
```objc
@implementation ViewController
// ...
- (void)viewDidLoad {
    // ...
    [self configureSections];
    // ...
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
```


#### 3. Thirdly, cell model implement `HHCellNodeModelProtocol`

Section model can be initialized with cell node creator block and cell tap action, then the cell model needn't implement `HHCellNodeModelProtocol`. Otherwise the cell model has to implement `HHCellNodeModelProtocol`

```objc
@implementation HHSettingCommonModel
- (HHCellNodeBlock)cellNodeBlock {
    return ^HHCellNode *(SettingViewController *containingVC) {
        return [HHSettingCommonCellNode new];
    };
}

- (HHCellNodeTapAction)cellNodeTapAction {
    return ^(SettingViewController *containingVC) {
        self.tapAction();
    };
}
@end
```

#### 4. Fourthly, delete/insert/update cell

It is very common to delete/insert/update cell dynamicly. It's easy to do this. But first, you should save the changed section model and cell model to a property. Then just insert/delete/update the corresponding cell model in that section model.

```objc
- (void)didTapAdd {
    [self.middleSection appendNewModel:[[HHSettingCommonModel alloc] initWithName:@"收藏" iconName:@"collect" tapAction:^{
        NSLog(@"Collect is tapped");
    }]];
}

- (void)didTapRefresh {
    self.walletModel.name = @"钱包updated";
    [self.walletSection markModelNeedsReload:self.walletModel];
}
```

If autoupdate is enabled, insert/delete cell model will be synchronized to UI automaticaly. But you should mark the updated model needs reload instead. Just like above.

Installation
==============

1. Add `pod 'HHListKit'` to your Podfile.
2. Run `pod install` or `pod update`.
3. Import \<HHListKit/HHListKit.h\>.


Requirements
==============

- iOS 9.0+


License
==============

`HHListKit` is MIT-licensed.
