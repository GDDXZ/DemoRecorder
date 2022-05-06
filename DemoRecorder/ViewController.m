//
//  ViewController.m
//  Recorder
//
//  Created by haozhou on 2022/5/6.
//

#import "ViewController.h"
#import "Recorder.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *indicator;
@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) Recorder *recorder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _recorder = Recorder.new;
    __weak typeof(self) self_weak_ = self;
    _recorder.callback = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self_weak_.view];
            hud.removeFromSuperViewOnHide = YES;
            hud.mode = MBProgressHUDModeText;
            [self_weak_.view addSubview:hud];
            hud.userInteractionEnabled = NO;
        });
        
    };
    
    _indicator.hidden = YES;
    
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            NSLog(@"录音权限未开启");
        }
    }];
}

- (IBAction)start:(UIButton *)sender {
    // 开始录音
    if (self.isRecording) {
        return;
    }
    self.isRecording = YES;
    self.indicator.hidden = NO;
    [self.recorder startEngine];
}

- (IBAction)stop:(UIButton *)sender {
    // 停止录音
    if (!self.isRecording) {
        return;
    }
    self.isRecording = NO;
    self.indicator.hidden = YES;
    [self.recorder stopEngine];
}


@end
