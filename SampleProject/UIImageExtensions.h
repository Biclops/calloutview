//
//  UIImageExtensions.h
//  Realist
//
//  Created by DTan on 6/22/11.
//  Copyright 2011 CoreLogic. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage(Extensions)
+ (UIImage*)imageFromMainBundleFile:(NSString*)aFileName;
+ (UIImage *)imageForSize:(CGSize)size scale:(float)scale withDrawingBlock:(void(^)(CGContextRef))drawingBlock;
+ (UIImage *)imageForSize:(CGSize)size withDrawingBlock:(void(^)(CGContextRef))drawingBlock;
@end
