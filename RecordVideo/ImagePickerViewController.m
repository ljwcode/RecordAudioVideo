//
//  ImagePickerViewController.m
//  RecordVideo
//
//  Created by 1 on 2020/11/3.
//

#import "ImagePickerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHAssetChangeRequest.h>
#import <AVFoundation/AVFoundation.h>

@interface ImagePickerViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
    
@end

@implementation ImagePickerViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if (![self isVideoRecordingAvailable]) {
        return;
    }
    self.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.mediaTypes = @[(NSString *)kUTTypeMovie];
    self.delegate = self;
    
    //隐藏系统自带UI
    self.showsCameraControls = YES;
    //设置摄像头
    [self switchCameraIsFront:NO];
    //设置视频画质类别
    self.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    //设置散光灯类型
    self.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
    //设置录制的最大时长
    self.videoMaximumDuration = 20;
}
#pragma mark 自定义方法

- (void)startRecorder
{
    [self startVideoCapture];
}


- (void)stopRecoder
{
    [self stopVideoCapture];
}

#pragma mark - Private methods
- (BOOL)isVideoRecordingAvailable
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]){
            return YES;
        }
    }
    return NO;
}

//切换相机
- (void)switchCameraIsFront:(BOOL)front
{
    if (front) {
        if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
            [self setCameraDevice:UIImagePickerControllerCameraDeviceFront];
        }
    } else {
        if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]){
            [self setCameraDevice:UIImagePickerControllerCameraDeviceRear];
            
        }
    }
}


//隐藏系统自带的UI，可以自定义UI
- (void)configureCustomUIOnImagePicker{
    self.showsCameraControls = YES;
    UIView *cameraOverlay = [[UIView alloc] init];
    self.cameraOverlayView = cameraOverlay;
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL *VideoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:VideoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"已将视频保存至相册");
        } else {
            NSLog(@"未能保存视频到相册");
        }
    }];
    [self addWaterPicWithVideoPath:VideoURL];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark ---- video edit logo


/**
 视频添加水印并保存到相册

 @param path 视频本地路径
 */
- (void)addWaterPicWithVideoPath:(NSURL*)path{
    //1 创建AVAsset实例
    AVURLAsset*videoAsset = [AVURLAsset assetWithURL:path];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    
    //3 视频通道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject]
                         atTime:kCMTimeZero error:nil];
    
    
    //2 音频通道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]
                         atTime:kCMTimeZero error:nil];
    
    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
    
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    //AVMutableVideoComposition：管理所有视频轨道，水印添加就在这上面
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize naturalSize = videoAssetTrack.naturalSize;
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    
    //    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo-%d.mp4",arc4random() % 1000]];
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    // 5 - 视频文件输出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if( exporter.status == AVAssetExportSessionStatusCompleted ){
                UISaveVideoAtPathToSavedPhotosAlbum(myPathDocs, nil, nil, nil);
            }else if( exporter.status == AVAssetExportSessionStatusFailed ){
                NSLog(@"failed");
            }
        });
    }];
}


/**
 设置水印及其对应视频的位置

 @param composition 视频的结构
 @param size 视频的尺寸
 */
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
//     文字
//    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    //    [subtitle1Text setFont:@"Helvetica-Bold"];
//    [subtitle1Text setFontSize:36];
//    [subtitle1Text setFrame:CGRectMake(10, size.height-10-100, size.width, 100)];
//    [subtitle1Text setString:@"水印"];
    //    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
//    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    //图片
    CALayer *picLayer = [CALayer layer];
    picLayer.contents = (id)[UIImage imageNamed:@"applelogo.png"].CGImage;
    picLayer.frame = CGRectMake(size.width-15-87, 15, 87, 26);
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:picLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}


@end
