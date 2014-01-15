//
//  ReviewVideoViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProcessingResults.h"

@interface ReviewVideoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) ProcessingResults* processingResults;
@property (strong, nonatomic) NSMutableArray* circleLayers;

@end
