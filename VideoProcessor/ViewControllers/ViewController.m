//
//  ViewController.m
//  VideoProcessor
//
//  Created by kunal singh on 08/10/14.
//  Copyright (c) 2014 Kunal Labs. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, strong) id videoExportCompleted;

@end

@implementation ViewController{
    UIActivityIndicatorView *exportVideoIndicator;
}



- (void)viewDidLoad{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.videoController = [[MPMoviePlayerController alloc] init];
    
    // set the media file for the media controller
    NSURL *videourl = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:@"sample" ofType:@"m4v"]];
    [self.videoController setContentURL:videourl];
    
    // set the video asset for the drawer view for merging the overlay and the video
    [self.drawerView setTheVideoAsset:videourl];
    
    [self.videoController.view setFrame:self.view.frame];
    [self.view addSubview:self.videoController.view];
    
    [self.videoController play];
    
    // adding the notification listener for getting the video natural size and resizing the overlay to the same size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieNaturalSizeAvailable:)   name:MPMoviePlayerLoadStateDidChangeNotification object:self.videoController];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.videoExportCompleted = [[NSNotificationCenter defaultCenter] addObserverForName:VIDEO_EXPORT_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self stopActivityIndicator];
    }];
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.videoExportCompleted name:VIDEO_EXPORT_NOTIFICATION object:nil];
}



-(void) movieNaturalSizeAvailable:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.videoController];
    
    [self equalizeMediaPlayerAndOverlaySize:self.videoController.naturalSize];
   
   // bring the overlay to the front
    [self.view bringSubviewToFront:self.drawerView];
}

-(void) equalizeMediaPlayerAndOverlaySize:(CGSize ) naturalsize{
    float aspectRatio = naturalsize.width / naturalsize.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    float predictedvideoheight = screenWidth / aspectRatio;
    self.videoController.view.frame = CGRectMake(0.0f,
                                                 (screenHeight - predictedvideoheight) / 2.0f, screenWidth, predictedvideoheight);
    self.drawerView.frame = CGRectMake(0.0f,
                                       (screenHeight - predictedvideoheight) / 2.0f, screenWidth, predictedvideoheight);
}

- (IBAction)selectColorTabs:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.drawerView setDrawingColor:[UIColor redColor]];
    } else if(sender.selectedSegmentIndex == 1) {
        [self.drawerView setDrawingColor:[UIColor greenColor]];
    } else if(sender.selectedSegmentIndex == 2) {
        [self.drawerView setDrawingColor:[UIColor blueColor]];
    }
}


- (IBAction)saveVideoClicked:(UIButton *)sender {
    [self startActivityIndicator];
    [self.videoController pause];
    [self.drawerView saveTheTaggedVideo];
}

-(void) startActivityIndicator{
    exportVideoIndicator = [[UIActivityIndicatorView alloc]
                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    exportVideoIndicator.center = self.view.center;
    [exportVideoIndicator startAnimating];
    [self.view addSubview:exportVideoIndicator];
}

-(void) stopActivityIndicator{
    if(exportVideoIndicator){
        [exportVideoIndicator stopAnimating];
        [exportVideoIndicator removeFromSuperview];
        exportVideoIndicator = nil;
    }
}


- (IBAction)tagClicked:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:VIDEO_TAGGER_TITLE message:VIDEO_TAGGER_MESSAGE delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        NSString *tagname = [alertView textFieldAtIndex:0].text;
        if(![self.drawerView isTagAlreadyPresent:tagname]){
            [self.drawerView setTag:tagname];
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DIALOG_ERROR_TITLE
                                                                message:VIDEO_TAGGER_ERROR_MESSAGE
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}


- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}






@end
