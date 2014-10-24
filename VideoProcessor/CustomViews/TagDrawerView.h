//
//  Drawer.h
//  VideoProcessor
//
//  Created by kunal singh on 08/10/14.
//  Copyright (c) 2014 Kunal Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AppConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface TagDrawerView : UIView

-(void) setDrawingColor:(UIColor *) drawcolor; // set the drawing color
-(void) setTag:(NSString *) videotag; // set the tag for the video
-(BOOL) isTagAlreadyPresent:(NSString *) videotag; // check whether the tag already present
-(void) setTheVideoAsset:(NSURL *) videourl; // set the video asset for the overlay mix
- (void) saveTheTaggedVideo; // save the video with the overlay

@property(nonatomic, strong) AVAsset *mediaAsset;


@end
