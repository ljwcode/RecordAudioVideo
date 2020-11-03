//
//  cameraView.m
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import "cameraView.h"
#import "FMRecordProgressView.h"
#import "UIColor+Hex.h"

#define kScreenWith [UIScreen mainScreen].bounds.size.width

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface cameraView()<CameraStatusModelDeleagte>

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIView *timeView;
@property (nonatomic, strong) UILabel *timelabel;
@property (nonatomic, strong) UIButton *turnCamera;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) FMRecordProgressView *progressView;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, assign) CGFloat recordTime;

@property (nonatomic, strong, readwrite) CameraStatusModel *fmodel;

@end

@implementation cameraView

-(instancetype)initWithFMVideoViewType:(RecordVideoViewType)type{
    if(self = [super initWithFrame:[UIScreen mainScreen].bounds]){
        [self BuildUIWithType:type];
    }
    return self;
}

- (void)BuildUIWithType:(RecordVideoViewType)type
{
    
    self.fmodel = [[CameraStatusModel alloc] initWithFMVideoViewType:type superView:self];
    self.fmodel.delegate = self;
    
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [UIColor colorWithRGB:0x000000 alpha:0.5];
    self.topView.frame = CGRectMake(0, 0, kScreenHeight, 44);
    [self addSubview:self.topView];
    
    self.timeView = [[UIView alloc] init];
    self.timeView.hidden = YES;
    self.timeView.frame = CGRectMake((kScreenWith - 100)/2, 16, 100, 34);
    self.timeView.backgroundColor = [UIColor colorWithRGB:0x242424 alpha:0.7];
    self.timeView.layer.cornerRadius = 4;
    self.timeView.layer.masksToBounds = YES;
    [self addSubview:self.timeView];
    
    
    UIView *redPoint = [[UIView alloc] init];
    redPoint.frame = CGRectMake(0, 0, 6, 6);
    redPoint.layer.cornerRadius = 3;
    redPoint.layer.masksToBounds = YES;
    redPoint.center = CGPointMake(25, 17);
    redPoint.backgroundColor = [UIColor redColor];
    [self.timeView addSubview:redPoint];
    
    self.timelabel =[[UILabel alloc] init];
    self.timelabel.font = [UIFont systemFontOfSize:13];
    self.timelabel.textColor = [UIColor whiteColor];
    self.timelabel.frame = CGRectMake(40, 8, 40, 28);
    [self.timeView addSubview:self.timelabel];
    
    
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.frame = CGRectMake(15, 14, 16, 16);
    [self.cancelBtn setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.cancelBtn];
    
    
    self.turnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    self.turnCamera.frame = CGRectMake(kScreenWith - 60 - 28, 11, 28, 22);
    [self.turnCamera setImage:[UIImage imageNamed:@"listing_camera_lens"] forState:UIControlStateNormal];
    [self.turnCamera addTarget:self action:@selector(turnCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.turnCamera sizeToFit];
    [self.topView addSubview:self.turnCamera];
    
    
    self.flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashBtn.frame = CGRectMake(kScreenWith - 22 - 15, 11, 22, 22);
    [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
    [self.flashBtn addTarget:self action:@selector(flashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.flashBtn sizeToFit];
    [self.topView addSubview:self.flashBtn];
    
    
    self.progressView = [[FMRecordProgressView alloc] initWithFrame:CGRectMake((kScreenWith - 62)/2, kScreenHeight - 32 - 62, 62, 62)];
    self.progressView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.progressView];
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.recordBtn addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.recordBtn setTitle:@"录制" forState:UIControlStateNormal];
    [self.recordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.recordBtn.frame = CGRectMake(5, 5, 52, 52);
    self.recordBtn.backgroundColor = [UIColor redColor];
    self.recordBtn.layer.cornerRadius = 26;
    self.recordBtn.layer.masksToBounds = YES;
    [self.progressView addSubview:self.recordBtn];
    [self.progressView resetProgress];
}

- (void)updateViewWithRecording{
    self.timeView.hidden = NO;
    self.topView.hidden = YES;
    [self changeToRecordStyle];
}

- (void)updateViewWithStop
{
    self.timeView.hidden = YES;
    self.topView.hidden = NO;
    [self changeToStopStyle];
}

- (void)changeToRecordStyle
{
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(28, 28);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 4;
        self.recordBtn.center = center;
    }];
}

- (void)changeToStopStyle
{
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.recordBtn.center;
        CGRect rect = self.recordBtn.frame;
        rect.size = CGSizeMake(52, 52);
        self.recordBtn.frame = rect;
        self.recordBtn.layer.cornerRadius = 26;
        self.recordBtn.center = center;
    }];
}
#pragma mark - action

- (void)dismissVC
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissVC)]) {
        [self.delegate dismissVC];
    }
}

- (void)turnCameraAction{
    [self.fmodel SwitchCamera];
}

- (void)flashAction
{
    [self.fmodel switchflash];
}

- (void)startRecord{
    if (self.fmodel.recordStatus == RecordStatusInit) {
        [self.fmodel startRecord];
    } else if (self.fmodel.recordStatus == RecordStatusRecording) {
        [self.fmodel stopRecord];
    } else {
        [self.fmodel reset];
    }
    
}


- (void)stopRecord
{
     [self.fmodel stopRecord];
}

- (void)reset
{
    [self.fmodel reset];
}

#pragma mark - CameraStatusModelDeleagte

- (void)updateFlashStatus:(flashStatus)state
{
    if (state == flashOpen) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_on"] forState:UIControlStateNormal];
    }
    if (state == flashClose) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
    }
    if (state == flashAuto) {
        [self.flashBtn setImage:[UIImage imageNamed:@"listing_flash_auto"] forState:UIControlStateNormal];
    }
}


- (void)updateRecoedStatus:(RecordStatus)recordState{
    if (recordState == RecordStatusInit) {
        [self updateViewWithStop];
        [self.progressView resetProgress];
    } else if (recordState == RecordStatusRecording) {
        [self updateViewWithRecording];
    } else  if (recordState == RecordStatusFinish) {
        [self updateViewWithStop];
        if (self.delegate && [self.delegate respondsToSelector:@selector(RecordFinishWithURL:)]) {
            [self.delegate RecordFinishWithURL:self.model.videoURL];
        }
    }
}

- (void)updateRecordProgress:(CGFloat)progress
{
    [self.progressView updateProgressWithValue:progress];
    self.timelabel.text = [self changeToVideotime:progress * 8];
    [self.timelabel sizeToFit];
}

- (NSString *)changeToVideotime:(CGFloat)videocurrent {
    
    return [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
