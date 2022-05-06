//
//  Recorder.h
//  Recorder
//
//  Created by haozhou on 2022/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Recorder : NSObject

- (void)startEngine;

- (void)stopEngine;

@property (nonatomic, copy) void (^callback)(void);

@end

NS_ASSUME_NONNULL_END
