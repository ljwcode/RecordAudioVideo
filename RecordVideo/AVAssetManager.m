//
//  AVAssetManager.m
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import "AVAssetManager.h"
#import "XCFileManager.h"
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#define kScreenWith [UIScreen mainScreen].bounds.size.width

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface AVAssetManager()

@property(nonatomic,strong)dispatch_queue_t writeQueue;

@property(nonatomic,strong)NSURL *videoURL;

@property(nonatomic,strong)AVAssetWriter *assetWriter;

@property(nonatomic,strong)AVAssetWriterInput *assetWriterVideoInput;

@property(nonatomic,strong)AVAssetWriterInput *assetWriteAudioInput;

@property(nonatomic,strong)NSDictionary *videoCompressionConfigure; //视频压缩设置

@property(nonatomic,strong)NSDictionary *audioCompressionConfigure; //音频压缩设置


@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, assign) RecordVideoViewType viewType;
@property (nonatomic, assign) CGSize outputSize;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;


@end

static AVAssetManager *instance = nil;
@implementation AVAssetManager

+(AVAssetManager *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AVAssetManager alloc]init];
    });
    return instance;
}

-(void)setRecordViewWithType:(RecordVideoViewType)type{
    switch(type){
            
        case videoType1x1:
            self.outputSize = CGSizeMake(kScreenWith,kScreenWith);
            break;
        case videoType4x3:
            self.outputSize = CGSizeMake(kScreenWith, kScreenHeight*4/3);
            break;
        case videoTypeFullScreen:
            self.outputSize = CGSizeMake(kScreenWith, kScreenHeight);
            break;
        default:
            self.outputSize = CGSizeMake(kScreenWith, kScreenWith);
    }
    self.writeQueue = dispatch_queue_create("com.captureQueue", DISPATCH_QUEUE_SERIAL);
    self.recordTime = 0;
}

-(instancetype)initWithURL:(NSURL *)url videoType:(RecordVideoViewType)type{
    if(self = [super init]){
        self.videoURL = url;
        self.viewType = type;
        [self setRecordViewWithType:type];
    }
    return self;
}

-(void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType{
    if(sampleBuffer == NULL){
        return;
    }
    @synchronized (self) {
        if(self.status < RecordStatusRecording){
            return;
        }
    }
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized (self) {
                if(self.status < RecordStatusRecording){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if(!self.canWrite && mediaType == AVMediaTypeVideo){
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;

            }
            if(!self.timer){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
                });
            }
            
            //写入视频数据
            if(mediaType == AVMediaTypeVideo){
                if(self.assetWriterVideoInput.readyForMoreMediaData){
                    BOOL succ = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if(!succ){
                        [self stopWrite];
                        [self destroyWrit];
                    }
                }
            }
            
            if(mediaType == AVMediaTypeAudio){
                if(self.assetWriteAudioInput.readyForMoreMediaData){
                    BOOL succ = [self.assetWriteAudioInput appendSampleBuffer:sampleBuffer];
                    if(!succ){
                        [self stopWrite];
                        [self destroyWrit];
                    }
                }
            }
            CFRelease(sampleBuffer);
        }
    });
}

-(void)updateProgress{
    if(self.recordTime >= 8){
        [self stopWrite];
        if(self.delegate && [self.delegate respondsToSelector:@selector(RecordVideoFinishWrite)]){
            [self.delegate RecordVideoFinishWrite];
        }
        return;
    }
    self.recordTime += 0.05;
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateProgrss:)]){
        [self.delegate updateProgrss:self.recordTime/8];
    }
}

-(void)setUpWrite{
    self.assetWriter = [[AVAssetWriter alloc]initWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:nil];
    
    NSInteger videoPixelSize = self.outputSize.width * self.outputSize.height; //视频大小
    CGFloat videoPixelByte = 6.; //像素比特
    NSInteger byteSecond = videoPixelSize * videoPixelByte;
    
    NSDictionary *compressionProperties = @{AVVideoAverageBitRateKey : @(byteSecond),
                                            AVVideoMaxKeyFrameIntervalKey : @(30),
                                            AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
                                            AVVideoExpectedSourceFrameRateKey : @(30)
    };//设置码率和帧率
    
    self.videoCompressionConfigure  = @{AVVideoCodecKey : AVVideoCodecTypeH264,
                                        AVVideoCompressionPropertiesKey : compressionProperties,
                                        AVVideoWidthKey : @(self.outputSize.width),
                                        AVVideoHeightKey : @(self.outputSize.height),
                                        AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
    };//设置视频属性
    
    self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionConfigure];
    self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    self.audioCompressionConfigure = @{AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050)
    };
    self.assetWriteAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionConfigure];
    self.assetWriteAudioInput.expectsMediaDataInRealTime = YES;
    
    if([self.assetWriter canAddInput:self.assetWriterVideoInput]){
        [self.assetWriter addInput:self.assetWriterVideoInput];
    }else{
        NSLog(@"asset writer video input fail");
    }
    
    if([self.assetWriter canAddInput:self.assetWriteAudioInput]){
        [self.assetWriter addInput:self.assetWriteAudioInput];
    }else{
        NSLog(@"asset writer audio input fail");
    }
    self.status = RecordStatusRecording;
}

-(void)startWrite{
    self.status = RecordStatusRecording;
    if(!self.assetWriter){
        [self setUpWrite];
    }
}

-(void)stopWrite{
    self.status = RecordStatusFinish;
    [self.timer invalidate];
    self.timer = nil;
    if(self.assetWriter && self.assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [self.assetWriter finishWritingWithCompletionHandler:^{
                PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
                [photoLibrary performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self->_videoURL];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        NSLog(@"已将视频保存至相册");
                    } else {
                        NSLog(@"未能保存视频到相册");
                    }
                }];
            }];
            
        });
    }
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



-(void)destroyWrit{
    self.assetWriter = nil;
    self.recordTime = 0;
    [self.timer invalidate];
    self.timer = nil;
    self.assetWriteAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.videoURL = nil;
}

//检查写入地址
- (BOOL)checkPathUrl:(NSURL *)url{
    if (!url) {
        return NO;
    }
    if ([XCFileManager isExistsAtPath:[url path]]) {
        return [XCFileManager removeItemAtPath:[url path]];
    }
    return YES;
}

@end
