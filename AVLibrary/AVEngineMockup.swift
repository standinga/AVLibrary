//
//  AVEngineMockup.swift
//  VideoCaptureTheMoment
//
//  Created by michal on 05/11/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import UIKit
import AVFoundation
class AVEngineMockup: NSObject, AVEngineProtocol {
    
    var avSession: AVCaptureSession! = nil
    var availableCameraFormats: [CameraFormat] = AVEngineMockupUtils.formats
    var fps = 30
    var logger: AVLogger = AVLogger()
    weak var delegate: AVEngineDelegate?
    var lockingQueue: DispatchQueue!
    var imageQueue = DispatchQueue(label: "avenginemockup.image.queue")
    var pauseCapturing = false
    var supportsLockedFocus = true
    var isRunning = true
    var currentCameraPosition = AVCaptureDevice.Position.back
    var format: MockupAVFormat
    private var timer: Timer?
    private var timevalue: Int64 = 46735832821083
    private var sampleBuffer: CMSampleBuffer!
    
    var isFocusLocked = false
    var blackImage: UIImage!
    var previous = CFAbsoluteTimeGetCurrent()
    var startTime = CFAbsoluteTimeGetCurrent() - 0.02
    
    init(lockingQueue: DispatchQueue) {
        self.lockingQueue = lockingQueue
        
        self.format = MockupAVFormat()
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 600, height: 800))
        let ciimage = CIImage(color: CIColor(color: .black))
        let cgImage = CIContext().createCGImage(ciimage, from: frame)!
        blackImage = UIImage(cgImage: cgImage)
        let image = UIImage(named: "sky", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        super.init()
        previous = CFAbsoluteTimeGetCurrent()
        let pixelBuffer = createCVPixelBuffer(from: image)
        
        setAttachments(to: pixelBuffer)
        
        let sampleBuffer = createSampleBufferWith(pixelBuffer: pixelBuffer)
        
        print(sampleBuffer)
        self.sampleBuffer = sampleBuffer
        format.mockFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(onTime), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func createCVPixelBuffer(from image: UIImage) -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            fatalError("cgImage nil \(#function)")
        }
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as CFBoolean,
                     kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary // without kCVPixelBufferIOSurfacePropertiesKey key the AVAssetWriter won't append sample buffers with error: AVAssetWriterInput append fails with error code -11800 AVErrorUnknown -12780
                     ] as CFDictionary
        var pbuff: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, cgImage.width, cgImage.height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &pbuff)
        
        guard status == kCVReturnSuccess else { fatalError("status error \(status)")}
        guard let pixelBuffer = pbuff else { fatalError("pixelbuffer")}
        
        return pixelBuffer
    }
    
    override init() {
        self.format = MockupAVFormat()
        super.init()
    }
    
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func debug() {
        print("AVEngineMockup debugAccess", self)
    }
    
    func updateLensPositionAndLockFocus(_ lensPosition: Float) {
        
    }
    
    @objc func onTime() {
        guard let pixelBuffer = blackImage.pixelBuffer else {
            fatalError("can't create pixelbuffer")
        }
        timevalue += 50000000
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        guard let fd = formatDescription else {
            fatalError("can't create formatDescription")
        }
        
        var count: CMItemCount = 0
        var osStatus = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero), count: count)
        
        osStatus = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
        let now = CFAbsoluteTimeGetCurrent()
        let delta = now - previous
        startTime += delta
        previous = now
        let timestamp = CMTime(seconds: startTime, preferredTimescale: 1000000000)
        for i in 0..<count {
            info[i].presentationTimeStamp = timestamp
            info[i].decodeTimeStamp = .invalid
        }
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out)
        guard let retimedSampleBuffer = out else {
            fatalError("no retimedSampleBuffer")
        }
//        delegate?.onPixelBuffer(pixelBuffer, timestamp: time, formatDescription: fd)
        delegate?.onSampleBuffer(retimedSampleBuffer, connection: AVCaptureConnection(inputPorts: [], output: MockupAVCaptureOutput()), timestamp: timestamp, output: MockupAVCaptureOutput(), isVideo: true)
    }
    
    func setAttachments(to pixelBuffer: CVPixelBuffer) {
        let dict = [kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_ITU_R_709_2, kCVImageBufferTransferFunctionKey: kCVImageBufferTransferFunction_ITU_R_709_2, kCVImageBufferYCbCrMatrixKey: kCVImageBufferYCbCrMatrix_ITU_R_601_4] as CFDictionary
        
        CVBufferSetAttachments(pixelBuffer, dict, CVAttachmentMode(rawValue: kCMAttachmentMode_ShouldPropagate)!)
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
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: formatDescription,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuff)
        guard let sampleBuffer = sampleBuff else {
            fatalError("samplebuffer")
        }
        return sampleBuffer
    }
    
    func toggleCamera() {
        
    }
    
    func orientationChanged(rawValue: Int) {
        
    }
    
    func toggleFocus() {
        
    }
    
    func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int) {
        
    }
    
    func setupAVCapture(_ index: AVCaptureDevice.Position, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation) {
        let session = AVCaptureSession()
        delegate?.didStartRunning(format: format, session: session, avData: AVEngineData(format: format, session: session, cameraPosition: .front, fps: 30, focus: .autoFocus, lensPosition: 1.4, videoOrientation: .portrait))
    }
}
