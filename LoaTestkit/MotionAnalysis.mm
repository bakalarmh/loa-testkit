//
//  MotionAnalysis.m
//  CellScopeLoa

#import "MotionAnalysis.h"
#import "UIImage+OpenCV.h"
#import "ProcessFramesViewController.h"


@implementation MotionAnalysis {
    NSMutableArray* movieLengths;
    //FrameBuffer *frameBuffers;
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
    //NSLog(@"Using sensitivity: %f", sensitivity);
    
    coordsArray = [[NSMutableArray alloc] init];

    movieLengths = [[NSMutableArray alloc] init];


    
    /*frameBuffers = new std::vector<cv::Mat>(frames*movies);
    
    for(int i=0; i<frames*movies; i++) {
        cv::Mat buffer(height,width,CV_8UC1);
        frameBuffers->at(i) = buffer;
    }
    */
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
    int sz[3] = {rows,cols,3};
    
    
    // Algorithm parameters
    int framesToAvg = 7;
    int framesToSkip = 1; //WARNING- verify bufferIdx after changing, might not scale right
    
    // Image for storing the output...
    cv::Mat outImage(3, sz, CV_16UC(1), cv::Scalar::all(0));
    
    // Kernels for block averages
    cv::Mat blockAvg3x3 = cv::Mat::ones(5, 5, CV_32F);
    cv::divide( blockAvg3x3, 25,  blockAvg3x3);

    cv::Mat blockAve7x7(7, 7, CV_32F, cv::Scalar::all(.02));
    
    cv::Mat blockAvg12x12 = cv::Mat::ones(15, 15, CV_32F);
    cv::Mat blockAvg50x50 = cv::Mat::ones(67,67,CV_32F);
    
    // Matrix for storing normalized frames
    cv::Mat movieFrameMatNorm(rows, cols, CV_16UC1);
    // Matrix for storing found blockxs of motion
    cv::Mat foundWorms(rows, cols, CV_8UC1, cv::Scalar::all(0));
    // Temporary matrices for image processing
    cv::Mat movieFrameMatOld;
    //cv::Mat movieFrameMatCum;
    cv::Mat movieFrameMatCum(rows,cols, CV_16UC1, cv::Scalar::all(0));
    
    cv::Mat movieFrameMatFirst;
    cv::Mat movieFrameMatDiff;
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat;
    cv::Mat movieFrameMatBW;
    cv::Mat movieFrameMatBWInv;
    cv::Mat movieFrameMatBWCopy;
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNormOld;
    cv::Mat movieFrameMatDiff1= cv::Mat::zeros(rows, cols, CV_16UC1);
    cv::Mat movieFrameMatDiff2= cv::Mat::zeros(rows, cols, CV_16UC1);;
    cv::Mat movieFrameMatDiff3= cv::Mat::zeros(rows, cols, CV_16UC1);;
    cv::Mat movieFrameMatDiff4= cv::Mat::zeros(rows, cols, CV_16UC1);;
    cv::Mat movieFrameMatDiff5= cv::Mat::zeros(rows, cols, CV_16UC1);;

    
    int i = 0;
    int avgFrames = framesToAvg/framesToSkip;
    frameIdx = 0;
    
    // Compute difference image from current movie
    while(frameIdx+avgFrames <= (numFrames-framesToAvg)) {
        //[self setProgressWithMovie:movidx Frame:frameIdx];
        while(i <= avgFrames) {
            // Update the progress bar
            //[self setProgressWithMovie:movidx Frame:frameIdx];
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx);
            //NSLog(@"bufferidxinit: %i", bufferIdx);
            movieFrameMat = [frameBuffers getFrameAtIndex:bufferIdx];
            //movieFrameMat = frameBuffers->at(bufferIdx);
            //movieFrameMat = [frameBuffers readFrame:bufferIdx];

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
            // 3x3 spatial filter to reduce noise and downsample
            //cv::filter2D(movieFrameMat, movieFrameMat, -1, blockAvg3x3, cv::Point(-1,-1));
            
            if (i == 0){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                movieFrameMatCum = movieFrameMatCum + movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=cv::Mat();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            i=i+1;
            frameIdx = frameIdx + framesToSkip;
        }
        
        if (i == avgFrames+1){
            //NSLog(@"dividing first cum image");
            
            cv::divide(movieFrameMatCum, avgFrames, movieFrameMatNorm);
            //filter2D(movieFrameMatNorm, movieFrameMatNorm, -1 , kernel, cv::Point( -1, -1 ), 0, cv::BORDER_DEFAULT );
        }
        if (i > avgFrames+1) {
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx);
            movieFrameMat = [frameBuffers getFrameAtIndex:bufferIdx];
            //cv::multiply(movieFrameMat, movieFrameMatBW, movieFrameMat);

            // Convert the frame into 16 bit grayscale. Space for optimization
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            // 3x3 spatial filter to reduce noise and downsample
            //cv::filter2D(movieFrameMat, movieFrameMat, -1, blockAvg3x3, cv::Point(-1,-1));
            
            // Grab the first frame from the current ave from the frame buffer list
            int firstBufferIdx = movieIdx*numFramesMax + (frameIdx-avgFrames);
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
            //cv::divide(movieFrameMatCum, avgFrames, movieFrameMatNorm);
            
            //@hack
            movieFrameMatNorm=movieFrameMatCum.clone();
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            
            movieFrameMatNormOld.release();
            movieFrameMatNormOld=cv::Mat();
            //if (i == avgFrames+2) {
            //    movieFrameMatDiff=movieFrameMatDiffTmp;
            //}
            if (i<=32) {
                movieFrameMatDiff1 = movieFrameMatDiff1 + movieFrameMatDiffTmp;
                
            }
            else if  (i<=60) {
                movieFrameMatDiff2 = movieFrameMatDiff2 + movieFrameMatDiffTmp;

            }
            else if (i<=88) {
                movieFrameMatDiff3 = movieFrameMatDiff3 + movieFrameMatDiffTmp;

            }
            else if (i<=126) {
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
        i = i+1;
    }
    
    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_32F);
    movieFrameMatDiff1=movieFrameMatDiff1/((numFrames-avgFrames)/5);
    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_16UC1);
    movieFrameMatDiff2=movieFrameMatDiff2/((numFrames-avgFrames)/5);
    movieFrameMatDiff3=movieFrameMatDiff3/((numFrames-avgFrames)/5);
    movieFrameMatDiff4=movieFrameMatDiff4/((numFrames-avgFrames)/5);
    movieFrameMatDiff5=movieFrameMatDiff5/((numFrames-avgFrames)/5);
   

    cv::Mat backConvMat= cv::Mat::ones(20, 20, CV_32FC1);
    backConvMat=backConvMat*.005;
    cv::Mat movieFrameMattDiffBackTmp=movieFrameMatDiff1+movieFrameMatBW;
    
    
    
    UIImage * diff1;
    cv::Mat movieFrameMatDiff18;
    movieFrameMattDiffBackTmp.convertTo(movieFrameMatDiff18, CV_8UC1);
    diff1 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff18];
    
    UIImageWriteToSavedPhotosAlbum(diff1,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here
    
    
    UIImage * diff2;
    cv::Mat movieFrameMatDiff28;
    movieFrameMatBW.convertTo(movieFrameMatDiff28, CV_8UC1);
    diff2 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff28];
    
    UIImageWriteToSavedPhotosAlbum(diff2,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here
    
    UIImage * diff3;
    cv::Mat movieFrameMatDiff38;
    movieFrameMatDiff1.convertTo(movieFrameMatDiff38, CV_8UC1);
    diff3 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff38];
    
    UIImageWriteToSavedPhotosAlbum(diff3,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here
    

    
    cv::filter2D(movieFrameMattDiffBackTmp,movieFrameMattDiffBackTmp,-1,backConvMat, cv::Point(-1,-1));
    double backVal1;
    double maxValTrash;
    cv::minMaxLoc(movieFrameMattDiffBackTmp, &backVal1, &maxValTrash);
    movieFrameMatDiff1=movieFrameMatDiff1-backVal1;

    
    movieFrameMattDiffBackTmp=movieFrameMatDiff2+movieFrameMatBW;
    cv::filter2D(movieFrameMattDiffBackTmp,movieFrameMattDiffBackTmp,-1,backConvMat, cv::Point(-1,-1));
    double backVal2;
    cv::minMaxLoc(movieFrameMattDiffBackTmp, &backVal2, &maxValTrash);
    movieFrameMatDiff2=movieFrameMatDiff2-backVal2;

    movieFrameMattDiffBackTmp=movieFrameMatDiff3+movieFrameMatBW;
    cv::filter2D(movieFrameMattDiffBackTmp,movieFrameMattDiffBackTmp,-1,backConvMat, cv::Point(-1,-1));
    double backVal3;
    cv::minMaxLoc(movieFrameMattDiffBackTmp, &backVal3, &maxValTrash);
    movieFrameMatDiff3=movieFrameMatDiff3-backVal3;

    movieFrameMattDiffBackTmp=movieFrameMatDiff4+movieFrameMatBW;
    cv::filter2D(movieFrameMattDiffBackTmp,movieFrameMattDiffBackTmp,-1,backConvMat, cv::Point(-1,-1));
    double backVal4;
    cv::minMaxLoc(movieFrameMattDiffBackTmp, &backVal4, &maxValTrash);
    movieFrameMatDiff4=movieFrameMatDiff4-backVal4;

    
    movieFrameMattDiffBackTmp=movieFrameMatDiff5+movieFrameMatBW;
    cv::filter2D(movieFrameMattDiffBackTmp,movieFrameMattDiffBackTmp,-1,backConvMat, cv::Point(-1,-1));
    double backVal5;
    cv::minMaxLoc(movieFrameMattDiffBackTmp, &backVal5, &maxValTrash);
    movieFrameMatDiff5=movieFrameMatDiff5-backVal5;
    
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

    

    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_16UC1);
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_32F);
    findContours( movieFrameMatDiff1, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:1:32];
    /*int idx = 0;
    for( ; idx >= 0; idx = hierarchy[idx][0] )

    {
        int len=contours[idx].size();
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
        else if (len>1000) {numWorms=numWorms+2;}
        else if (len>1700) {numWorms=numWorms+3;}
        else if (len>2300) {numWorms=numWorms+4;}
        else if (len>2700) {numWorms=numWorms+5;}
        else if (len>3100) {numWorms=numWorms+6;}
        else {    NSLog(@"found small contour %i", len); }


    }*/
    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_16UC1);

    findContours( movieFrameMatDiff2, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:33:60];

    
    findContours( movieFrameMatDiff3, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:61:90];

    
    findContours( movieFrameMatDiff4, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:91:120];

    
    findContours( movieFrameMatDiff5, contours, hierarchy,
                 CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    [self countContours:contours:121:150];
    
    numWorms=numWorms/5;
    NSLog(@"numWorms %i", numWorms);
    return coordsArray;

}

- (void) countContours:(cv::vector<cv::vector<cv::Point> >) contours :(int) start :(int) end {
    int numWorms=0;
    for(int idx = 0;idx<contours.size(); idx++)
        
    {
        int len=contours[idx].size();
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
        else if (len>1000) {
            numWorms=numWorms+2;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
        }
        else if (len>1700) {
            numWorms=numWorms+3;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];

        }
        else if (len>2300) {
            numWorms=numWorms+4;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
        }
        else if (len>2700) {
            numWorms=numWorms+5;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];
        }
        else if (len>3100) {
            numWorms=numWorms+6;
            NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            [coordsArray addObject:x];
            NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:1];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:32];
            [coordsArray addObject:end];

        }
        else {    NSLog(@"found small contour %i", len); }
    }
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"error saving image");
        
    } else {
        NSLog(@"image saved in photo album");
    }
}


@end
