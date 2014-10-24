//
//  Drawer.m
//  VideoProcessor
//
//  Created by kunal singh on 08/10/14.
//  Copyright (c) 2014 Kunal Labs. All rights reserved.
//

#import "TagDrawerView.h"


@implementation TagDrawerView{
    UIColor *tagshapecolor;
    NSMutableDictionary *drawingroutesdictionary;
    NSMutableArray *drawingroutearray;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
    drawingroutesdictionary = [[NSMutableDictionary alloc] init];
    tagshapecolor = [UIColor redColor];
}



-(void) setDrawingColor:(UIColor *) drawcolor{
    tagshapecolor = drawcolor;
}

- (void)drawRect:(CGRect)rect {
    for(id key in drawingroutesdictionary) {
        NSDictionary *drawingsubdictionary = [drawingroutesdictionary objectForKey:key];
        UIColor * tagcolor = [[drawingsubdictionary allKeys] objectAtIndex:0];
        NSMutableArray *drawingsubarray = [drawingsubdictionary objectForKey:tagcolor];
        CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), tagcolor.CGColor);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(),[drawingsubarray[0][0] intValue],[drawingsubarray[0][1] intValue]);
        for (int i = 0; i < [drawingsubarray count]; i++){
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), [drawingsubarray[i][0] intValue], [drawingsubarray[i][1] intValue]);
        }
        CGContextStrokePath(UIGraphicsGetCurrentContext());
    }
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), tagshapecolor.CGColor);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(),[drawingroutearray[0][0] intValue],[drawingroutearray[0][1] intValue]);
    for (int i = 0; i < [drawingroutearray count]; i++){
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), [drawingroutearray[i][0] intValue], [drawingroutearray[i][1] intValue]);
    }
    CGContextStrokePath(UIGraphicsGetCurrentContext());
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    drawingroutearray = [NSMutableArray array];
	[drawingroutearray addObject:@[@([[touches anyObject]locationInView:self].x), @([[touches anyObject]locationInView:self].y)]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [drawingroutearray addObject:@[@([[touches anyObject]locationInView:self].x), @([[touches anyObject]locationInView:self].y)]];
    [self setNeedsDisplay];
}

-(void) setTag:(NSString *) videotag{
    NSDictionary *drawingsubdictionary = [NSDictionary dictionaryWithObject:drawingroutearray forKey:tagshapecolor];
    [drawingroutesdictionary setObject:drawingsubdictionary forKey:videotag];
}

-(BOOL) isTagAlreadyPresent:(NSString *) videotag{
    NSArray * tagarrays = [drawingroutesdictionary allKeys];
    for(int i = 0;i < [tagarrays count];i++){
        NSString * tags = [tagarrays objectAtIndex:i];
        if([tags isEqualToString:videotag]){
            return YES;
        }
    }
    return NO;
}

-(void) setTheVideoAsset:(NSURL *) videourl{
    self.mediaAsset = [AVAsset assetWithURL:videourl];
}


- (void) applyOverlayToVideo:(AVMutableVideoComposition *)composition size:(CGSize)size{

    CALayer *overlayLayer = [CALayer layer];
    
    // get the uiimage from the view
    UIImage *overlayImage = [self uiImageOfTheUIView];
    [overlayLayer setContents:(id)[overlayImage CGImage]];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    // create a parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    //call AVVideoCompositionCoreAnimationTool to add the final composition with the layers
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (UIImage *) uiImageOfTheUIView{
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}


- (void) saveTheTaggedVideo{

    // exit there is no video file loaded and send the notification to cancel the activity indicator
    if (!self.mediaAsset) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DIALOG_ERROR_TITLE message:LOAD_VIDEO_ERROR_MESSAGE
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_EXPORT_NOTIFICATION object:nil];
        return;
    }
    
    // AVMutableComposition object will hold AVMutableCompositionTrack instances.
    AVMutableComposition *mutableComposition = [[AVMutableComposition alloc] init];
    
    // video track
    AVMutableCompositionTrack *videocompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videocompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.mediaAsset.duration)
                        ofTrack:[[self.mediaAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    //  create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *compositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    compositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.mediaAsset.duration);
    
    // create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videocompositionTrack];
    AVAssetTrack *videoAssetTrack = [[self.mediaAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoOrientation  = UIImageOrientationUp;
    BOOL isvideoPortrait  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoOrientation = UIImageOrientationRight;
        isvideoPortrait = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoOrientation =  UIImageOrientationLeft;
        isvideoPortrait = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoOrientation =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoOrientation = UIImageOrientationDown;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:self.mediaAsset.duration];
   
    // add instructions
    compositionInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction, nil];
    AVMutableVideoComposition *finalCompositionInst = [AVMutableVideoComposition videoComposition];
    CGSize naturalVideoSize;
    if(isvideoPortrait){
        naturalVideoSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalVideoSize = videoAssetTrack.naturalSize;
    }
    float finalVideoWidth = naturalVideoSize.width;
    float finalVideoHeight = naturalVideoSize.height;
    finalCompositionInst.renderSize = CGSizeMake(finalVideoWidth, finalVideoHeight);
    finalCompositionInst.instructions = [NSArray arrayWithObject:compositionInstruction];
    finalCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    [self applyOverlayToVideo:finalCompositionInst size:naturalVideoSize];
    
    [self exportTheVideo:mutableComposition withVideoComposition:finalCompositionInst];
}

-(void) exportTheVideo:(AVMutableComposition *) mutableComposition withVideoComposition:
    (AVMutableVideoComposition *) finalCompositionInst{
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [filePaths objectAtIndex:0];
    NSString *randomPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"TagVideo-%d.mov",arc4random() % 1000]];
    NSURL *videoOutputURL = [NSURL fileURLWithPath:randomPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = finalCompositionInst;
    
    // export the video
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusCompleted:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self saveTheVideoAfterExporting:exporter];
                });
                break;
            }
            case AVAssetExportSessionStatusFailed:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_EXPORT_NOTIFICATION object:nil];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DIALOG_ERROR_TITLE message:VIDEO_SAVED_ERROR_MESSAGE                                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    
                });
                break;
            }
            case AVAssetExportSessionStatusCancelled:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_EXPORT_NOTIFICATION object:nil];
                });
                break;
            }
        }
    }];

}

-(void) saveTheVideoAfterExporting:(AVAssetExportSession*)session {
    NSURL *outputURL = session.outputURL;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_EXPORT_NOTIFICATION object:nil];
                if (error) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DIALOG_ERROR_TITLE message:VIDEO_SAVED_ERROR_MESSAGE
                                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                }else{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:VIDEO_SAVED_SUCCESS_TITLE
                                                                        message:VIDEO_SAVED_SUCCESS_MESSAGE
                                                                       delegate:self
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil, nil];
                    [alertView show];
                }
            });
        }];
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
