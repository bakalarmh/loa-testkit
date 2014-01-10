//
//  MenuViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectVideoViewController.h"

@interface MenuViewController : UITableViewController <SelectVideoDelegate>

@property (strong, nonatomic) NSURL *assetURL;

@end
