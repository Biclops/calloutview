//
//  CustomAnnotationView.m
//  CalloutViewSamples
//
//  Created by DTan on 12/21/12.
//
//

#import "CustomPinAnnotationView.h"

@implementation CustomPinAnnotationView

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    if(view == nil) {
        view = [super hitTest:point withEvent:event];
    }

    return view;
}
@end