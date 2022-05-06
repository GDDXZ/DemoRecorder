//
//  Recorder.m
//  Recorder
//
//  Created by haozhou on 2021/5/6.
//

#import "Recorder.h"
#import "AEAudioController.h"
#import "AEUtilities.h"
#import "AEBlockAudioReceiver.h"
#import "AudioUtils.h"
#import "AEPlaythroughChannel.h"
#include <stdio.h>

@interface Recorder ()

@property (nonatomic,strong)   AEAudioController     *audioCtl;
@property (nonatomic,strong)   AEPlaythroughChannel  *input;
@property (nonatomic,strong)   AEBlockAudioReceiver  *voiceReceiver;
@property (nonatomic,assign)   AEChannelGroupRef outGroup;
@property (nonatomic,assign)   FILE *pcm;

@end

@implementation Recorder

//录音时人声线路 实时录制音频
- (void)registAudioUnit {
    UInt32 ops = AEAudioControllerOptionEnableOutput|AEAudioControllerOptionEnableInput|AEAudioControllerOptionEnableBluetoothInput;
    self.audioCtl = [[AEAudioController alloc] initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleaved16BitStereo options:(AEAudioControllerOptions)ops];
    self.audioCtl.useMeasurementMode = YES;
    self.audioCtl.preferredBufferDuration = 0.01;
    
    self.input = [[AEPlaythroughChannel alloc] init];
    
    NSString *tmpPath = NSTemporaryDirectory();
    NSString *outPath = [tmpPath stringByAppendingPathComponent:@"record.pcm"];
    NSLog(@"outPath: %@", outPath);
    self.pcm = fopen(outPath.UTF8String, "wb");
    
    self.voiceReceiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        
        short *sbuf = (short *)audio->mBuffers[0].mData;
        NSLog(@"接收到音频数据, frames = %d", frames);
        fwrite((char *)sbuf, 1, frames*sizeof(short), self.pcm);
    }];
    
    [self.audioCtl addInputReceiver:self.voiceReceiver];
    
}

- (void)unRegistAudioUnit {
    [self.audioCtl removeInputReceiver:self.voiceReceiver];
    
    self.voiceReceiver = nil;
    self.audioCtl = nil;
}

- (void)startEngine {
    if (self.audioCtl) { return; }

    //保证蓝牙连接
    setPlayMode();
    setUseMeasurement(YES);
    
    [self registAudioUnit];

    [self.audioCtl start:NULL];
}

- (void)stopEngine {
    if (!self.audioCtl) { return; }
    
    [self.audioCtl stop];
    [self unRegistAudioUnit];
    
    setPlayMode();
    setUseMeasurement(NO);
    
    if (self.pcm != NULL) {
        fclose(self.pcm);
    }
}

@end
