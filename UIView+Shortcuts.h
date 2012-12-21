//
//  UIView+Shortcuts.h
//  CalloutViewSamples
//
//  Created by DTan on 12/20/12.
//
//

#import <Foundation/Foundation.h>

//
// UIView shortcuts - shorten the code
//

@interface UIView (Shortcuts)
@property (nonatomic, assign) CGPoint $origin;
@property (nonatomic, assign) CGSize $size;
@property (nonatomic, assign) CGFloat $x, $y, $width, $height;      // normal rect properties
@property (nonatomic, assign) CGFloat $left, $top, $right, $bottom; // setting these will stretch/shrink the rect, based on frame
@end