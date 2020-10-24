//
//  AVUtils.h
//  PrerecordCamera
//
//  Created by michal on 04/01/2018.
//  Copyright © 2018 borama. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
@interface AVUtils : NSObject

+(int)configureCurrentFormatForHighestFrameRate:(AVCaptureDevice *)device;
+(void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device;

+(CMSampleBufferRef) copyAudioSampleBufferRef:(CMSampleBufferRef) sampleBuffer blockBufferRef:(CMBlockBufferRef *) blockBufferRef;
+(CMSampleBufferRef)updateTimestamp:(CMSampleBufferRef)sampleBuffer updatedBuffer:(CMSampleBufferRef *)updateBuffer timestamp:(CMTime)timestamp;
+(CMSampleBufferRef) copyH264SampleBufer:(CMSampleBufferRef) sampleBuffer blockBufferRef:(CMBlockBufferRef *) copiedBufferRef;
+(void)copyVideoFrame:(CVImageBufferRef)pixelBuffer bufferCopy:(CVImageBufferRef *)bufferCopy;
@end
