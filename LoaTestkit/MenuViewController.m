//
//  MenuViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "MenuViewController.h"
#import "SelectVideoViewController.h"
#import "PlayVideoViewController.h"
#import "ProcessFramesViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

@synthesize assetURL;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SelectVideo delegate

- (void)didMakeSelectionWithInfo:(NSDictionary *)info
{
    NSURL* url = [info objectForKey:UIImagePickerControllerReferenceURL];
    assetURL = url;
}

- (void)didCancel
{
    
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Select"]) {
        SelectVideoViewController* viewController = (SelectVideoViewController*)segue.destinationViewController;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"Play"]) {
        PlayVideoViewController* viewController = (PlayVideoViewController*)segue.destinationViewController;
        viewController.assetURL = self.assetURL;
    }
    else if ([segue.identifier isEqualToString:@"Process"]) {
        ProcessFramesViewController* viewController = (ProcessFramesViewController*)segue.destinationViewController;
        viewController.assetURL = self.assetURL;
    }
}

@end
