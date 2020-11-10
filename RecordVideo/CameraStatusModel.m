//
//  CameraStatusModel.m
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import "CameraStatusModel.h"
#import "XCFileManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define kScreenWith [UIScreen mainScreen].bounds.size.width

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface CameraStatusModel()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AssetManagerDelegate>

@property(nonatomic,strong)UIImageView *focusCursor;

@property(nonatomic,strong)UIView *superView;

@property(nonatomic,strong)AVCaptureSession *session;

@property(nonatomic,strong)AVCaptureDeviceInput *DeviceVideoInput;

@property(nonatomic,strong)AVCaptureDeviceInput *DeviceAudioInput;

@property(nonatomic,strong)AVCaptureVideoPreviewLayer *capturePreviewLayer;

@property(nonatomic,strong)AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic,strong)AVCaptureAudioDataOutput *audioDataOutput;

@property(nonatomic,strong)dispatch_queue_t captureQueue;

@property(nonatomic,strong)AVAssetManager *assetManager;

@property(nonatomic,strong,readwrite)NSURL *videoURL;

@property(nonatomic,readwrite)flashStatus status;

@property(nonatomic,readwrite)RecordVideoViewType viewType;

@end

@implementation CameraStatusModel

-(instancetype)initWithFMVideoViewType:(RecordVideoViewType)type superView:(UIView *)superView{
    if(self = [super init]){
        self.superView = superView;
        self.viewType = type;
        [self setUpWithType:type];
        [self addFocus];
    }
    return self;
}

-(void)setUpWithType:(RecordVideoViewType)type{
    [self setUpInit];
    ///2. 设置视频的输入输出
    [self setUpVideo];
    
    ///3. 设置音频的输入输出
    [self setUpAudio];
    
    ///4. 视频的预览层
    [self setUpPreviewLayerWithType:type];
    
    ///5. 开始采集画面
    [self.session startRunning];
    
    /// 6. 初始化writer， 用writer 把数据写入文件
    [self setUpWriter];
}

-(void)setUpInit{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self clearFile];
    self.recordStatus = RecordStatusInit;
}
//设置视频输入输出
-(void)setUpVideo{
    AVCaptureDevice *captureDevice = [self getCaptureDevicePosition:AVCaptureDevicePositionBack];
    
    NSError *error = nil;
    self.DeviceVideoInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    
    if([self.session canAddInput:self.DeviceVideoInput]){
        [self.session addInput:self.DeviceVideoInput];
    }
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    if([self.session canAddOutput:self.videoDataOutput]){
        [self.session addOutput:self.videoDataOutput];
    }
}

//设置音频输入输出
-(void)setUpAudio{
    AVCaptureDevice *captureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]firstObject];
    
    NSError *error = nil;
    self.DeviceAudioInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if([self.session canAddInput:self.DeviceAudioInput]){
        [self.session addInput:self.DeviceAudioInput];
    }
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc]init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    if([self.session canAddOutput:self.audioDataOutput]){
        [self.session addOutput:self.audioDataOutput];
    }
}

-(void)setUpPreviewLayerWithType:(RecordVideoViewType)type{
    CGRect rect = CGRectZero;
    switch(type){
            
        case videoType1x1:
            rect = CGRectMake(0, 0, kScreenWith, kScreenWith);
            break;
        case videoType4x3:
            rect = CGRectMake(0, 0, kScreenWith, kScreenWith*4/3);
            break;
        case videoTypeFullScreen:
            rect = CGRectMake(0, 0, kScreenWith, kScreenHeight);
            break;
        default:
            rect = CGRectMake(0, 0, kScreenWith, kScreenWith);
    }
    self.capturePreviewLayer.frame = rect;
    [self.superView.layer insertSublayer:self.capturePreviewLayer atIndex:0];
}

-(void)setUpWriter{
    self.videoURL = [[NSURL alloc] initFileURLWithPath:[self createVideoFilePath]];
    self.assetManager = [[AVAssetManager alloc]initWithURL:self.videoURL videoType:_viewType];
    self.assetManager.delegate = self;
}

//写入的视频路径
- (NSString *)createVideoFilePath
{
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}

-(NSString *)videoFolder{
    NSString *cacheDir = [XCFileManager cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:@"videoFolder"];
    if (![XCFileManager isExistsAtPath:direc]) {
        [XCFileManager createDirectoryAtPath:direc];
    }
    return direc;
}

-(void)clearFile{
    [XCFileManager removeItemAtPath:[self videoFolder]];
}

#pragma mark ------ lazy load


- (UIImageView *)focusCursor
{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [UIImage imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}

-(AVCaptureSession *)session{
    if(!_session){
        _session = [[AVCaptureSession alloc]init];
        if([_session canSetSessionPreset:AVCaptureSessionPresetHigh]){
            _session.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

-(dispatch_queue_t)captureQueue{
    if(!_captureQueue){
        _captureQueue = dispatch_queue_create("com.captureQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

-(AVCaptureVideoPreviewLayer *)capturePreviewLayer{
    if(!_capturePreviewLayer){
        _capturePreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
        _capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _capturePreviewLayer;
}

-(void)setRecordStatus:(RecordStatus)recordStatus{
    if(_recordStatus != recordStatus){
        _recordStatus = recordStatus;
        if(self.delegate && [self.delegate respondsToSelector:@selector(updateRecoedStatus:)]){
            [self.delegate updateRecoedStatus:_recordStatus];
        }
    }
}

#pragma mark 获取摄像头

-(AVCaptureDevice *)getCaptureDevicePosition:(AVCaptureDevicePosition)position{
    /*
     设备类型AVCaptureDeviceType    描述
     AVCaptureDeviceTypeBuiltInMicrophone    一个内置的麦克风
     AVCaptureDeviceTypeBuiltInWideAngleCamera    内置广角相机,这些装置适用于一般用途。
     AVCaptureDeviceTypeBuiltInTelephotoCamera    内置长焦相机，比广角相机的焦距长。这种类型只是将窄角设备与配备两种类型的摄像机的硬件上的宽角设备区分开来。要确定摄像机设备的实际焦距，可以检查AVCaptureDevice的format数组中的AVCaptureDeviceFormat对象。
     AVCaptureDeviceTypeBuiltInDualCamera    广角相机和长焦相机的组合，创建了一个拍照，录像的AVCaptureDevice。具有和深度捕捉，增强变焦和双图像捕捉功能。
     AVCaptureDeviceTypeBuiltInTrueDepthCamera    相机和其他传感器的组合，创建了一个捕捉设备，能够拍照、视频和深度捕捉。
     AVCaptureDeviceTypeBuiltInDuoCamera    iOS 10.2 之后添加自动变焦功能，该值功能被AVCaptureDeviceTypeBuiltInDualCamera替代
     */
    NSArray* devices = [AVCaptureDeviceDiscoverySession
    discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                        mediaType:AVMediaTypeVideo position:position].devices;
    for(AVCaptureDevice *camera in devices){
        if([camera position] == position){
            return camera;
        }
    }
    return nil;
}

//添加视频聚焦
- (void)addFocus
{
    [self.superView addSubview:self.focusCursor];
    UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.superView addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.superView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.capturePreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}


-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}
//设置聚焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [self.DeviceVideoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}


//切换摄像头
-(void)SwitchCamera{
    [self.session stopRunning];
    
    AVCaptureDevicePosition position = self.DeviceVideoInput.device.position;
    if(position == AVCaptureDevicePositionBack){
        position = AVCaptureDevicePositionFront;
    }else{
        position = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *captureDevice = [self getCaptureDevicePosition:position];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    [self.session removeInput:self.DeviceVideoInput];
    [self.session beginConfiguration];
    [self.session addInput:deviceInput];
    [self.session commitConfiguration];
    self.DeviceVideoInput = deviceInput;
    [self.session startRunning];

}

//闪光灯切换
-(void)switchflash{
    if(self.status == flashClose){
        if([self.DeviceVideoInput.device hasTorch]){
            [self.DeviceVideoInput.device lockForConfiguration:nil];
            [self.DeviceVideoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.DeviceVideoInput.device unlockForConfiguration];
            self.status = flashOpen;
        }
    }else if(self.status == flashAuto){
        if([self.DeviceVideoInput.device hasTorch]){
            [self.DeviceVideoInput.device lockForConfiguration:nil];
            [self.DeviceVideoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.DeviceVideoInput.device unlockForConfiguration];
            self.status = flashClose;
        }
    }else if(self.status == flashOpen){
        if([self.DeviceVideoInput.device hasTorch]){
            [self.DeviceVideoInput.device lockForConfiguration:nil];
            [self.DeviceVideoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.DeviceVideoInput.device unlockForConfiguration];
            self.status = flashAuto;
        }
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateFlashStatus:)]){
        [self.delegate updateFlashStatus:_status];
    }
}

#pragma mark AVCaptureAudioDataOutputSampleBufferDelegate && AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    @autoreleasepool {
        
        //视频
        if (connection == [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo]) {
            
            if (!self.assetManager.outPutVideoFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.assetManager.outPutVideoFormatDescription = formatDescription;
                }
            } else {
                @synchronized(self) {
                    if (self.assetManager.status == RecordStatusRecording) {
                        [self.assetManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                    }
                    
                }
            }
            
            
        }
        
        //音频
        if (connection == [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio]) {
            if (!self.assetManager.outPutAudioFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.assetManager.outPutAudioFormatDescription = formatDescription;
                }
            }
            @synchronized(self) {
                
                if (self.assetManager.status == RecordStatusRecording) {
                    [self.assetManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
                
            }
            
        }
    }
    
}

-(void)startRecord{
    if(self.recordStatus == RecordStatusInit){
        [self.assetManager startWrite];
        self.recordStatus = RecordStatusRecording;
    }
}

-(void)stopRecord{
    self.recordStatus = RecordStatusFinish;
    [self.session stopRunning];
    [self.assetManager stopWrite];
}

-(void)reset{
    [self.session startRunning];
    self.recordStatus = RecordStatusInit;
    [self setUpWriter];
}

#pragma mark ----- assetManagerDelegate

-(void)RecordVideoFinishWrite{
    [self.session stopRunning];
    self.recordStatus = RecordStatusFinish;
}

-(void)updateProgrss:(CGFloat)progress{
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateRecordProgress:)]){
        [self.delegate updateRecordProgress:progress];
    }
}

#pragma mark ----- 事件处理

-(void)enterForeground{
    [self reset];
}

-(void)enterBackGround{
    self.videoURL = nil;
    [self.assetManager destroyWrit];
    [self.session stopRunning];
}

-(void)destory{
    [self.session stopRunning];
    self.captureQueue = nil;
    self.session = nil;
    self.videoURL = nil;
    self.DeviceVideoInput = nil;
    self.videoDataOutput = nil;
    self.audioDataOutput = nil;
    self.DeviceAudioInput = nil;
    [self.assetManager destroyWrit];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)dealloc{
    [self destory];
}

@end
