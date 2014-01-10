//
//  ProcessFramesViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessFramesViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ProcessFramesViewController ()

@end

@implementation ProcessFramesViewController

@synthesize messageLabel;
@synthesize activityView;
@synthesize frameView;

@synthesize assetURL;
@synthesize reader;
@synthesize frameBuffer;

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
        dispatch_async(dispatch_get_main_queue(), ^{
            messageLabel.hidden = YES;
            activityView.hidden = YES;
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

// Create a UIImage from sample buffer data
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
