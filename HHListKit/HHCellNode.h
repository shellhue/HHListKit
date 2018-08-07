//
//  HHCellNode.h
//  HHListKit
//
//  Created by shelllhue on 06/03/2018.
//

#import <AsyncDisplayKit/ASCellNode.h>
#import "HHCellNodeModelProtocol.h"

@interface HHCellNode : ASCellNode

/**
 * Boolean value indicating whether it is the last cell of the containing section
 * The value of this property is set before @selector(hh_configureWithModel:) is called,
 *      so it can be used in @selector(hh_configureWithModel:)
 */
@property (nonatomic, assign) BOOL isLastCell;

/**
 * Boolean value indicating whether it is the first cell of the containing section
 * The value of this property is set before @selector(hh_configureWithModel:) is called,
 *      so it can be used in @selector(hh_configureWithModel:)
 */
@property (nonatomic, assign) BOOL isFirstCell;

/**
 * @abstract Chance to configure cell with the corresponding model
 * @param model The corresponding model
 * Override this method to configure cell with the corresponding model
 *     when your cell subclasses HHCellNode, there is no need to call super
 */
- (void)hh_configureWithModel:(id <HHCellNodeModelProtocol>)model;
@end
