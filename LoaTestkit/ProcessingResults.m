//
//  ProcessingResults.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessingResults.h"

@implementation ProcessingResults

@synthesize frameBuffer;
@synthesize points;
@synthesize startFrames;
@synthesize endFrames;

- (void)initWithFrameBuffer:(FrameBuffer*)buffer
{
    self.frameBuffer = buffer;
    self.points = [[NSMutableArray alloc] init];
    self.startFrames = [[NSMutableArray alloc] init];
    self.endFrames = [[NSMutableArray alloc] init];
}

- (void)addPoint:(CGPoint)point from:(NSInteger)startFrame to:(NSInteger)endFrame
{
    [points addObject:[NSValue valueWithCGPoint:point]];
    [startFrames addObject:[NSNumber numberWithInteger:startFrame]];
    [endFrames addObject:[NSNumber numberWithInteger:endFrame]];
}

@end
