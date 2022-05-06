//
//  AudioUtils.m
//  McAudioEngine
//
//  Created by Hicks Jiang on 3/2/15.
//  Copyright (c) 2015 Hicks Jiang. All rights reserved.
//

#import "AudioUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <sys/sysctl.h>
#import <mach/mach.h>


BOOL isHeadphoneConnected(void)
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]
            || [[desc portType] isEqualToString:AVAudioSessionPortUSBAudio]) {
            return YES;
        }
        if (@available(iOS 10.0, *)) {
            if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
                return YES;
            }
        }
    }
    return NO;
}

BOOL isBluetoothConnected(void)
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if (@available(iOS 10.0, *)) {
            if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
                return YES;
            }
        }
    }
    return NO;
}

void setPlayMode(void)
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

void setProcessingMode(void)
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAudioProcessing error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

void setUseMeasurement(BOOL use)
{
    [[AVAudioSession sharedInstance] setMode:use ? AVAudioSessionModeMeasurement : AVAudioSessionModeDefault error:NULL];
}

NSDictionary* getRecordSettings(void) {
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                              [NSNumber numberWithFloat:44100],AVSampleRateKey,
                              [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                              [NSNumber numberWithInt:AVAudioQualityMax],AVEncoderAudioQualityKey,
                              nil];
    return settings;
}


