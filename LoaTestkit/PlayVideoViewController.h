//
//  PlayVideoViewController.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PlayVideoViewController : UIViewController

@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong, nonatomic) NSURL* assetURL;


- (IBAction)playMovie:(id)sender;
- (void)moviePlayBackDidFinish:(NSNotification*)notification;

@end