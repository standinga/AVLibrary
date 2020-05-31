//
//  AVEngineMockup.swift
//  VideoCaptureTheMoment
//
//  Created by michal on 05/11/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import UIKit
import AVFoundation

internal  extension AVEngineMockup {
    func setAttachments(to pixelBuffer: CVPixelBuffer) {
        let dict = createExtensions()
        CVBufferSetAttachments(pixelBuffer, dict, CVAttachmentMode(rawValue: kCMAttachmentMode_ShouldPropagate)!)
    }
    
    func createExtensions() -> CFDictionary {
        let dict = [kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_ITU_R_709_2, kCVImageBufferTransferFunctionKey: kCVImageBufferTransferFunction_ITU_R_709_2, kCVImageBufferYCbCrMatrixKey: kCVImageBufferYCbCrMatrix_ITU_R_601_4
            ] as CFDictionary
        return dict
    }
    
    func createSampleBufferWith(pixelBuffer: CVPixelBuffer) -> CMSampleBuffer {
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = .zero
        info.duration = .invalid
        info.decodeTimeStamp = .invalid
        var formatDesc: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDesc)
        guard let formatDescription = formatDesc else {
            fatalError("formatDescription")
        }
        var sampleBuff: CMSampleBuffer? = nil
        let status = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: formatDescription,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuff)
        
        guard status == noErr else {
            fatalError("CMSampleBufferCreateReadyWithImageBuffer failed \(status)")
        }
        guard let sampleBuffer = sampleBuff else {
            fatalError("samplebuffer")
        }
        return sampleBuffer
    }
    
    func retimeSampleBuffer(_ sampleBuffer: CMSampleBuffer, timestamp: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        var osStatus = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        guard osStatus == 0 else {
            fatalError("CMSampleBufferGetSampleTimingInfoArray \(osStatus)")
        }
        
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero), count: count)
        
        osStatus = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
        for i in 0..<count {
            info[i].presentationTimeStamp = timestamp
            info[i].decodeTimeStamp = .invalid
        }
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out)
        guard let retimedSampleBuffer = out else {
            fatalError("no retimedSampleBuffer")
        }
        return retimedSampleBuffer
    }
    
    func createCVPixelBuffer(from image: UIImage) -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            fatalError("cgImage nil \(#function)")
        }
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as CFBoolean,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as CFBoolean,
                     kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary // without kCVPixelBufferIOSurfacePropertiesKey key the AVAssetWriter won't append sample buffers with error: AVAssetWriterInput append fails with error code -11800 AVErrorUnknown -12780
            ] as CFDictionary
        var pbuff: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, cgImage.width, cgImage.height, kCVPixelFormatType_32ARGB, attrs, &pbuff)
        
        guard status == kCVReturnSuccess else { fatalError("status error \(status)")}
        guard let pixelBuffer = pbuff else { fatalError("pixelbuffer")}
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        guard let pixelAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            fatalError("pointer null \(#function)")
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelAddress, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            fatalError("context: \(#function)")
        }
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0) // different coordinates (from bottom instead of from top)
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        return pixelBuffer
    }
}
