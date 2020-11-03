//
//  cameraView.h
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import <UIKit/UIKit.h>
#import "CameraStatusModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol cameraViewDelegate<NSObject>

-(void)dismissVC;

-(void)RecordFinishWithURL:(NSURL *)url;

@end

@interface cameraView : UIView

@property(nonatomic,assign)RecordVideoViewType viewType;

@property(nonatomic,strong)CameraStatusModel *model;

@property(nonatomic,weak)id<cameraViewDelegate>delegate;

- (instancetype)initWithFMVideoViewType:(RecordVideoViewType)type;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
