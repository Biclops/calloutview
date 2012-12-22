//
//  CustomAnnotationView.h
//  CalloutViewSamples
//
//  Created by DTan on 12/21/12.
//
//

#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

// We need a custom MKAnnotationView implementation to override -hitTest:withEvent: so we can intercept touches
// in our annotation's callout view.
@interface CustomPinAnnotationView : MKPinAnnotationView
@property (strong, nonatomic) SMCalloutView *calloutView;
@end
