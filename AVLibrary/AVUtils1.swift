//
//  AVUtils.swift
//  PrerecordCamera
//
//  Created by michal on 04/01/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import Foundation
import AVFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

open class AVUtils1 {
    
    public static func updateTimestamp(_ sample: CMSampleBuffer, timestamp: CMTime) -> CMSampleBuffer {
        let count: CMItemCount = 1
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero), count: count)
        

        for i in 0..<count {
            info[i].decodeTimeStamp = timestamp
            info[i].presentationTimeStamp = timestamp
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out)
        return out!
    }
    
    static func getVideoTransform(orientation: AVCaptureVideoOrientation, cameraPosition: Int) -> CGAffineTransform {
        var transform: CGAffineTransform!
        switch(orientation) {
        case AVCaptureVideoOrientation.portrait:
            transform = CGAffineTransform(rotationAngle: 0)
        case AVCaptureVideoOrientation.portraitUpsideDown:
            transform = CGAffineTransform(rotationAngle: 0)
        case AVCaptureVideoOrientation.landscapeLeft:
            transform = CGAffineTransform(rotationAngle: 0)
        case AVCaptureVideoOrientation.landscapeRight:
            transform = CGAffineTransform(rotationAngle: 0)
        @unknown default:
            transform = CGAffineTransform(rotationAngle: 0)
        }
        return transform;
    }
    
    static func angleOffsetFromPortraitOrientationToOrientation(_ orientation: AVCaptureVideoOrientation) -> CGFloat {
        var angle: CGFloat = 0.0
        switch ( orientation )
        {
        case AVCaptureVideoOrientation.portrait:
            angle = 0.0
        case AVCaptureVideoOrientation.portraitUpsideDown:
            angle = CGFloat(Double.pi)
        case AVCaptureVideoOrientation.landscapeRight:
            angle = CGFloat(-Double.pi / 2)
        case AVCaptureVideoOrientation.landscapeLeft:
            angle = CGFloat(Double.pi / 2)
        @unknown default:
            angle = 0.0
        }
        return angle;
    }
    
    static func getFormatFromHashFormat(_ cameraFormats: [CameraFormat], hashValue: Int) -> AVCaptureDevice.Format? {
        for camFormat in cameraFormats {
            print (camFormat.format!.formatDescription.hashValue)
            if camFormat.format?.formatDescription.hashValue == hashValue {
                return camFormat.format
            }
        }
        return nil
    }
    
    static func getFormatFromFormatString(_ cameraFormats: [CameraFormat], formatString: String?) -> AVCaptureDevice.Format? {
        if formatString == nil { return nil }
        for camFormat in cameraFormats {
            if AVUtils1.formatToString(camFormat.format) == formatString! {
                return camFormat.format
            }
        }
        return nil
    }
    
    static func availableCameraForamats(_ device: AVCaptureDevice?, currentFormat: AVCaptureDevice.Format?, maxFrameSize: Int =  1280 * 720) -> [CameraFormat] {
        var formatsArray = [CameraFormat]()

        guard let device = device else { return formatsArray }
        let deviceFormats = device.formats
        var index = 0
        for deviceFormat in deviceFormats {
            let description = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(description) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                if dimensions.width * dimensions.height > maxFrameSize
                    || dimensions.width == 480 || dimensions.width == 352 {
                    continue
                }
                let cameraResolution = "\(dimensions.width) x \(dimensions.height)"
                var cameraFormat = CameraFormat(index, resolution: cameraResolution, format: deviceFormat)
                
                cameraFormat.currentFormat = currentFormat
                formatsArray.append(cameraFormat)
                index += 1
            }
        }
        formatsArray = removeDuplicatedResolutions(formatsArray)
        return formatsArray
    }
    /// leaves formats with highest possible fps,
    /// if there are two formats of resolutions 1280x720, it will remove format with lower max fps
    private static func removeDuplicatedResolutions(_ formats: [CameraFormat]) -> [CameraFormat] {
        let formatsIndexesSizesAndMaxFps = formats
            .map {($0.index, $0.resolution, $0.format?.videoSupportedFrameRateRanges[0].maxFrameRate ?? -1)}
            .filter { $0.2 > -1 }
        let formatsSorted = Dictionary(grouping: formatsIndexesSizesAndMaxFps, by: { $0.1 })
            .compactMap { $1.max(by: { (l, r) -> Bool in
                return l.2 < r.2
            })}
            .sorted{ $0.0 < $1.0 }
        let indexes = formatsSorted.reduce(into: Set<Int>()) { (acc, arg1) in
            let (idx, _, _) = arg1
            acc.insert(idx)
        }
        return formats.filter{indexes.contains($0.index)}
    }
    
    public static func formatToString(_ format: AVCaptureDevice.Format?) -> String {
        guard let strongFormat = format else { return "" }
        let description = strongFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(description)
        let width = dimensions.width
        let height = dimensions.height
        let maxFPS = strongFormat.videoSupportedFrameRateRanges[0].maxFrameRate
        let minFPS = strongFormat.videoSupportedFrameRateRanges[0].minFrameRate
        #if os(iOS)
        let minIso = strongFormat.minISO
        let maxIso = strongFormat.maxISO
        return "width:\(width)height:\(height)minfps:\(minFPS)maxfps:\(maxFPS)miniso:\(minIso)maxiso:\(maxIso)"
        #elseif os(macOS)
        return "width:\(width)height:\(height)minfps:\(minFPS)maxfps:\(maxFPS)"
        #endif
    }
    
    #if os(iOS)
    
    static func cameraOrientationFromDeviceOrientation (_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        var newOrientation:AVCaptureVideoOrientation!
        switch (deviceOrientation) {
        case .portrait:
            newOrientation = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            newOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        case .landscapeLeft:
            newOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        case .landscapeRight:
            newOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        default:
            newOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        }
        return newOrientation
    }
    
    static func videoOrientationFromDeviceOrientation (_ deviceOrientation: UIDeviceOrientation ) -> AVCaptureVideoOrientation {
        var newOrientation: AVCaptureVideoOrientation!
        switch (deviceOrientation) {
        case .portrait:
            newOrientation = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            newOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        case .landscapeLeft:
            newOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        case .landscapeRight:
            newOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        default:
            newOrientation = AVCaptureVideoOrientation.portrait
        }
        return newOrientation
    }
    #endif
}
