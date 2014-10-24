//
//  ViewController.h
//  VideoProcessor
//
//  Created by kunal singh on 08/10/14.
//  Copyright (c) 2014 Kunal Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagDrawerView.h"
#import "AppConstants.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet TagDrawerView *drawerView;
@property (strong, nonatomic) MPMoviePlayerController *videoController;



@end
