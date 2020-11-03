//
//  ViewController.m
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "RecordViewController.h"
#import "ImagePickerViewController.h"
#import "RecordAudioViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"视频录制";
    
    UIButton *btn = [[UIButton alloc]init];
    [btn setTitle:@"视频" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(recordVidelHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view);
        make.width.height.mas_equalTo(50);
    }];
    
    UIButton *imgPickBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [imgPickBtn setTitle:@"相册" forState:UIControlStateNormal];
    [imgPickBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [imgPickBtn addTarget:self action:@selector(imgPichHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:imgPickBtn];
    
    [imgPickBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(btn.mas_bottom).offset(20);
        make.width.height.mas_equalTo(50);
    }];
    
    UIButton *audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [audioBtn setTitle:@"录音" forState:UIControlStateNormal];
    [audioBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [audioBtn addTarget:self action:@selector(recordAudioHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:audioBtn];
    
    [audioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(imgPickBtn.mas_bottom).offset(20);
        make.width.height.mas_equalTo(50);
    }];
    // Do any additional setup after loading the view.
}

-(void)imgPichHandle:(UIButton *)sender{
    ImagePickerViewController *imgPickVC = [[ImagePickerViewController alloc]init];
    [self presentViewController:imgPickVC animated:YES completion:nil];
}

-(void)recordVidelHandle:(UIButton *)sender{
    RecordViewController *recordVC = [[RecordViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:recordVC];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)recordAudioHandle:(UIButton *)sender{
    RecordAudioViewController *audioVC = [[RecordAudioViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:audioVC];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
