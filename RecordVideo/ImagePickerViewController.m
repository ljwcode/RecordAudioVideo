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
#import "AVAssetManager.h"

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
    [[AVAssetManager shareInstance] addWaterPicWithVideoPath:VideoURL];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
