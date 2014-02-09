//
//  ReviewVideoViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ReviewVideoViewController.h"

@interface ReviewVideoViewController () {
    NSInteger frameNumber;
}

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
    NSLog(@"Count: %f", (double)processingResults.points.count / 5.0);
}

- (void)animateVideo:(NSTimer *)timer
{
    UIImage* image = [processingResults.frameBuffer getUIImageFromIndex:frameNumber];
    self.imageView.image = [self rotateImage:image];
    
    [self clearCircles];
    NSMutableArray* points = processingResults.points;
    NSMutableArray* startFrames = processingResults.startFrames;
    NSMutableArray* endFrames = processingResults.endFrames;
    [self drawCirclesAtCoordinates:points withStartFrames:startFrames endFrames:endFrames forFrameNumber:frameNumber];
    
    frameNumber += 1;
    if (frameNumber == processingResults.frameBuffer.numFrames.integerValue) {
        [timer invalidate];
    }
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
- (void)drawCirclesAtCoordinates:(NSMutableArray*)locations withStartFrames:(NSMutableArray*)startFrames endFrames:(NSMutableArray*)endFrames forFrameNumber:(NSInteger)frame
{
    // Expand position of points to fit the image view
    CGSize imageSize = imageView.frame.size;
    float multiplier = imageSize.width/360.0;
    
    CGFloat circradius = 5.0;
    int i = 0;
    for (NSValue* location in locations) {
        NSNumber* startFrame = (NSNumber*)[startFrames objectAtIndex:i];
        NSNumber* endFrame = (NSNumber*)[endFrames objectAtIndex:i];
        if ((frame > startFrame.integerValue) && (frame <= endFrame.integerValue)) {
            CGPoint point = location.CGPointValue;
            CGPoint rotatedPoint = CGPointMake((360.0-point.y)*multiplier, point.x*multiplier);
            UIBezierPath* path = [self makeCircleAtLocation:rotatedPoint radius:circradius];
            
            // Create new CAShapeLayer
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = path.CGPath;
            shapeLayer.strokeColor = [[UIColor redColor] CGColor];
            shapeLayer.fillColor = nil;
            shapeLayer.lineWidth = 3.0;
            
            [imageView.layer addSublayer:shapeLayer];
            // Save the layer in a list of circleLayers for access later
            [circleLayers addObject:shapeLayer];
        }
        i += 1;
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

- (IBAction)onPlayButtonPressed:(id)sender
{
    frameNumber = 0;
    float interval = 1.0/30.0;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(animateVideo:) userInfo:nil repeats:YES];
}

- (UIImage *)rotateImage:(UIImage*)image
{
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(M_PI/2);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(bitmap, rotatedSize.width, rotatedSize.height);
    CGContextRotateCTM(bitmap, M_PI/2);
    
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width, -image.size.height, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
