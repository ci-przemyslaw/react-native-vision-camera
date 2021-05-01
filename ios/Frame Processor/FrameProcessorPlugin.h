//
//  FrameProcessorPlugin.h
//  VisionCamera
//
//  Created by Marc Rousavy on 01.05.21.
//  Copyright © 2021 Facebook. All rights reserved.
//

#ifndef FrameProcessorPlugin_h
#define FrameProcessorPlugin_h

#import <Foundation/Foundation.h>
#import "FrameProcessorPluginRegistry.h"
#import <CoreMedia/CMSampleBuffer.h>

@protocol FrameProcessorPluginBase
+ (id) callback:(CMSampleBufferRef)buffer;
@end


#define VISION_CONCAT2(A, B) A##B
#define VISION_CONCAT(A, B) VISION_CONCAT2(A, B)

/**
 * Use this Macro to register the given function as a Frame Processor.
 * * Make sure the given function is a C-style function with the following signature: static inline id callback(CMSampleBufferRef buffer)
 * * Make sure the given function's name is unique across other frame processor plugins
 * * Make sure your frame processor returns a Value that can be converted to JS
 * * Make sure to use this Macro in an @implementation, not @interface
 */
#define VISION_EXPORT_FRAME_PROCESSOR(frame_processor)                              \
                                                                                    \
+(void)load                                                                         \
{                                                                                   \
  [FrameProcessorPluginRegistry addFrameProcessorPlugin:@"__" @ #frame_processor callback:^id(CMSampleBufferRef buffer) { \
    return frame_processor(buffer);                                                 \
  }];                                                                               \
}


/**
 * Same as VISION_EXPORT_FRAME_PROCESSOR, but uses __attribute__((constructor)) for
 * registration. Useful for registering swift classes that forbids use of +(void)load.
 */
#define VISION_EXPORT_SWIFT_FRAME_PROCESSOR(name, objc_name) \
objc_name : NSObject<FrameProcessorPluginBase>                                      \
@end                                                                                \
                                                                                    \
@interface objc_name (FrameProcessorPlugin)                                         \
@end                                                                                \
@implementation objc_name (FrameProcessorPlugin)                                    \
                                                                                    \
__attribute__((constructor)) static void VISION_CONCAT(initialize_, objc_name)()    \
{                                                                                   \
  [FrameProcessorPluginRegistry addFrameProcessorPlugin:@"__" @ #name callback:^id(CMSampleBufferRef buffer) {    \
    return [QRCodeFrameProcessorPlugin callback:buffer];                            \
  }];                                                                               \
}

#endif /* FrameProcessorPlugin_h */
