//
//  ProcessBatchViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 2/9/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessBatchViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ProcessBatchViewController () {
    bool firstRun;
    NSMutableArray* pickedAssetURLs;
    NSURL* assetURL;
}

@end

@implementation ProcessBatchViewController

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
	// Do any additional setup after loading the view.
    firstRun = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (firstRun) {
        QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsMultipleSelection = YES;
        [self.navigationController pushViewController:imagePickerController animated:YES];
        firstRun = NO;
    }
    else {
        if (pickedAssetURLs.count > 0) {
            assetURL = [pickedAssetURLs objectAtIndex:0];
            [pickedAssetURLs removeObjectAtIndex:0];
            [self performSegueWithIdentifier:@"Process" sender:self];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissImagePickerController
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Process"]) {
        ProcessFramesViewController* viewController = (ProcessFramesViewController*)segue.destinationViewController;
        viewController.assetURL = assetURL;
        viewController.delegate = self;
    }
}

#pragma mark - QBImagePickerControllerDelegate

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(ALAsset *)asset
{
    pickedAssetURLs = [[NSMutableArray alloc] init];
    NSURL* myAssetURL = [asset valueForProperty:@"ALAssetPropertyAssetURL"];
    [pickedAssetURLs addObject:myAssetURL];

    [self dismissImagePickerController];
}

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets
{
    pickedAssetURLs = [[NSMutableArray alloc] init];
    for (ALAsset* asset in assets) {
        NSURL* myAssetURL = [asset valueForProperty:@"ALAssetPropertyAssetURL"];
        [pickedAssetURLs addObject:myAssetURL];
    }
    [self dismissImagePickerController];
}

- (void)imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"*** imagePickerControllerDidCancel:");
    
    [self dismissImagePickerController];
}

#pragma mark - ProcessingFramesViewControllerDelegate
- (void)finishedProcessingWithResults:(ProcessingResults *)results
{
    // Pass
}


@end
