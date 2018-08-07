//
//  HHCellNodeModelProtocol.h
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HHCellNode;
@protocol HHCellNodeModelProtocol;
typedef void (^HHCellNodeTapAction)(__kindof UIViewController *containingVC);
typedef HHCellNode * _Nonnull (^HHCellNodeBlock)(__kindof UIViewController *containingVC);

@protocol HHCellNodeModelProtocol <NSObject>

@optional

/**
 * The corresponding cell node creator block of this model
 *
 * No memory cycle retaining
 */
- (HHCellNodeBlock)cellNodeBlock;

/**
 * The corresponding cell node tap action of this model
 *
 * No memory cycle retaining
 */
- (HHCellNodeTapAction)cellNodeTapAction;

@end
NS_ASSUME_NONNULL_END
