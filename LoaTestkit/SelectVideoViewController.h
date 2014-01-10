//
//  SelectVideoViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectVideoDelegate <NSObject>

@optional
- (void)didMakeSelectionWithInfo:(NSDictionary *)info;
- (void)didCancel;

@end

@interface SelectVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) id<SelectVideoDelegate> delegate;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end