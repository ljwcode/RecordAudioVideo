//
//  AVAssetManager.h
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,RecordStatus){
    RecordStatusInit = 0,
    RecordStatusPrepare = 1,
    RecordStatusRecording = 2,
    RecordStatusFinish = 3,
    RecordStatusFail = 4
};

typedef NS_ENUM(NSInteger,RecordVideoViewType){
    videoType1x1 = 0,
    videoType4x3 = 1,
    videoTypeFullScreen = 2
};

@protocol AssetManagerDelegate<NSObject>

-(void)RecordVideoFinishWrite;

-(void)updateProgrss:(CGFloat)progress;

@end

@interface AVAssetManager : NSObject

+(AVAssetManager *)shareInstance;

@property(nonatomic,retain)__attribute__ ((NSObject)) CMFormatDescriptionRef outPutVideoFormatDescription;

@property(nonatomic,retain)__attribute__ ((NSObject)) CMFormatDescriptionRef outPutAudioFormatDescription;

@property(nonatomic,assign)RecordStatus status;

@property(nonatomic,weak)id<AssetManagerDelegate> delegate;

-(instancetype)initWithURL:(NSURL *)url videoType:(RecordVideoViewType)type;

- (void)startWrite;

- (void)stopWrite;

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;

- (void)destroyWrit;

- (void)addWaterPicWithVideoPath:(NSURL*)path;

@end

NS_ASSUME_NONNULL_END
