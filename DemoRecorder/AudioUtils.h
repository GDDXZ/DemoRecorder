//
//  AudioUtils.h
//  McAudioEngine
//
//  Created by Hicks Jiang on 3/2/15.
//  Copyright (c) 2015 Hicks Jiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    BOOL isHeadphoneConnected(void);
    BOOL isBluetoothConnected(void);

    void setPlayMode(void);
    void setProcessingMode(void);

    void setUseMeasurement(BOOL use);

    NSDictionary* getRecordSettings(void);

#ifdef __cplusplus
}
#endif
