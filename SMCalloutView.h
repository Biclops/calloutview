#import <UIKit/UIKit.h>

// =============================================================================
// Types
// =============================================================================

// options for which directions the callout is allowed to "point" in.
enum {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};
typedef NSUInteger SMCalloutArrowDirection;

// options for the callout present/dismiss animation
enum {
    SMCalloutAnimationBounce,   // the "bounce" animation we all know and love from UIAlertView
    SMCalloutAnimationFade,     // a simple fade in or out
    SMCalloutAnimationStretch   // grow or shrink linearly, like in the iPad Calendar app
};
typedef NSInteger SMCalloutAnimation;

// =============================================================================
// Constants
// =============================================================================

// when delaying our popup in order to scroll content into view, you can use this amount to match the
// animation duration of UIScrollView when using -setContentOffset:animated.
extern NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView;

// =============================================================================
// Delegate
// =============================================================================

@class SMCalloutView;
@protocol SMCalloutViewDelegate <NSObject>
@optional
// Called when the callout view detects that it will be outside the constrained view when it appears,
// or if the target rect was already outside the constrained view. You can implement this selector to
// respond to this situation by repositioning your content first in order to make everything visible. The
// CGSize passed is the calculated offset necessary to make everything visible (plus a nice margin).
// It expects you to return the amount of time you need to reposition things so the popup can be delayed.
// Typically you would return kSMCalloutViewRepositionDelayForUIScrollView if you're repositioning by
// calling [UIScrollView setContentOffset:animated:].
- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset;

// Called after the callout view appears on screen, or after the appearance animation is complete.
- (void)calloutViewDidAppear:(SMCalloutView *)calloutView;

// Called after the callout view is removed from the screen, or after the disappearance animation is complete.
- (void)calloutViewDidDisappear:(SMCalloutView *)calloutView;

@end

// =============================================================================
// SMCalloutView
// =============================================================================

@interface SMCalloutView : UIView

@property (nonatomic, unsafe_unretained) id<SMCalloutViewDelegate> delegate;

// must have contentView for work
@property (nonatomic, retain) UIView *contentView;

// calloutOffset is the offset in screen points from the top-middle of the annotation view, where the anchor of the callout should be shown.
@property (nonatomic, assign) CGPoint calloutOffset;

// space between the edge of the content view and the edge of the mapView. Default is {10.0f, 10.0f}
@property (nonatomic, assign) CGPoint margins;

// default SMCalloutAnimationBounce, SMCalloutAnimationFade respectively
@property (nonatomic, assign) SMCalloutAnimation presentAnimation, dismissAnimation;

// Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
// Constrains the callout to the bounds of the given view. Optionally scrolls the given rect into view (plus margins)
// if -delegate is set and responds to -delayForRepositionWithSize.
- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

// Same as the view-based presentation, but inserts the callout into a CALayer hierarchy instead. Be aware that you'll have to direct
// your own touches to any accessory views, since CALayer doesn't relay touch events.
- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissCalloutAnimated:(BOOL)animated;

@end
