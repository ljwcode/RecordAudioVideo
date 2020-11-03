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

@implementation AVAssetManager

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
//                ALAssetsLibrary *alib = [[ALAssetsLibrary alloc]init];
//                [alib writeVideoAtPathToSavedPhotosAlbum:self.videoURL completionBlock:nil];
                //#import <Photos/Photos.h>
                PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
                [photoLibrary performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self->_videoURL];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        NSLog(@"已将视频保存至相册1");
                    } else {
                        NSLog(@"未能保存视频到相册1");
                    }
                }];
            }];
        });
    }
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
