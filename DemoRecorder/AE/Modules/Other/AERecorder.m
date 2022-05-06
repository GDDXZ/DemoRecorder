//
//  AERecorder.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 23/04/2012.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "AERecorder.h"
#import "AEMixerBuffer.h"
#import "AEAudioFileWriter.h"

#define kProcessChunkSize 8192

NSString * AERecorderDidEncounterErrorNotification = @"AERecorderDidEncounterErrorNotification";
NSString * kAERecorderErrorKey = @"error";

@interface AERecorder () {
    volatile BOOL _recording;
}
@property (nonatomic, strong) AEAudioFileWriter *writer;

@property (nonatomic, assign) BOOL fristWrite;

@end

@implementation AERecorder
@synthesize  writer = _writer, currentTime = _currentTime;
@dynamic path;

+ (BOOL)AACEncodingAvailable {
    return [AEAudioFileWriter AACEncodingAvailable];
}

- (id)initWithAudioController:(AEAudioController*)audioController {
    if ( !(self = [super init]) ) return nil;
    self.writer = [[AEAudioFileWriter alloc] initWithAudioDescription:audioController.audioDescription];
    return self;
}

-(void)dealloc {
    NSLog(@"AERecorder 退出");
}


-(BOOL)beginRecordingToFileAtPath:(NSString *)path fileType:(AudioFileTypeID)fileType error:(NSError **)error {
    return [self beginRecordingToFileAtPath:path fileType:fileType bitDepth:16 channels:0 error:error];
}

- (BOOL)beginRecordingToFileAtPath:(NSString*)path fileType:(AudioFileTypeID)fileType bitDepth:(UInt32)bits error:(NSError**)error {
    return [self beginRecordingToFileAtPath:path fileType:fileType bitDepth:16 channels:0 error:error];
}

- (BOOL)beginRecordingToFileAtPath:(NSString*)path fileType:(AudioFileTypeID)fileType bitDepth:(UInt32)bits channels:(UInt32)channels error:(NSError**)error
{
    BOOL result = [self prepareRecordingToFileAtPath:path fileType:fileType bitDepth:bits channels:channels error:error];
    _recording = YES;
    return result;
}

- (BOOL)prepareRecordingToFileAtPath:(NSString*)path fileType:(AudioFileTypeID)fileType error:(NSError**)error {
    return [self prepareRecordingToFileAtPath:path fileType:fileType bitDepth:16 channels:0 error:error];
}

- (BOOL)prepareRecordingToFileAtPath:(NSString*)path fileType:(AudioFileTypeID)fileType bitDepth:(UInt32)bits error:(NSError**)error {
    return [self prepareRecordingToFileAtPath:path fileType:fileType bitDepth:16 channels:0 error:error];
}

- (BOOL)prepareRecordingToFileAtPath:(NSString*)path fileType:(AudioFileTypeID)fileType bitDepth:(UInt32)bits channels:(UInt32)channels error:(NSError**)error
{
    _currentTime = 0.0;
    _fristWrite = YES;
    BOOL result = [_writer beginWritingToFileAtPath:path fileType:fileType bitDepth:bits channels:channels error:error];
    
    if ( result ) {
        // Initialize async writing
        AECheckOSStatus(AEAudioFileWriterAddAudio(_writer, NULL, 0), "AEAudioFileWriterAddAudio");
    }
    
    return result;
}


-(void)startRecording {
    _recording = YES;
}

-(void)stopRecording {
    _recording = NO;
}

- (void)finishRecording {
    _recording = NO;
    [_writer finishWriting];
}

-(NSString *)path {
    return _writer.path;
}

-(double)currentTime
{
    if (_currentTime < _startTime) {
        return 0;
    }
    return _currentTime - _startTime;
}

struct reportError_t { void *THIS; OSStatus result; };
static void reportError(void *userInfo, int length) {
    struct reportError_t *arg = userInfo;
    [((__bridge AERecorder*)arg->THIS) finishRecording];
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain 
                                         code:arg->result
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Error while saving audio: Code %d", @""), arg->result]}];
    [[NSNotificationCenter defaultCenter] postNotificationName:AERecorderDidEncounterErrorNotification
                                                        object:(__bridge id)arg->THIS
                                                      userInfo:@{kAERecorderErrorKey: error}];
}

static void audioCallback(__unsafe_unretained AERecorder *THIS,
                          __unsafe_unretained AEAudioController *audioController,
                          void                     *source,
                          const AudioTimeStamp     *time,
                          UInt32                    frames,
                          AudioBufferList          *audio) {

    if ( !THIS->_recording || !audioController) return;

    if (THIS->_fristWrite) {
        THIS->_fristWrite = NO;
        return;
    }
    
    THIS->_currentTime +=  frames / audioController.audioDescription.mSampleRate;
    if (THIS->_currentTime < THIS->_startTime) {
        return;
    }
    if (THIS.duartion > 0 && (THIS->_currentTime - THIS->_startTime >= THIS.duartion)) {
        THIS->_recording = NO;
        if (THIS->_recordEnd) {
            THIS->_recordEnd();
        }
        return;
    }

//    NSLog(@"AERecorder currentTime %f", THIS->_currentTime - THIS->_startTime);
    
    OSStatus status = AEAudioFileWriterAddAudio(THIS->_writer, audio, frames);
    if ( status != noErr ) {
        THIS->_recording = NO;
        AEAudioControllerSendAsynchronousMessageToMainThread(audioController,
                                                             reportError,
                                                             &(struct reportError_t) { .THIS = (__bridge void*)THIS, .result = status },
                                                             sizeof(struct reportError_t));
    }
}

-(AEAudioReceiverCallback)receiverCallback {
    return audioCallback;
}

@end
