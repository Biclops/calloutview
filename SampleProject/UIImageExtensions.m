//
//  UIImageExtensions.m
//  Realist
//
//  Created by DTan on 6/22/11.
//  Copyright 2011 CoreLogic. All rights reserved.
//

#import "UIImageExtensions.h"


@implementation UIImage(Extensions)
//http://stackoverflow.com/questions/924740/dispelling-the-uiimage-imagenamed-fud
+ (UIImage*)imageFromMainBundleFile:(NSString*)aFileName  {
    NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, aFileName]];
}

+ (UIImage *)imageForSize:(CGSize)size scale:(float)scale withDrawingBlock:(void(^)(CGContextRef))drawingBlock {
    if(size.width <= 0 || size.width <= 0){
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();   
    drawingBlock(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
#if !__has_feature(objc_arc)
    return [image autorelease];
#else
    return image;
#endif
}

// https://github.com/kgn/BBlock
+ (UIImage *)imageForSize:(CGSize)size withDrawingBlock:(void(^)(CGContextRef))drawingBlock {
    // 0.0f scale uses the device appropriate scale 
    return [UIImage imageForSize:size scale:0.0f withDrawingBlock:drawingBlock];
}
@end
