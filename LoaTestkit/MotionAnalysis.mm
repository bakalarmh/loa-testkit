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
double numWorms=0;
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
    //coordsArray = [[NSMutableArray alloc] init];
    numWorms=0;
    movieIdx = 0;
    //NSNumber *movielength = [movieLengths objectAtIndex:0];
    NSInteger numFrames = 148;
    
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
    cv::Mat movieFrameMatIllum;

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
    while(frameIdx < (frameBuffers.numFrames.integerValue)) {
        //[self setProgressWithMovie:movidx Frame:frameIdx];
        while(i < avgFrames) {
            // Update the progress bar
            //[self setProgressWithMovie:movidx Frame:frameIdx];
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx);
            //NSLog(@"bufferidxinit: %i", bufferIdx);
            movieFrameMat = [frameBuffers getFrameAtIndex:bufferIdx];
            

            if (i==0){
                threshold(movieFrameMat, movieFrameMatBW, 30, 255, CV_THRESH_BINARY_INV);
                threshold(movieFrameMat, movieFrameMatBWInv, 30, 1, CV_THRESH_BINARY);

                cv::Mat element = getStructuringElement(CV_SHAPE_ELLIPSE, cv::Size( 10,10 ), cv::Point( 2, 2 ));
                cv::morphologyEx(movieFrameMatBW,movieFrameMatBW, CV_MOP_DILATE, element );
                //cv::Mat movieFrameMatBWInv;
                //cv::subtract(cv::Scalar::all(255),movieFrameMatBW, movieFrameMatBW);
                movieFrameMatBW.convertTo(movieFrameMatBW, CV_16UC1);
                movieFrameMatBW=movieFrameMatBW*255;
                
                movieFrameMatIllum=movieFrameMat.clone();
                movieFrameMatIllum.convertTo(movieFrameMatIllum, CV_16UC1);

                

            }
            //cv::multiply(movieFrameMat, movieFrameMatBW, movieFrameMat);

            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            
            if (i == 0){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                
                /*UIImage * diff3;
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
            else if  (i<=64) {
                movieFrameMatDiff2 = movieFrameMatDiff2 + movieFrameMatDiffTmp;

            }
            else if (i<=92) {
                movieFrameMatDiff3 = movieFrameMatDiff3 + movieFrameMatDiffTmp;

            }
            else if (i<=120) {
                movieFrameMatDiff4 = movieFrameMatDiff4 + movieFrameMatDiffTmp;

            }
            else if (i<=148) {

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
    cv::Mat backgroundConvMat= cv::Mat::ones(10, 10, CV_32FC1);
    //backConvMat=backConvMat*.005;
    cv::Scalar sum=cv::sum(movieFrameMatDiff);
    NSLog(@"sum is %f", sum[0]);
    movieFrameMatDiff=movieFrameMatDiff+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff,movieFrameMatDiff,-1,backgroundConvMat, cv::Point(-1,-1));
    
    
    /*UIImage * diff4;
    cv::Mat movieFrameMatDiff48;
    cv::divide(movieFrameMatDiff, 255, movieFrameMatDiff48);
    movieFrameMatDiff48.convertTo(movieFrameMatDiff48, CV_8UC1);
    diff4 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff48];
    UIImageWriteToSavedPhotosAlbum(diff4,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here */

    
    
    double backVal;
    double maxValTrash;
    cv::minMaxLoc(movieFrameMatDiff, &backVal, &maxValTrash);
    double backCorrFactor=sum[0]/1000000;
    backCorrFactor=3.98/backCorrFactor*1.5; //2 is good for standard alg (non peak finding)
    if (backCorrFactor>4) backCorrFactor=4;
    //backVal=round((backVal/100)*300); //good for low
    //backVal=round((backVal/100)*150); //good for high
    
    //backVal=round(backVal*3); //good for low
    //backVal=round(backVal*1.5); //good for high
    backVal=backVal*backCorrFactor; //good for everything
    
    //calc illumination uniformity
    
    //double illumMinVal;
    //double illumMaxVal;
    cv::filter2D(movieFrameMatIllum,movieFrameMatIllum,-1,backConvMat, cv::Point(-1,-1));
    //cv::minMaxLoc(movieFrameMatIllum, &illumMinVal, &illumMaxVal);
    movieFrameMatIllum.convertTo(movieFrameMatIllum, CV_32F);
    cv::divide(movieFrameMatIllum, 400, movieFrameMatIllum);
    double illVal;
    double maxill;
    cv::minMaxLoc(movieFrameMatIllum, &illVal, &maxill);
    NSLog(@"max, min of illum is %f, %f", maxill, illVal);
    cv::divide(movieFrameMatIllum, maxill, movieFrameMatIllum);
    
    movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_32F);
    cv::multiply(movieFrameMatDiff1, movieFrameMatIllum, movieFrameMatDiff1);
    movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_16UC1);

    movieFrameMatDiff2.convertTo(movieFrameMatDiff2, CV_32F);
    cv::multiply(movieFrameMatDiff2, movieFrameMatIllum, movieFrameMatDiff2);
    movieFrameMatDiff2.convertTo(movieFrameMatDiff2, CV_16UC1);

    movieFrameMatDiff3.convertTo(movieFrameMatDiff3, CV_32F);
    cv::multiply(movieFrameMatDiff3, movieFrameMatIllum, movieFrameMatDiff3);
    movieFrameMatDiff3.convertTo(movieFrameMatDiff3, CV_16UC1);

    movieFrameMatDiff4.convertTo(movieFrameMatDiff4, CV_32F);
    cv::multiply(movieFrameMatDiff4, movieFrameMatIllum, movieFrameMatDiff4);
    movieFrameMatDiff4.convertTo(movieFrameMatDiff4, CV_16UC1);

    //movieFrameMatIllum.convertTo(movieFrameMatIllum, CV_32F);
    movieFrameMatDiff5.convertTo(movieFrameMatDiff5, CV_32F);
    
        //cv::multiply(movieFrameMatDiff5, maxill, movieFrameMatDiff5);
    double illVal6;
    double maxill6;
    cv::minMaxLoc(movieFrameMatDiff5, &illVal6, &maxill6);
    NSLog(@"max of diff 5 before  is %f", maxill6);

    cv::multiply(movieFrameMatDiff5, movieFrameMatIllum, movieFrameMatDiff5);
    movieFrameMatDiff5.convertTo(movieFrameMatDiff5, CV_16UC1);
    double illVal5;
    double maxill5;
    cv::minMaxLoc(movieFrameMatDiff5, &illVal5, &maxill5);
    NSLog(@"max of diff 5 after is %f", maxill5);

    
    UIImage * diff4;
    cv::Mat movieFrameMatDiff48=movieFrameMatDiff5.clone();
    //cv::divide(movieFrameMatDiff48, 1, movieFrameMatDiff48);
    movieFrameMatDiff48.convertTo(movieFrameMatDiff48, CV_8UC1);
    diff4 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff48];
    UIImageWriteToSavedPhotosAlbum(diff4,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here */

    
    //new background calcs1
    cv::Scalar sum1=cv::sum(movieFrameMatDiff1);
    NSLog(@"sum1 is %f", sum1[0]);
    cv::Mat movieFrameMatDiff1Back=movieFrameMatDiff1+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff1Back,movieFrameMatDiff1Back,-1,backgroundConvMat, cv::Point(-1,-1));
    double backVal1;
    double maxValTrash1;
    cv::minMaxLoc(movieFrameMatDiff1Back, &backVal1, &maxValTrash1);
    double backCorrFactor1=sum1[0]/1000000;
    backCorrFactor1=3.98/backCorrFactor1*1; //2 is good for standard alg (non peak finding)
    //if (backCorrFactor1>25) backCorrFactor1=25;
    backVal1=backVal1*backCorrFactor1; //good for everything
    
    
    
    
    
    //new background calcs2
    cv::Scalar sum2=cv::sum(movieFrameMatDiff2);
    NSLog(@"sum2 is %f", sum2[0]);
    cv::Mat movieFrameMatDiff2Back=movieFrameMatDiff2+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff2Back,movieFrameMatDiff2Back,-1,backgroundConvMat, cv::Point(-1,-1));
    double backVal2;
    double maxValTrash2;
    cv::minMaxLoc(movieFrameMatDiff2Back, &backVal2, &maxValTrash2);
    double backCorrFactor2=sum2[0]/1000000;
    backCorrFactor2=3.98/backCorrFactor2*1; //2 is good for standard alg (non peak finding)
    //if (backCorrFactor2>25) backCorrFactor2=25;
    backVal2=backVal2*backCorrFactor2; //good for everything
    
    //new background calcs3
    cv::Scalar sum3=cv::sum(movieFrameMatDiff3);
    NSLog(@"sum3 is %f", sum3[0]);
    cv::Mat movieFrameMatDiff3Back=movieFrameMatDiff3+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff3Back,movieFrameMatDiff3Back,-1,backgroundConvMat, cv::Point(-1,-1));
    double backVal3;
    double maxValTrash3;
    cv::minMaxLoc(movieFrameMatDiff3Back, &backVal3, &maxValTrash3);
    double backCorrFactor3=sum3[0]/1000000;
    backCorrFactor3=3.98/backCorrFactor3*1; //2 is good for standard alg (non peak finding)
    //if (backCorrFactor3>25) backCorrFactor3=25;
    backVal3=backVal3*backCorrFactor3; //good for everything

    //new background calcs4
    cv::Scalar sum4=cv::sum(movieFrameMatDiff4);
    NSLog(@"sum4 is %f", sum4[0]);
    cv::Mat movieFrameMatDiff4Back=movieFrameMatDiff4+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff4Back,movieFrameMatDiff4Back,-1,backgroundConvMat, cv::Point(-1,-1));
    double backVal4;
    double maxValTrash4;
    cv::minMaxLoc(movieFrameMatDiff4Back, &backVal4, &maxValTrash4);
    double backCorrFactor4=sum4[0]/1000000;
    backCorrFactor4=3.98/backCorrFactor4*1; //2 is good for standard alg (non peak finding)
    //if (backCorrFactor4>25) backCorrFactor4=25;
    backVal4=backVal4*backCorrFactor4; //good for everything

    //new background calcs5
    cv::Scalar sum5=cv::sum(movieFrameMatDiff5);
    NSLog(@"sum5 is %f", sum5[0]);
    cv::Mat movieFrameMatDiff5Back=movieFrameMatDiff5+movieFrameMatBW;
    cv::filter2D(movieFrameMatDiff5Back,movieFrameMatDiff5Back,-1,backgroundConvMat, cv::Point(-1,-1));
    double backVal5;
    double maxValTrash5;
    cv::minMaxLoc(movieFrameMatDiff5Back, &backVal5, &maxValTrash5);
    double backCorrFactor5=sum5[0]/1000000;
    backCorrFactor5=3.98/backCorrFactor5*1; //2 is good for standard alg (non peak finding)
    //if (backCorrFactor5>20) backCorrFactor5=20;
    NSLog(@"backcorrfac5 is %f", backCorrFactor5);

    backVal5=backVal5*backCorrFactor5; //good for everything
    NSLog(@"back5 is %f", backVal5);

    

    
    
    
    movieFrameMatBWInv.convertTo(movieFrameMatBWInv, CV_16UC1);
    //spatially filter and subtract background
    cv::filter2D(movieFrameMatDiff1,movieFrameMatDiff1,-1,backConvMat, cv::Point(-1,-1));
    
    movieFrameMatDiff1=movieFrameMatDiff1-backVal1;
    

    
    multiply(movieFrameMatDiff1, movieFrameMatBWInv, movieFrameMatDiff1);

    cv::filter2D(movieFrameMatDiff2,movieFrameMatDiff2,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff2=movieFrameMatDiff2-backVal2;
    multiply(movieFrameMatDiff2, movieFrameMatBWInv, movieFrameMatDiff2);


    cv::filter2D(movieFrameMatDiff3,movieFrameMatDiff3,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff3=movieFrameMatDiff3-backVal3;
    multiply(movieFrameMatDiff3, movieFrameMatBWInv, movieFrameMatDiff3);


    cv::filter2D(movieFrameMatDiff4,movieFrameMatDiff4,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff4=movieFrameMatDiff4-backVal4;
    multiply(movieFrameMatDiff4, movieFrameMatBWInv, movieFrameMatDiff4);


    cv::filter2D(movieFrameMatDiff5,movieFrameMatDiff5,-1,backConvMat, cv::Point(-1,-1));
    movieFrameMatDiff5=movieFrameMatDiff5-backVal5;
    multiply(movieFrameMatDiff5, movieFrameMatBWInv, movieFrameMatDiff5);

    
    
    [self getLocalMaxima:movieFrameMatDiff1: 17: 1: 5:1:32];

    movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_8UC1);

    cv::Mat movieFrameMatForWatGray;
    threshold(movieFrameMatDiff1, movieFrameMatForWatGray, 1, 255, CV_THRESH_TOZERO);
    threshold(movieFrameMatDiff1, movieFrameMatDiff1, 1, 255, CV_THRESH_BINARY);
    cv::Mat movieFrameMatDiff1ForWat=movieFrameMatDiff1.clone();
    //cv::Mat wat1=[self doWatershed:movieFrameMatDiff1 :movieFrameMatForWatGray];
    //movieFrameMatDiff1.convertTo(movieFrameMatDiff1, CV_8UC1);
    //multiply(movieFrameMatDiff1,wat1,movieFrameMatDiff1);
    
    
    
    /*UIImage * diff3;
    cv::Mat movieFrameMatDiff38;
    movieFrameMatDiff1.convertTo(movieFrameMatDiff38, CV_8UC1);
    diff3 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff38*255];
    UIImageWriteToSavedPhotosAlbum(diff3,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here */

    [self getLocalMaxima:movieFrameMatDiff2: 17: 1: 5:33:60];

    movieFrameMatDiff2.convertTo(movieFrameMatDiff2, CV_8UC1);

    threshold(movieFrameMatDiff2, movieFrameMatForWatGray, 1, 255, CV_THRESH_TOZERO);
    threshold(movieFrameMatDiff2, movieFrameMatDiff2, 1, 255, CV_THRESH_BINARY);
    movieFrameMatDiff1ForWat=movieFrameMatDiff2.clone();
    //wat1=[self doWatershed:movieFrameMatDiff2 :movieFrameMatForWatGray];
    //movieFrameMatDiff2.convertTo(movieFrameMatDiff2, CV_8UC1);
    //multiply(movieFrameMatDiff1,wat1,movieFrameMatDiff1);
    [self getLocalMaxima:movieFrameMatDiff3: 17: 1: 5:61:90];

    movieFrameMatDiff3.convertTo(movieFrameMatDiff3, CV_8UC1);

    threshold(movieFrameMatDiff3, movieFrameMatDiff3, 1, 255, CV_THRESH_BINARY);
    threshold(movieFrameMatDiff3, movieFrameMatDiff3, 1, 255, CV_THRESH_BINARY);
    movieFrameMatDiff1ForWat=movieFrameMatDiff3.clone();
    //wat1=[self doWatershed:movieFrameMatDiff3 :movieFrameMatForWatGray];
    //movieFrameMatDiff3.convertTo(movieFrameMatDiff3, CV_8UC1);
    //multiply(movieFrameMatDiff1,wat1,movieFrameMatDiff1);

    [self getLocalMaxima:movieFrameMatDiff4: 17: 1: 5:91:120];

    movieFrameMatDiff4.convertTo(movieFrameMatDiff4, CV_8UC1);

    threshold(movieFrameMatDiff4, movieFrameMatDiff4, 1, 255, CV_THRESH_BINARY);
    threshold(movieFrameMatDiff4, movieFrameMatDiff4, 1, 255, CV_THRESH_BINARY);
    movieFrameMatDiff1ForWat=movieFrameMatDiff4.clone();
    //wat1=[self doWatershed:movieFrameMatDiff4 :movieFrameMatForWatGray];
    //movieFrameMatDiff4.convertTo(movieFrameMatDiff4, CV_8UC1);
    //multiply(movieFrameMatDiff1,wat1,movieFrameMatDiff1);

    [self getLocalMaxima:movieFrameMatDiff5: 17: 1: 5:121:150];

    movieFrameMatDiff5.convertTo(movieFrameMatDiff5, CV_8UC1);

    threshold(movieFrameMatDiff5, movieFrameMatDiff5, 1, 255, CV_THRESH_BINARY);
    threshold(movieFrameMatDiff5, movieFrameMatDiff5, 1, 255, CV_THRESH_BINARY);
    movieFrameMatDiff1ForWat=movieFrameMatDiff5.clone();
    //wat1=[self doWatershed:movieFrameMatDiff5 :movieFrameMatForWatGray];
    //movieFrameMatDiff5.convertTo(movieFrameMatDiff5, CV_8UC1);
    //multiply(movieFrameMatDiff1,wat1,movieFrameMatDiff1);

    /*
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
    */
    numWorms=numWorms/5;
    NSLog(@"numWorms %f", numWorms);
    
    
    
    
    
    movieFrameMatDiff.release();
    movieFrameMatDiff1.release();
    movieFrameMatDiff2.release();
    movieFrameMatDiff3.release();
    movieFrameMatDiff4.release();
    movieFrameMatDiff5.release();
    movieFrameMatBW.release();

    return coordsArray;

}

-(cv::Mat) doWatershed:(cv::Mat) movieFrameMatDiff1ForWat: (cv::Mat) movieFrameMatDiff1ForWatGray {
    
    //test watershed
    cv::Mat kernel= cv::Mat::ones(3, 3, CV_32FC1);
    
    //sure_bg = cv2.dilate(movieFrameMatWat,kernel,iterations=3)
    cv::Mat sureBG;
    cv::Mat element = getStructuringElement(CV_SHAPE_RECT, cv::Size( 3,3 ));
    cv::morphologyEx(movieFrameMatDiff1ForWat,sureBG, CV_MOP_DILATE, element );
    cv::morphologyEx(sureBG,sureBG, CV_MOP_DILATE, element );
    cv::morphologyEx(sureBG,sureBG, CV_MOP_DILATE, element );
    //cv::filter2D(movieFrameMatWat,sureBG,-1,kernel, cv::Point(-1,-1));
    //cv::filter2D(sureBG,sureBG,-1,kernel, cv::Point(-1,-1));
    //cv::filter2D(sureBG,sureBG,-1,kernel, cv::Point(-1,-1));
    
    //dist_transform = cv2.distanceTransform(opening,cv2.DIST_L2,5)
    cv::Mat distTrans;
    distanceTransform(movieFrameMatDiff1ForWat, distTrans, CV_DIST_L2, 5);
    //ret, sure_fg = cv2.threshold(dist_transform,0.7*dist_transform.max(),255,0)
    cv::Mat sureFG;
    double maxVal;
    double minValTrash;
    cv::minMaxLoc(distTrans, &minValTrash, &maxVal);
    
    threshold(distTrans, sureFG,0.5*maxVal, 255, CV_THRESH_BINARY);
    cv::Mat unknown;
    sureFG.convertTo(sureFG, CV_8UC1);
    cv::subtract(sureBG, sureFG, unknown);
    int compCount = 0;
    cv::vector<cv::vector<cv::Point> > contours2;
    cv::vector<cv::Vec4i> hierarchy2;
    
    findContours(sureFG, contours2, hierarchy2, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    cv::Mat markers=cv::Mat::ones(sureFG.size(), CV_32S);

    if( !contours2.empty() ){
        
        //cv::Mat markers(sureFG.size(), CV_32S);
        markers = cv::Scalar::all(0);
        int idx = 0;
        for( ; idx >= 0; idx = hierarchy2[idx][0], compCount++ ) {
            drawContours(markers, contours2, idx, cv::Scalar::all(compCount+1), -1, 8, hierarchy2, INT_MAX);
        }
        
        markers=markers+1;
        unknown.convertTo(unknown, CV_32S);
        markers=markers-(unknown/255);
        cv::Mat movieFrameMatWatRGB;
        cvtColor(movieFrameMatDiff1ForWatGray, movieFrameMatWatRGB, CV_GRAY2RGB);
        //movieFrameMatWat.convertTo(movieFrameMatWatRGB, CV_8UC3);
        watershed( movieFrameMatWatRGB, markers );
        markers=markers+1;
        markers.convertTo(markers, CV_8UC1);
        threshold(markers, markers,1, 1, CV_THRESH_BINARY);
        
        //markers.convertTo(markers,CV_8UC1);'
        /*UIImage * diff3;
         cv::Mat movieFrameMatDiff38;
         markers.convertTo(movieFrameMatDiff38, CV_8UC1);
         diff3 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff38*255];
         UIImageWriteToSavedPhotosAlbum(diff3,
         self, // send the message to 'self' when calling the callback
         @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
         NULL); // you generally won't need a contextInfo here */
        
    }
    markers.convertTo(markers, CV_8UC1);
    return markers;

    
}

- (void) countContours:(cv::vector<cv::vector<cv::Point> >) contours :(cv::vector<cv::Vec4i>) hierarchy:(int) starti :(int) endi {
    cv::RNG rng(12345);

    cv::Mat drawing = cv::Mat::zeros(360,480, CV_8UC3 );
    
    for(int idx = 0;idx<contours.size(); idx++)
        
    {
        cv::Scalar color = cv::Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours( drawing, contours, idx, color, 2, 8, hierarchy, 0, cv::Point() );
        
        //calculate moments
        cv::Moments mom;
        mom=cv::moments(contours[idx], true);
        //get centroids
        cv::Point2f mc;
        mc = cv::Point2f( mom.m10/mom.m00 ,mom.m01/mom.m00 );

        
        double len=contourArea(contours[idx]);
        NSLog(@"found contour %f", len);
        
        if (len>14100) {
            numWorms=numWorms+8;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            
            for (int i=0; i<=7; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }
        }

        
        else if (len>12100) {
            numWorms=numWorms+7;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            
            for (int i=0; i<=6; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }
        }

        
        else if (len>10100) {
            numWorms=numWorms+6;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            
            for (int i=0; i<=5; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];

            }
        }
        else if (len>8100) {
            numWorms=numWorms+5;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            for (int i=0; i<=4; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }

        }

        else if (len>6100) {
            numWorms=numWorms+4;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            for (int i=0; i<=3; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }

        }

        else if (len>4100) {
            numWorms=numWorms+3;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            for (int i=0; i<=2; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }
            
        }
        
        else if (len>2100) {
            numWorms=numWorms+2;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            //[coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            //[coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            //[coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            //[coordsArray addObject:end];
            
            for (int i=0; i<=1; i++){
                //just write again since we don't have real positions
                [coordsArray addObject:x];
                [coordsArray addObject:y];
                [coordsArray addObject:start];
                [coordsArray addObject:end];
                
            }
            
        }

        if (len>100) {
            numWorms=numWorms+1;
            //NSNumber *x = [NSNumber numberWithInt:contours[idx][0].x];
            NSNumber *x=[NSNumber numberWithInt:mc.x];
            [coordsArray addObject:x];
            //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
            NSNumber *y=[NSNumber numberWithInt:mc.y];
            [coordsArray addObject:y];
            NSNumber *start = [NSNumber numberWithInt:starti];
            [coordsArray addObject:start];
            NSNumber *end = [NSNumber numberWithInt:endi];
            [coordsArray addObject:end];
            
        }
        else {
            //NSLog(@"found small contour %f", len);
        }
    }
    /*UIImage * diff2;
    cv::Mat movieFrameMatDiff28;
    drawing.convertTo(movieFrameMatDiff28, CV_8UC1);
    diff2 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff28];
    
    UIImageWriteToSavedPhotosAlbum(diff2,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here*/

}

//cv::vector <cv::Point> GetLocalMaxima(const cv::Mat Src,int MatchingSize, int Threshold, int GaussKernel  )
//cv::Mat GetLocalMaxima(const cv::Mat Src,int MatchingSize, int Threshold, int GaussKernel  )
-(cv::vector <cv::Point>) getLocalMaxima:(const cv::Mat) src:(int) matchingSize: (int) threshold: (int) gaussKernel:(int) starti :(int) endi


{

    cv::vector <cv::Point> vMaxLoc(0);
    
    //MatchingSize=14;
    vMaxLoc.reserve(100); // Reserve place for fast access
    cv::Mat processImg = src.clone();
    int w = src.cols;
    int h = src.rows;
    //cv::Mat out=cv::Mat::zeros(H,W,CV_8UC1);

    int searchWidth  = w - matchingSize;
    int searchHeight = h - matchingSize;
    int matchingSquareCenter = matchingSize/2;
    
    uchar* pProcess = (uchar *) processImg.data; // The pointer to image Data
    
    int shift = matchingSquareCenter * ( w + 1);
    int k = 0;
    threshold=0;
    for(int y=0; y < searchHeight; ++y)
    {
        int m = k + shift;
        for(int x=0;x < searchWidth ; ++x)
        {
            if (pProcess[m++] >= threshold)
            {
                cv::Point locMax;
                cv::Mat mROI(processImg, cv::Rect(x,y,matchingSize,matchingSize));
                minMaxLoc(mROI,NULL,NULL,NULL,&locMax);
                if (locMax.x == matchingSquareCenter && locMax.y == matchingSquareCenter)
                {
                    vMaxLoc.push_back(cv::Point( x+locMax.x,y + locMax.y ));
                    //NSLog(@"%i %i", x+LocMax.x, y+LocMax.y);
                    int xi=x+locMax.x;
                    int yi= y+locMax.y;
                    //out.at<uchar>( y+LocMax.y,x+LocMax.x) = 255;
                    NSNumber *x=[NSNumber numberWithInt:xi];
                    //[coordsArray addObject:x];
                    //NSNumber *y = [NSNumber numberWithInt:contours[idx][0].y];
                    NSNumber *y=[NSNumber numberWithInt:yi];
                    //[coordsArray addObject:y];
                    NSNumber *start = [NSNumber numberWithInt:starti];
                    //[coordsArray addObject:start];
                    NSNumber *end = [NSNumber numberWithInt:endi];
                    //[coordsArray addObject:end];
                    [coordsArray addObject:x];
                    [coordsArray addObject:y];
                    [coordsArray addObject:start];
                    [coordsArray addObject:end];
                    numWorms=numWorms+1;

                    // imshow("W1",mROI);cvWaitKey(0); //For gebug
                }
            }
        }
        k += w;
    }
    /*UIImage * diff2;
    cv::Mat movieFrameMatDiff28;
    out.convertTo(movieFrameMatDiff28, CV_8UC1);
    diff2 = [[UIImage alloc] initWithCVMat:movieFrameMatDiff28];
    
    UIImageWriteToSavedPhotosAlbum(diff2,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here*/

    return vMaxLoc;
    //return out;
}


- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"error saving image");
        
    } else {
        NSLog(@"image saved in photo album");
    }
}


@end
