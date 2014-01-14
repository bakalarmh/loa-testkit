//
//  ProcessFramesViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessFramesViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MotionAnalysis.h"

@interface ProcessFramesViewController ()

@end

@implementation ProcessFramesViewController

@synthesize messageLabel;
@synthesize activityView;
@synthesize frameView;

@synthesize assetURL;
@synthesize reader;
@synthesize frameBuffer;
@synthesize processingResults;
@synthesize coordsArray;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    coordsArray = [[NSMutableArray alloc] init];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    messageLabel.text = @"Counting frames";
    activityView.hidden = FALSE;
    [activityView startAnimating];
}

- (void)viewDidAppear:(BOOL)animated
{
    // #TODO MHB - hard coded width and height for the video frames
    NSInteger width = (NSInteger) 480;
    NSInteger height = (NSInteger) 360;
    
    NSNumber* frames = [self countAssetFrames];
    messageLabel.text = @"Reading frames";
    
    // Read in one less frame than the number returned by countframes
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        frameBuffer = [[FrameBuffer alloc] initWithWidth:width Height:height Frames:frames.integerValue];
        [self fillFrameBuffer];
        
        // Initialize the processing results structure
        processingResults = [[ProcessingResults alloc] initWithFrameBuffer:frameBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            messageLabel.text = @"Processing frames";
            // #TODO - MHB terminate processing code early for testing
            [self.delegate finishedProcessingWithResults:processingResults];
            [self.navigationController popViewControllerAnimated:YES];
        });
        
        // Launch processing code on frame structure
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self beginProcessing];
        });
        
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSNumber*)countAssetFrames
{
    AVAsset* asset = [AVAsset assetWithURL:assetURL];
    reader = [[AVAssetReader alloc] initWithAsset:asset error:Nil];
    
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack* track = [tracks objectAtIndex:0];
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSNumber* format = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    [dictionary setObject:format forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput* readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:dictionary];
    [reader addOutput:readerOutput];
    [reader startReading];
    
    CMSampleBufferRef buffer;
    
    int i = 0;
    while ([reader status] == AVAssetReaderStatusReading )
    {
        buffer = [readerOutput copyNextSampleBuffer];
        if([reader status] == AVAssetReaderStatusReading) {
            i++;
        }
    }
    
    return [[NSNumber alloc] initWithInt:i];
}

- (void)fillFrameBuffer
{
    AVAsset* asset = [AVAsset assetWithURL:assetURL];
    reader = [[AVAssetReader alloc] initWithAsset:asset error:Nil];
    
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack* track = [tracks objectAtIndex:0];
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSNumber* format = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    [dictionary setObject:format forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput* readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:dictionary];
    [reader addOutput:readerOutput];
    [reader startReading];
    
    CMSampleBufferRef buffer;
    
    int i = 0;
    while ([reader status] == AVAssetReaderStatusReading )
    {
        buffer = [readerOutput copyNextSampleBuffer];
        if([reader status] == AVAssetReaderStatusReading) {
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
            [frameBuffer writeFrame:imageBuffer atIndex:[NSNumber numberWithInt:i]];
            i++;
        }
    }
}

- (void)beginProcessing
{
    NSLog(@"Begin processing algorithm");
    MotionAnalysis* analysis = [[MotionAnalysis alloc] initWithWidth: 360
                                                              Height: 480
                                                              Frames: 150
                                                              Movies: 0
                                                         Sensitivity: 1];
    coordsArray=[analysis processFramesForMovie:(FrameBuffer *)frameBuffer];
    for (int idx=0; idx+3<[coordsArray count]; idx=idx+4){
        NSNumber* pointx= [coordsArray objectAtIndex:(NSInteger)idx];
        NSNumber* pointy= [coordsArray objectAtIndex:(NSInteger)idx+1];

        CGPoint point=CGPointMake([pointx floatValue], [pointy floatValue]);
        NSNumber* start= [coordsArray objectAtIndex:(NSInteger)idx+2];
        NSNumber* end= [coordsArray objectAtIndex:(NSInteger)idx+3];
        
        [processingResults addPoint:point from:[start integerValue] to:[end integerValue]];

    }

    // frameBuffer
    // processingResults
    // processingResults addPoint:(CGPoint)point from:(NSInteger)startFrame to:(NSInteger)endFrame
}

@end
