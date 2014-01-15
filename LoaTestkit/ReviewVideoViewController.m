//
//  ReviewVideoViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ReviewVideoViewController.h"

@interface ReviewVideoViewController ()

@end

@implementation ReviewVideoViewController

@synthesize imageView;
@synthesize circleLayers;
@synthesize processingResults;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    circleLayers = [[NSMutableArray alloc] init];
}

// Create a UIBezierPath which is a circle at a certain location of a certain radius.
- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:location
                    radius:radius
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    return path;
}

// Create a CAShapeLayer for our circle on tap on the screen
- (void)drawCirclesAtCoordinates:(NSMutableArray*)locations
{
    CGFloat circradius = 5.0;
    for (NSValue* location in locations) {
        
        CGPoint point = location.CGPointValue;
        UIBezierPath* path = [self makeCircleAtLocation:point radius:circradius];
        
        // Create new CAShapeLayer
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = path.CGPath;
        shapeLayer.strokeColor = [[UIColor redColor] CGColor];
        shapeLayer.fillColor = [[UIColor redColor] CGColor];
        shapeLayer.lineWidth = 3.0;
        
        [imageView.layer addSublayer:shapeLayer];
        // Save the layer in a list of circleLayers for access later
        [circleLayers addObject:shapeLayer];
    }
}

// Clear all circle layers from the view and delete them from the circleLayers array
- (void)clearCircles
{
    for (CAShapeLayer* layer in circleLayers) {
        [layer removeFromSuperlayer];
    }
    [circleLayers removeAllObjects];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
