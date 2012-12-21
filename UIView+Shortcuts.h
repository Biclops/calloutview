//
//  UIView+Shortcuts.h
//  CalloutViewSamples
//
//  Created by DTan on 12/20/12.
//
//

#import <Foundation/Foundation.h>

//
// UIView frame helpers - shorten the code
//

@interface UIView (Shortcuts)
@property (nonatomic, assign) CGPoint $origin;
@property (nonatomic, assign) CGSize $size;
@property (nonatomic, assign) CGFloat $x, $y, $width, $height;      // normal rect properties
@property (nonatomic, assign) CGFloat $left, $top, $right, $bottom; // these will stretch/shrink the rect
@end