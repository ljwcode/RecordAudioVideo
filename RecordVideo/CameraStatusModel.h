//
//  CameraStatusModel.h
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AVAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, flashStatus){
    flashClose = 0,
    flashOpen  = 1,
    flashAuto  = 2
};

@protocol CameraStatusModelDeleagte<NSObject>

-(void)updateFlashStatus:(flashStatus)status;

-(void)updateRecordProgress:(CGFloat)progress;

-(void)updateRecoedStatus:(RecordStatus)status;

@end

@interface CameraStatusModel : NSObject

@property(nonatomic,strong,readonly)NSURL *videoURL;

@property(nonatomic,weak)id<CameraStatusModelDeleagte>delegate;

@property(nonatomic,readwrite)RecordStatus recordStatus;

- (instancetype)initWithFMVideoViewType:(RecordVideoViewType )type superView:(UIView *)superView;

- (void)SwitchCamera;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
