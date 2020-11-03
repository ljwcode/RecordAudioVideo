//
//  RecordAudioViewController.m
//  RecordVideo
//
//  Created by 1 on 2020/11/3.
//

#import "RecordAudioViewController.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordAudioViewController ()

@property(nonatomic,strong)AVAudioRecorder *audioRecorder;

@property(nonatomic,strong)AVAudioPlayer *audioPlayer;

@property(nonatomic,strong)NSURL *audioURL;

@end

@implementation RecordAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *audioStartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [audioStartBtn setTitle:@"开始" forState:UIControlStateNormal];
    [audioStartBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    audioStartBtn.backgroundColor = [UIColor greenColor];
    [audioStartBtn addTarget:self action:@selector(startHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:audioStartBtn];
    
    [audioStartBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.mas_equalTo(self.view);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(30);
    }];
    
    UIButton *audioEndBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [audioEndBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [audioEndBtn setTitle:@"结束" forState:UIControlStateNormal];
    audioEndBtn.backgroundColor = [UIColor greenColor];
    [audioEndBtn addTarget:self action:@selector(endHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:audioEndBtn];
    [audioEndBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(audioStartBtn.mas_bottom).offset(20);
        make.width.height.mas_equalTo(audioStartBtn);
    }];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    playBtn.backgroundColor = [UIColor greenColor];
    [playBtn addTarget:self action:@selector(playHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    
    [playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(audioEndBtn.mas_bottom).offset(20);
        make.width.height.mas_equalTo(audioEndBtn);
    }];
    // Do any additional setup after loading the view.
}

-(void)startHandle:(id)sender{
    
    NSLog(@"startRecording");;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    
    NSError *error = nil;
    
    self.audioRecorder = [[ AVAudioRecorder alloc] initWithURL:self.audioURL settings:[self audioRecordingSettings] error:&error];
    self.audioRecorder.meteringEnabled = YES;
    if ([self.audioRecorder prepareToRecord] == YES){
        self.audioRecorder.meteringEnabled = YES;
        [self.audioRecorder record];
    }else {
        NSLog(@"初始化录音失败");
    }
}

//音频录制设置
- (NSDictionary *)audioRecordingSettings{

   NSDictionary *result = nil;

   NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
   //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
   //    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
   [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
   //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
   [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
   //录音通道数  1 或 2
   [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
   //线性采样位数  8、16、24、32
   [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
   //录音的质量
   [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];

   result = [NSDictionary dictionaryWithDictionary:recordSetting];
   return result;
}

-(void)endHandle:(id)sender{
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

-(void)playHandle:(id)sender{
    NSLog(@"playRecording");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.audioURL error:&error];
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer play];
    NSLog(@"playing");
}

-(NSURL *)audioURL{
    if(!_audioURL){
        //设置文件储存路径
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                                NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *soundFilePath = [docsDir
                                   stringByAppendingPathComponent:@"recordTest.caf"];
        
        NSURL *url = [NSURL fileURLWithPath:soundFilePath];
        _audioURL = url;
    }
    return _audioURL;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
