#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomPinAnnotationView.h"
#import "UIViewExtensions.h"

@interface MKMapView(CalloutHitDetection)

@end

@implementation MKMapView(CalloutHitDetection)

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];

    // blocks propogation of touches if it hits the content view or any of it's descendents
    if([view isKindOfClass:[MKAnnotationView class]] == NO &&
       [view isKindOfClass:[UIControl class]] == NO) {
        UIView *iter = view;
        while (iter.superview) {
            if([iter.superview isKindOfClass:[SMCalloutView class]]) {
                if([iter isKindOfClass:[UIButton class]] == NO) {
                    view = nil;
                    break;
                }
            }
            else {
                iter = iter.superview;
            }
        }
    }
    
    return view;
}

@end

@implementation AppDelegate {
    SMCalloutView *calloutView;
    MKMapView *bottomMapView;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.window.backgroundColor = [UIColor whiteColor];
    CGRect half = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height/2);
    
    //
    // Fill top half with a custom view (image) inside a scroll view along with a custom pin view that triggers our custom MTCalloutView.
    //
    
    MKPinAnnotationView *topPin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
    topPin.center = CGPointMake(half.size.width/2 + 230, half.size.height/2 + 100);
    topPin.animatesDrop = YES;
    
    calloutView = [SMCalloutView new];
    calloutView.delegate = self;
    calloutView.calloutOffset = topPin.calloutOffset;
    
    // custom view to be used in our callout
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 50)];
    customView.tag = 666;
    customView.backgroundColor = [UIColor whiteColor];
    customView.layer.borderColor = [UIColor blackColor].CGColor;
    customView.layer.borderWidth = 1;
    customView.layer.cornerRadius = 4;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(handleButton:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(10, 10, 30, 30);
    [customView addSubview:button];
    
    UIView *customView2 = [[UIView alloc] initWithFrame:CGRectMake(110, 10, 30, 30)];
    customView2.tag = 777;
    customView2.backgroundColor = [UIColor orangeColor];
    customView2.layer.borderColor = [UIColor blackColor].CGColor;
    customView2.layer.borderWidth = 1;
    customView2.layer.cornerRadius = 4;
    [customView addSubview:customView2];
    
    calloutView.contentView = customView;
    
    //
    // Fill the bottom half of our window with a standard MKMapView with pin+callout for comparison
    //
    
    MapAnnotation *capeCanaveral = [MapAnnotation new];
    capeCanaveral.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    capeCanaveral.title = @"Cape Canaveral";
    
    bottomMapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height)];
    bottomMapView.delegate = self;
    [bottomMapView addAnnotation:capeCanaveral];
    [bottomMapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];
    
    //
    // Put it all on the screen.
    //
    
    [self.window addSubview:bottomMapView];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
	if([gestureRecognizer isMemberOfClass:[UILongPressGestureRecognizer class]] && (gestureRecognizer.state == UIGestureRecognizerStateEnded)) {
		[bottomMapView removeGestureRecognizer:gestureRecognizer]; //avoid multiple pins to appear when holding on the screen
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:bottomMapView];
    CLLocationCoordinate2D touchMapCoordinate = [bottomMapView convertPoint:touchPoint toCoordinateFromView:bottomMapView];
	
    MapAnnotation *annotation = [MapAnnotation new];
    annotation.coordinate = touchMapCoordinate;
    annotation.title = [NSString stringWithFormat:@"Dropped Pin"];
    [bottomMapView addAnnotation:annotation];
    
    [bottomMapView selectAnnotation:annotation animated:YES];
}

#pragma mark - MKMapView

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    MKAnnotationView *annotationView = nil;
    if([annotation isKindOfClass:[MapAnnotation class]]) {
        MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
        if(pinAnnotationView == nil) {
            pinAnnotationView = [[CustomPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
        }
        
        pinAnnotationView.animatesDrop = YES;
        annotationView = pinAnnotationView;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    // dismiss out callout if it's already shown but on a different parent view
    if (calloutView.window) {
        [calloutView dismissCalloutAnimated:NO];
    }
    
    if([view isKindOfClass:[CustomPinAnnotationView class]]) {
        // now in this example we're going to introduce an artificial delay in order to make our popup feel identical to MKMapView.
        // MKMapView has a delay after tapping so that it can intercept a double-tap for zooming. We don't need that delay but we'll
        // add it just so things feel the same.
        [self performSelector:@selector(popupMapCalloutView:) withObject:view afterDelay:1.0/3.0];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if([view isKindOfClass:[CustomPinAnnotationView class]]) {
        // again, we'll introduce an artifical delay to feel more like MKMapView for this demonstration.
        [calloutView performSelector:@selector(dismissCalloutAnimated:) withObject:nil afterDelay:1.0/3.0];
    }
}

#pragma mark - SMCalloutView
- (void)popupMapCalloutView:(CustomPinAnnotationView *)annotationView {
    calloutView.calloutOffset = CGPointMake(-annotationView.calloutOffset.x, -7.0f);
    
    annotationView.calloutView = calloutView;
    [calloutView presentCalloutFromRect:annotationView.bounds
                                 inView:annotationView
                      constrainedToView:bottomMapView
               permittedArrowDirections:SMCalloutArrowDirectionDown
                               animated:YES];
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset {
    
    // if annotation view is coming from MKMapView, it's contained within a MKAnnotationContainerView instance
    // so we need to adjust the map position so that the callout will be completely visible when displayed
    if ([NSStringFromClass([calloutView.superview.superview class]) isEqualToString:@"MKAnnotationContainerView"]) {
        CGFloat pixelsPerDegreeLat = bottomMapView.frame.size.height / bottomMapView.region.span.latitudeDelta;
        CGFloat pixelsPerDegreeLon = bottomMapView.frame.size.width / bottomMapView.region.span.longitudeDelta;

        CLLocationDegrees latitudinalShift = offset.height / pixelsPerDegreeLat;
        CLLocationDegrees longitudinalShift = -(offset.width / pixelsPerDegreeLon);

        CGFloat lat = bottomMapView.region.center.latitude + latitudinalShift;
        CGFloat lon = bottomMapView.region.center.longitude + longitudinalShift;
        CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D){lat, lon};
        if (fabsf(newCenterCoordinate.latitude) <= 90 && fabsf(newCenterCoordinate.longitude) <= 180) {
            [bottomMapView setCenterCoordinate:newCenterCoordinate animated:YES];
        }
    }
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)dismissCallout {
    [calloutView dismissCalloutAnimated:NO];
}

- (void)handleButton:(UIButton *)button {
    NSLog(@"handleButton");
}

@end

@implementation MapAnnotation
@end