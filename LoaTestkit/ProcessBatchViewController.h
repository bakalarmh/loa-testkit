//
//  ProcessBatchViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 2/9/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBImagePickerController.h"
#import "ProcessFramesViewController.h"

@interface ProcessBatchViewController : UIViewController <QBImagePickerControllerDelegate, ProcessFramesDelegate>

- (void)dismissImagePickerController;

@end
