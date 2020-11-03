//
//  RecordViewController.m
//  RecordVideo
//
//  Created by 1 on 2020/11/2.
//

#import "RecordViewController.h"
#import "cameraView.h"

@interface RecordViewController ()<cameraViewDelegate>

@property(nonatomic,strong)cameraView *CView;

@end

@implementation RecordViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(self.CView.model.recordStatus == RecordStatusFinish){
        [self.CView.model reset];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    _CView = [[cameraView alloc]initWithFMVideoViewType:videoType1x1];
    _CView.delegate = self;
    [self.view addSubview:self.CView];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Do any additional setup after loading the view.
}

-(void)dismissVC{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)RecordFinishWithURL:(NSURL *)url{
    
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
