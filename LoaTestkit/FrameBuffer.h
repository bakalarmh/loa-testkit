//
//  FrameBuffer.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrameBuffer : NSObject

@property (strong, nonatomic) NSNumber* frameWidth;
@property (strong, nonatomic) NSNumber* frameHeight;
@property (strong, nonatomic) NSNumber* numFrames;

- (id)initWithWidth:(NSInteger)frameWidth Height:(NSInteger)frameHeight Frames:(NSInteger)frames;
- (void)writeFrame:(CVBufferRef)imageBuffer atIndex:(NSNumber*)index;
- (UIImage*)getUIImageFromIndex:(NSInteger)index;
- (NSArray*)getUIImageArray;
- (cv::Mat)getFrameAtIndex:(NSInteger)index;

@end
