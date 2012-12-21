#import "SMCalloutView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Shortcuts.h"

//
// Callout View.
//

NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView = 1.0 / 3.0;

#define ANCHOR_MARGIN 37             // the smallest possible distance from the edge of our control to the "tip" of the anchor, from either left or right

@implementation SMCalloutView {
    SMCalloutArrowDirection _arrowDirection;
    BOOL _popupCancelled;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _presentAnimation = SMCalloutAnimationBounce;
        _dismissAnimation = SMCalloutAnimationFade;
        
        // default
        _margins = CGPointMake(10, 10);
        
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

#pragma mark - layout/offsets/sizing
- (void)layoutSubviews {
    self.contentView.$origin = CGPointMake(0, 0);
}

- (void)rebuildSubviews {
    // remove and re-add our appropriate subviews in the appropriate order
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setNeedsDisplay];

    if (self.contentView) {
        [self addSubview:self.contentView];
    }
}

- (CGFloat)calloutHeight {
    CGFloat height = self.contentView.frame.size.height;
    return height;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.contentView.bounds.size;
}

- (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect {
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - CGRectGetMinX(innerRect));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - CGRectGetMaxX(innerRect));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - CGRectGetMinY(innerRect));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - CGRectGetMaxY(innerRect));
    
    if(nudgeLeft != 0) {
        nudgeLeft -= _margins.x;
    }
    if(nudgeRight != 0) {
        nudgeRight += _margins.x;
    }
    if(nudgeTop != 0) {
        nudgeTop += _margins.y;
    }
    if(nudgeBottom != 0) {
        nudgeBottom -= _margins.y;
    }
    
    return CGSizeMake(nudgeLeft ? : nudgeRight, nudgeTop ? : nudgeBottom);
}

- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentCalloutFromRect:rect inLayer:view.layer ofView:view constrainedToLayer:constrainedView.layer permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentCalloutFromRect:rect inLayer:layer ofView:nil constrainedToLayer:constrainedLayer permittedArrowDirections:arrowDirections animated:animated];
}

// this private method handles both CALayer and UIView parents depending on what's passed.
- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer ofView:(UIView *)view constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    // Sanity check: dismiss this callout immediately if it's displayed somewhere
    if (self.layer.superlayer) {
        [self dismissCalloutAnimated:NO];
    }

    // figure out the constrained view's rect in our popup view's coordinate system
    CGRect constrainedRect = [constrainedLayer convertRect:constrainedLayer.bounds toLayer:layer];

    // form our subviews based on our content set so far
    [self rebuildSubviews];

    // size the callout to fit the width constraint as best as possible
    self.$size = _contentView.frame.size;
    
    // how much room do we have in the constraint box, both above and below our target rect?
    CGFloat topSpace = CGRectGetMinY(rect) - CGRectGetMinY(constrainedRect);
    CGFloat bottomSpace = CGRectGetMaxY(constrainedRect) - CGRectGetMaxY(rect);

    // we prefer to point our arrow down.
    SMCalloutArrowDirection bestDirection = SMCalloutArrowDirectionDown;

    // we'll point it up though if that's the only option you gave us.
    if (arrowDirections == SMCalloutArrowDirectionUp) {
        bestDirection = SMCalloutArrowDirectionUp;
    }

    // or, if we don't have enough space on the top and have more space on the bottom, and you
    // gave us a choice, then pointing up is the better option.
    if ((arrowDirections == SMCalloutArrowDirectionAny) && (topSpace < self.calloutHeight) && (bottomSpace > topSpace)) {
        bestDirection = SMCalloutArrowDirectionUp;
    }

    // show the correct anchor based on our decision
    _arrowDirection = bestDirection;

    // we want to point directly at the horizontal center of the given rect. calculate our "anchor point" in terms of our
    // target view's coordinate system. make sure to offset the anchor point as requested if necessary.
    CGFloat anchorX = self.calloutOffset.x + CGRectGetMidX(rect);
    CGFloat anchorY = self.calloutOffset.y + (bestDirection == SMCalloutArrowDirectionDown ? CGRectGetMinY(rect) : CGRectGetMaxY(rect));
    
    // we prefer to sit in the exact center of our constrained view, so we have visually pleasing equal left/right margins.
    CGFloat calloutX = roundf(CGRectGetMidX(constrainedRect) - self.$width / 2);

    // what's the farthest to the left and right that we could point to, given our background image constraints?
    CGFloat minPointX = calloutX + ANCHOR_MARGIN;
    CGFloat maxPointX = calloutX + self.$width - ANCHOR_MARGIN;

    // we may need to scoot over to the left or right to point at the correct spot
    CGFloat adjustX = 0;

    if (anchorX < minPointX) {
        adjustX = anchorX - minPointX;
    }

    if (anchorX > maxPointX) {
        adjustX = anchorX - maxPointX;
    }

    // add the callout to the given layer (or view if possible, to receive touch events)
    if (view) {
        [view addSubview:self];
    }
    else {
        [layer addSublayer:self.layer];
    }
    
    CGPoint calloutOrigin = {
        .x = -self.$width*0.5f + self.calloutOffset.x,
        .y = bestDirection == SMCalloutArrowDirectionDown ? (anchorY - self.calloutHeight) : anchorY
    };

    self.$origin = calloutOrigin;

    // now set the *actual* anchor point for our layer so that our "popup" animation starts from this point.
    CGPoint anchorPoint = [layer convertPoint:CGPointMake(anchorX, anchorY) toLayer:self.layer];
    anchorPoint.x /= self.$width;
    anchorPoint.y /= self.$height;
    self.layer.anchorPoint = anchorPoint;

    // setting the anchor point moves the view a bit, so we need to reset
    self.$origin = calloutOrigin;

    // layout now so we can immediately start animating to the final position if needed
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // if we're outside the bounds of our constraint rect, we'll give our delegate an opportunity to shift us into position.
    // consider both our size and the size of our target rect (which we'll assume to be the size of the content you want to scroll into view.
    CGRect contentRect = CGRectUnion(self.frame, CGRectInset(rect, -10, -10));
    CGSize offset = [self offsetToContainRect:contentRect inRect:constrainedRect];

    NSTimeInterval delay = 0;
    _popupCancelled = NO; // reset this before calling our delegate below

    if ([self.delegate respondsToSelector:@selector(calloutView:delayForRepositionWithSize:)] && !CGSizeEqualToSize(offset, CGSizeZero)) {
        delay = [self.delegate calloutView:self delayForRepositionWithSize:offset];
    }

    // there's a chance that user code in the delegate method may have called -dismissCalloutAnimated to cancel things; if that
    // happened then we need to bail!
    if (_popupCancelled) {
        return;
    }

    // if we need to delay, we don't want to be visible while we're delaying, so hide us in preparation for our popup
    self.hidden = YES;

    // create the appropriate animation, even if we're not animated
    CAAnimation *animation = [self animationWithType:self.presentAnimation presenting:YES];

    // nuke the duration if no animation requested - we'll still need to "run" the animation to get delays and callbacks
    if (!animated) {
        animation.duration = 0.0000001; // can't be zero or the animation won't "run"
    }

    animation.beginTime = CACurrentMediaTime() + delay;
    animation.delegate = self;

    [self.layer addAnimation:animation forKey:@"present"];
}

#pragma mark - animation
- (void)animationDidStart:(CAAnimation *)anim {
    BOOL presenting = [[anim valueForKey:@"presenting"] boolValue];

    if (presenting) {
        // ok, animation is on, let's make ourselves visible!
        self.hidden = NO;
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished {
    BOOL presenting = [[anim valueForKey:@"presenting"] boolValue];

    if (presenting) {
        if ([_delegate respondsToSelector:@selector(calloutViewDidAppear:)]) {
            [_delegate calloutViewDidAppear:self];
        }
    }
    else if (!presenting) {
        [self removeFromParent];
        [self.layer removeAnimationForKey:@"dismiss"];

        if ([_delegate respondsToSelector:@selector(calloutViewDidDisappear:)]) {
            [_delegate calloutViewDidDisappear:self];
        }
    }
}

- (CAAnimation *)animationWithType:(SMCalloutAnimation)type presenting:(BOOL)presenting {
    CAAnimation *animation = nil;

    if (type == SMCalloutAnimationBounce) {
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        bounceAnimation.values = @[@0.05, @1.11245, @0.951807, @1.0];
        bounceAnimation.keyTimes = @[@0, @(4.0/9.0), @(4.0/9.0+5.0/18.0), @1.0];
        bounceAnimation.duration = 1.0/3.0; // the official bounce animation duration adds up to 0.3 seconds; but there is a bit of delay introduced by Apple using a sequence of callback-based CABasicAnimations rather than a single CAKeyframeAnimation. So we bump it up to 0.33333 to make it feel identical on the device
        bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut];

        if (!presenting) {
            bounceAnimation.values = [[bounceAnimation.values reverseObjectEnumerator] allObjects]; // reverse values
        }

        animation = bounceAnimation;
    }
    else if (type == SMCalloutAnimationFade) {
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.duration = 1.0 / 3.0;
        fadeAnimation.fromValue = presenting ? @0.0 : @1.0;
        fadeAnimation.toValue = presenting ? @1.0 : @0.0;        animation = fadeAnimation;
    }
    else if (type == SMCalloutAnimationStretch) {
        CABasicAnimation *stretchAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        stretchAnimation.duration = 0.1;
        stretchAnimation.fromValue = presenting ? @0.0 : @1.0;
        stretchAnimation.toValue = presenting ? @1.0 : @0.0;
        animation = stretchAnimation;
    }

    // CAAnimation is KVC compliant, so we can store whether we're presenting for lookup in our delegate methods
    [animation setValue:@ (presenting) forKey:@"presenting"];

    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    return animation;
}

#pragma mark - callout dismissal
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // we want to match the system callout view, which doesn't "capture" touches outside the accessory areas. This way you can click on other pins and things *behind* a translucent callout.
    return [self.contentView pointInside:[self.contentView convertPoint:point fromView:self] withEvent:nil];
}

- (void)dismissCalloutAnimated:(BOOL)animated {
    [self.layer removeAnimationForKey:@"present"];
    
    _popupCancelled = YES;
    
    if (animated) {
        CAAnimation *animation = [self animationWithType:self.dismissAnimation presenting:NO];
        animation.delegate = self;
        [self.layer addAnimation:animation forKey:@"dismiss"];
    }
    else {
        [self removeFromParent];
    }
}

- (void)removeFromParent {
    if (self.superview) {
        [self removeFromSuperview];
    }
    else {
        // removing a layer from a superlayer causes an implicit fade-out animation that we wish to disable.
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self.layer removeFromSuperlayer];
        [CATransaction commit];
    }
}

@end
