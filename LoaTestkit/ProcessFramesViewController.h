//
//  ProcessFramesViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "FrameBuffer.h"
#include "ProcessingResults.h"
#include <AVFoundation/AVFoundation.h>

@protocol ProcessFramesDelegate <NSObject>

@optional

- (void)finishedProcessingWithResults:(ProcessingResults *)results;

@end

@interface ProcessFramesViewController : UIViewController

@property (weak, nonatomic) id<ProcessFramesDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIImageView *frameView;

@property (strong, nonatomic) NSURL* assetURL;
@property (strong, nonatomic) AVAssetReader* reader;
@property (strong, nonatomic) FrameBuffer* frameBuffer;
@property (strong, nonatomic) ProcessingResults* processingResults;
@property (strong, nonatomic) NSMutableArray* coordsArray;


- (NSNumber*)countAssetFrames;

@end
