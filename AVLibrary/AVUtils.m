//
//  AVUtils.m
//  PrerecordCamera
//
//  Created by michal on 04/01/2018.
//  Copyright © 2018 borama. All rights reserved.
//

#import "AVUtils.h"

@implementation AVUtils

+(int)configureCurrentFormatForHighestFrameRate:(AVCaptureDevice *)device
{
    
    AVCaptureDeviceFormat *currentFormat = device.activeFormat;
    
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVFrameRateRange *range in currentFormat.videoSupportedFrameRateRanges ) {
        if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
            bestFrameRateRange = range;
        }
    }
    int cfRate = 0;
    if ( currentFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            cfRate = bestFrameRateRange.maxFrameRate;
            [device unlockForConfiguration];
        }
    }
    return cfRate;
}

+ (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device {
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    if ( bestFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = bestFormat;
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }
}

+(CMSampleBufferRef) copyH264SampleBufer:(CMSampleBufferRef) sampleBuffer {

    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    CMFormatDescriptionRef formatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer);

    CMSampleTimingInfo timing   = {.duration= kCMTimeInvalid, .presentationTimeStamp= CMSampleBufferGetPresentationTimeStamp(sampleBuffer), .decodeTimeStamp= CMSampleBufferGetDecodeTimeStamp(sampleBuffer)};
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timing);
    CMSampleBufferRef copySampleBuffer = NULL;

    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo * sampleTimingArray = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, sampleTimingArray, &count);

    CMSampleBufferCreate(kCFAllocatorDefault, nil, YES, nil, nil, formatDescriptionRef, 1, 1, sampleTimingArray, 0, nil, &copySampleBuffer);

    CFArrayRef newAttachments = CMSampleBufferGetSampleAttachmentsArray(copySampleBuffer, true);

    CFIndex numValues = CFArrayGetCount(attachmentsArray);

    CFIndex idx;
    for (idx = 0; idx < numValues; idx++) {
        CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsArray, idx);
        CFIndex count = CFDictionaryGetCount(dict);
        const void * keys [count];
        const void * values [count];
        CFMutableDictionaryRef newDict = (CFMutableDictionaryRef) CFArrayGetValueAtIndex(newAttachments, idx);
        CFDictionaryGetKeysAndValues(dict, keys, values);
        for (int i=0; i<count; i++) {
            CFDictionarySetValue(newDict, keys[i], values[i]);
        }
    }

    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
    size_t totalLenght = 0;
    size_t bufferLenght = 0;
    char* dataPointer = nil;

    CMBlockBufferGetDataPointer(blockBufferRef, 0, &bufferLenght, &totalLenght, &dataPointer);

    size_t bufferOffset = 0;
    size_t avcHeaderLength = 4;
    NSMutableData * buffer = [[NSMutableData alloc] init];
    char dataBytes[totalLenght];
    while (bufferOffset < totalLenght - avcHeaderLength) {
        UInt32 naluUnitLength = 0;
        memcpy(&naluUnitLength, dataPointer + bufferOffset, avcHeaderLength);
        naluUnitLength = CFSwapInt32BigToHost(naluUnitLength);
        char naluStart[4] = {0x0, 0x0, 0x0, 0x1};
        [buffer appendBytes: naluStart length:4];
        [buffer appendBytes:dataPointer + bufferOffset + avcHeaderLength length:naluUnitLength];
        bufferOffset += avcHeaderLength - naluUnitLength;
    }
    CMBlockBufferCopyDataBytes(blockBufferRef, 0, totalLenght, &dataBytes);
    CMBlockBufferRef copiedBuffer = NULL;

    CMBlockBufferCreateWithMemoryBlock(NULL, dataBytes, totalLenght, kCFAllocatorNull, NULL, 0, totalLenght, 0, &copiedBuffer);
//    CFRetain(copiedBuffer);
    CMSampleBufferSetDataBuffer(copySampleBuffer, copiedBuffer);
    free(sampleTimingArray);
    return copySampleBuffer;
}

+(CMSampleBufferRef) copyAudioSampleBufferRef:(CMSampleBufferRef) sampleBuffer blockBufferRef:(CMBlockBufferRef *) blockBufferRef
{
    AudioBufferList audioBufferList;
    //Create an AudioBufferList containing the data from the CMSampleBuffer,
    //and a CMBlockBuffer which references the data in that AudioBufferList.
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, blockBufferRef);
    NSUInteger size = sizeof(audioBufferList);
    char buffer[size];
    
    memcpy(buffer, &audioBufferList, size);
    //This is the Audio data.
    NSData *bufferData = [NSData dataWithBytes:buffer length:size];
    
    const void *copyBufferData = [bufferData bytes];
    copyBufferData = (char *)copyBufferData;
    
    CMSampleBufferRef copyBuffer = NULL;
    OSStatus status = -1;
    
    /* Format Description */
    
    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef) CMSampleBufferGetFormatDescription(sampleBuffer));
    
    CMFormatDescriptionRef format = NULL;
    status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioFormat, 0, nil, 0, nil, nil, &format);
    
    if (status != noErr) {
        NSLog(@"Error in CMFormatDescriptionRef %i", (int)status  );
        return NULL;
    }
    
    /* Create sample Buffer */
    CMItemCount framesCount = CMSampleBufferGetNumSamples(sampleBuffer);
    CMSampleTimingInfo timing   = {.duration= CMTimeMake(1, 44100), .presentationTimeStamp= CMSampleBufferGetPresentationTimeStamp(sampleBuffer), .decodeTimeStamp= CMSampleBufferGetDecodeTimeStamp(sampleBuffer)};
    
    status = CMSampleBufferCreate(kCFAllocatorDefault, nil , NO,nil,nil,format, framesCount, 1, &timing, 0, nil, &copyBuffer);
    
    if( status != noErr) {
        NSLog(@"Error in CMSampleBufferCreate %i ", (int)status);
        //        CFRelease(*blockBufferRef);
        return NULL;
    }
    
    /* Copy BufferList to Sample Buffer */
    AudioBufferList receivedAudioBufferList;
    memcpy(&receivedAudioBufferList, copyBufferData, sizeof(receivedAudioBufferList));
    
    //Creates a CMBlockBuffer containing a copy of the data from the
    //AudioBufferList.
    status = CMSampleBufferSetDataBufferFromAudioBufferList(copyBuffer, kCFAllocatorDefault , kCFAllocatorDefault, 0, &receivedAudioBufferList);
    if (status != noErr) {
        NSLog(@"Error in CMSampleBufferSetDataBufferFromAudioBufferList %i ", (int)status);
        //        CFRelease(*blockBufferRef);
        return NULL;
    }
    CFRelease(format); // need to release otherwise it leaks
    return copyBuffer;
}


+(CMSampleBufferRef)updateTimestamp:(CMSampleBufferRef)sampleBuffer updatedBuffer:(CMSampleBufferRef *)updateBuffer timestamp:(CMTime)timestamp
{
    CMSampleBufferRef retimedBuffer = NULL;
    CMItemCount count;
    OSStatus status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    if (status != 0) {
        NSLog(@"failed CMSampleBufferGetSampleT(int)imingInfoArray %i", (int)status);
        return NULL;
    }
    CMSampleTimingInfo * pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    status =  CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
    
    if (status != 0) {
        NSLog(@"failed CMSampleBufferGetSampleT(int)imingInfoArray %i", (int)status);
        free(pInfo);
        return NULL;
    }
    
    if (count > 123) {
        NSLog(@"count is large %li", count);
        free(pInfo);
        return NULL;
    }
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = kCMTimeInvalid;
        pInfo[i].presentationTimeStamp = timestamp;
    }
    status = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, count, pInfo, &retimedBuffer);
    
    if (status != 0) {
        NSLog(@"failed CMSampleBufferCreateCop(int)yWithNewTiming %i", (int)status);
        free(pInfo);
        return NULL;
    }
    
    free(pInfo);
    return retimedBuffer;
}
+(void)copyVideoFrame:(CVImageBufferRef)pixelBuffer bufferCopy:(CVImageBufferRef *)bufferCopy {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    uint8_t *baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    // copy pixel buffer:
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionary] , (id) kCVPixelBufferIOSurfacePropertiesKey, nil]; //  need to attach IOSurface in order to record video!
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,(__bridge CFDictionaryRef) pixelBufferAttributes, bufferCopy);
    
    NSParameterAssert(status == kCVReturnSuccess && bufferCopy != NULL);
    
    CVPixelBufferLockBaseAddress(*bufferCopy, 0);
    CVBufferPropagateAttachments(pixelBuffer, * bufferCopy); // nned to copy attachments in order to be able to record video frames!!!
    
    uint8_t *copyBaseAddress = CVPixelBufferGetBaseAddressOfPlane(*bufferCopy, 0);
    
    size_t size = CVPixelBufferGetDataSize(*bufferCopy);
    memcpy(copyBaseAddress, baseAddress, size);
    
    pixelBufferAttributes = NULL;
    CVPixelBufferUnlockBaseAddress(*bufferCopy, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
