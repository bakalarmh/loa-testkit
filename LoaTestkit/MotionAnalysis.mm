//
//  MotionAnalysis.m
//  CellScopeLoa

#import "MotionAnalysis.h"
#import "UIImage+OpenCV.h"
#import "ProcessFramesViewController.h"


@implementation MotionAnalysis {
    NSMutableArray* movieLengths;
    NSInteger movieIdx;
    NSInteger frameIdx;
    NSInteger numFramesMax;
    NSInteger numMovies;
    float sensitivity;
    double progress;
}
int numWorms=0;
@synthesize coordsArray;

-(id)initWithWidth:(NSInteger)width Height:(NSInteger)height
            Frames:(NSInteger)frames
            Movies:(NSInteger)movies
       Sensitivity: (float) sense {

    self = [super init];
    
    progress = 0.0;
    
    movieIdx = 0;
    frameIdx = 0;
    numFramesMax = frames;
    numMovies = movies;
    sensitivity = sense;
    coordsArray = [[NSMutableArray alloc] init];
    movieLengths = [[NSMutableArray alloc] init];
    return self;
}

- (NSMutableArray *)processFramesForMovie:(FrameBuffer*) frameBuffers {
    // Start at the first frame
    frameIdx = 0;
    coordsArray = [[NSMutableArray alloc] init];
    
    movieIdx = 0;
    //NSNumber *movielength = [movieLengths objectAtIndex:0];
    NSInteger numFrames = 150;
    
    // Movie dimensions
    int rows = 360;
    int cols = 480;
    //int sz[3] = {rows,cols,3};
    
    
    // Algorithm parameters
    int framesToAvg = 7;
    int framesToSkip = 1;
    // Matrix for storing normalized frames
    cv::Mat movieFrameMatNorm=cv::Mat::zeros(rows, cols, CV_16UC1);

    // Temporary matrices for image processing
    cv::Mat movieFrameMatOld;
    cv::Mat movieFrameMatCum(rows,cols, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatFirst;
    cv::Mat movieFrameMatDiff= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat;
    cv::Mat movieFrameMatBW;
    cv::Mat movieFrameMatBWInv;
    cv::Mat movieFrameMatBWCopy;
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNormOld;
    cv::Mat movieFrameMatDiff1= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiff2= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiff3= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiff4= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiff5= cv::Mat::zeros(rows, cols, CV_16UC1);

    
    int i = 0;
    int avgFrames = framesToAvg/framesToSkip;
    frameIdx = 0;
    
    // Compute difference image from current movie
    while(frameIdx < numFrames) {
        //[self setProgressWithMovie:movidx Frame:frameIdx];
        while(i < avgFrames) {
            // Update the progress bar
            //[self setProgressWithMovie:movidx Frame:frameIdx];
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx);
            //NSLog(@"bufferidxinit: %i", bufferIdx);
            movieFrameMat = [frameBuffers getFrameAtIndex:bufferIdx];
            

            if (i==0){
                threshold(movieFrameMat, movieFrameMatBW, 50, 255, CV_THRESH_BINARY_INV);
                cv::Mat element = getStructuringElement(CV_SHAPE_ELLIPSE, cv::Size( 10,10 ), cv::Point( 2, 2 ));
                cv::morphologyEx(movieFrameMatBW,movieFrameMatBW, CV_MOP_DILATE, element );
                //cv::Mat movieFrameMatBWInv;
                //cv::subtract(cv::Scalar::all(255),movieFrameMatBW, movieFrameMatBW);
                movieFrameMatBW.convertTo(movieFrameMatBW, CV_16UC1);
                movieFrameMatBW=movieFrameMatBW*255;

            }
            //cv::multiply(movieFrameMat, movieFrameMatBW, movieFrameMat);

            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            
            if (i == 0){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                
                UIImage * diff3;
                cv::Mat movieFrameMatDiff38=movieFrameMatCum.clone()/i;
                movieFrameMatDiff38.convertTo(movieFrameMatDiff38, CV_8UC1);
                diff3 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff38];
                
                /*UIImageWriteToSavedPhotosAlbum(diff3,
                                               self, // send the message to 'self' when calling the callback
                                               @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                               NULL); // you generally won't need a contextInfo here*/

                movieFrameMatCum = movieFrameMatCum + movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=cv::Mat();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            i=i+1;
            //NSLog(@"%i", i);
            frameIdx = frameIdx + framesToSkip;
        }
        
        if (i == avgFrames){
            movieFrameMatNorm=movieFrameMatCum.clone()/i;
            /*UIImage * diff3;
            cv::Mat movieFrameMatDiff38;
            movieFrameMatNorm.convertTo(movieFrameMatDiff38, CV_8UC1);
            diff3 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff38];
            
            UIImageWriteToSavedPhotosAlbum(diff3,
                                           self, // send the message to 'self' when calling the callback
                                           @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                           NULL); // you generally won't need a contextInfo here */
        }
        if (i > avgFrames) {
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx);
            movieFrameMat = [frameBuffers getFrameAtIndex:bufferIdx];
            //cv::multiply(movieFrameMat, movieFrameMatBW, movieFrameMat);

            // Convert the frame into 16 bit grayscale. Space for optimization
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            // 3x3 spatial filter to reduce noise and downsample
            //cv::filter2D(movieFrameMat, movieFrameMat, -1, blockAvg3x3, cv::Point(-1,-1));
            
            // Grab the first frame from the current ave from the frame buffer list
            int firstBufferIdx = movieIdx*numFramesMax + (frameIdx-avgFrames+1);
            //NSLog(@"bufferidxfirst: %i", bufferIdx);
            
            movieFrameMatFirst = [frameBuffers getFrameAtIndex:firstBufferIdx];
            movieFrameMatFirst.convertTo(movieFrameMatFirst, CV_16UC1);
            
            // 3x3 spatial filter to reduce noise and downsample
            //cv::filter2D(movieFrameMatFirst, movieFrameMatFirst, -1, blockAvg3x3, cv::Point(-1,-1));
            
            movieFrameMatCum = movieFrameMatCum - movieFrameMatFirst + movieFrameMat;
            movieFrameMat.release();
            movieFrameMat=cv::Mat();
            movieFrameMatFirst.release();
            movieFrameMatFirst=cv::Mat();
            cv::divide(movieFrameMatCum, avgFrames, movieFrameMatNorm);
            
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            
            movieFrameMatNormOld.release();
            movieFrameMatNormOld=cv::Mat();
            movieFrameMatDiff=movieFrameMatDiff + movieFrameMatDiffTmp;

            if (i<=36) {
                movieFrameMatDiff1 = movieFrameMatDiff1 + movieFrameMatDiffTmp;
                
            }
            else if  (i<=65) {
                movieFrameMatDiff2 = movieFrameMatDiff2 + movieFrameMatDiffTmp;

            }
            else if (i<=94) {
                movieFrameMatDiff3 = movieFrameMatDiff3 + movieFrameMatDiffTmp;

            }
            else if (i<=123) {
                movieFrameMatDiff4 = movieFrameMatDiff4 + movieFrameMatDiffTmp;

            }
            else {
                movieFrameMatDiff5 = movieFrameMatDiff5 + movieFrameMatDiffTmp;

            }
            movieFrameMatDiffTmp.release();
            movieFrameMatDiffTmp=cv::Mat();
        }
        movieFrameMatNormOld=movieFrameMatNorm.clone();
        movieFrameMatNorm.release();
        movieFrameMatNorm=cv::Mat();
        frameIdx = frameIdx + framesToSkip;
        //NSLog(@"%i", i);
        i = i+1;
    }

    cv::Mat backConvMat= cv::Mat::ones(20, 20, CV_32FC1);
    backConvMat=backConvMat*.005;

    movieFrameMatDiff=movieFrameMatDiff+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff,movieFrameMatDiff,-1,backConvMat, cv::Point(-1,-1));
    double backVal;
    double maxValTrash;
    cv::minMaxLoc(movieFrameMatDiff, &backVal, &maxValTrash);
    //backVal=backVal;
    //spatially filter and subtract background
    cv::filter2D(movieFrameMatDiff1,movieFrameMatDiff1,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff1=movieFrameMatDiff1-backVal;

    cv::filter2D(movieFrameMatDiff2,movieFrameMatDiff2,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff2=movieFrameMatDiff2-backVal;

    cv::filter2D(movieFrameMatDiff3,movieFrameMatDiff3,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff3=movieFrameMatDiff3-backVal;

    cv::filter2D(movieFrameMatDiff4,movieFrameMatDiff4,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff4=movieFrameMatDiff4-backVal;

    cv::filter2D(movieFrameMatDiff5,movieFrameMatDiff5,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff5=movieFrameMatDiff5-backVal;
    
    movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_8UC1);
    threshold(movieFrameMatDiff1, movieFrameMatDiff1, 1, 255, CV_THRESH_BINARY);
    
    movieFrameMatDiff2.convertTo(movieFrameMatDiff2, CV_8UC1);
    threshold(movieFrameMatDiff2, movieFrameMatDiff2, 1, 255, CV_THRESH_BINARY);
    
    movieFrameMatDiff3.convertTo(movieFrameMatDiff3, CV_8UC1);
    threshold(movieFrameMatDiff3, movieFrameMatDiff3, 1, 255, CV_THRESH_BINARY);
    
    movieFrameMatDiff4.convertTo(movieFrameMatDiff4, CV_8UC1);
    threshold(movieFrameMatDiff4, movieFrameMatDiff4, 1, 255, CV_THRESH_BINARY);
    
    movieFrameMatDiff5.convertTo(movieFrameMatDiff5, CV_8UC1);
    threshold(movieFrameMatDiff5, movieFrameMatDiff5, 1, 255, CV_THRESH_BINARY);

    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    findContours( movieFrameMatDiff1, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:hierarchy:1:32];

    findContours( movieFrameMatDiff2, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0,0) );

    [self countContours:contours:hierarchy:33:60];

    
    findContours( movieFrameMatDiff3, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:hierarchy:61:90];

    
    findContours( movieFrameMatDiff4, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:hierarchy:91:120];

    
    findContours( movieFrameMatDiff5, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:hierarchy:121:150];
    
    numWorms=numWorms/5;
    NSLog(@"numWorms %i", numWorms);
    movieFrameMatDiff.release();
    movieFrameMatDiff1.release();
    movieFrameMatDiff2.release();
    movieFrameMatDiff3.release();
    movieFrameMatDiff4.release();
    movieFrameMatDiff5.release();
    movieFrameMatBW.release();

    return coordsArray;

}

- (void) countContours:(cv::vector<cv::vector<cv::Point> >) contours :(cv::vector<cv::Vec4i>) hierarchy:(int) start :(int) end {
    cv::RNG rng(12345);

    cv::Mat drawing = cv::Mat::zeros(360,480, CV_8UC3 );
    
    for(int idx = 0;idx<contours.size(); idx++)
        
    {
        cv::Scalar color = cv::Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours( drawing, contours, idx, color, 2, 8, hierarchy, 0, cv::Point() );

        
        double len=contourArea(contours[idx]);
        NSLog(@"found contour %f", len);
        
        if (len>10100) {
            numWorms=numWorms+6;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
        }
        else if (len>8100) {
            numWorms=numWorms+5;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];

        }

        else if (len>6100) {
            numWorms=numWorms+4;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];

        }

        else if (len>4100) {
            numWorms=numWorms+3;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            
        }
        
        else if (len>2100) {
            numWorms=numWorms+2;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            
            //just write again since we don't have real positions
            [coordsArray addObject:x];
            [coordsArray addObject:y];
            [coordsArray addObject:start];
            [coordsArray addObject:end];
            
        }

        if (len>100) {
            numWorms=numWorms+1;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
            
        }
        else {
            //NSLog(@"found small contour %f", len);
        }
    }
    UIImage * diff2;
    cv::Mat movieFrameMatDiff28;
    drawing.convertTo(movieFrameMatDiff28, CV_8UC1);
    diff2 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff28];
    
    UIImageWriteToSavedPhotosAlbum(diff2,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here*/

}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"error saving image");
        
    } else {
        NSLog(@"image saved in photo album");
    }
}


@end
