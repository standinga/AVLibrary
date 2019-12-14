//
//  AVEngineMockup.swift
//  VideoCaptureTheMoment
//
//  Created by michal on 05/11/2018.
//  Copyright © 2018 borama. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import AVFoundation
class AVEngineMockup: NSObject, AVEngineProtocol {
    
    var avSession: AVCaptureSession! = nil
    var availableCameraFormats: [CameraFormat] = AVEngineMockupUtils.formats
    var fps = 30
    weak var delegate: AVEngineDelegate?
    var lockingQueue: DispatchQueue!
    var imageQueue = DispatchQueue(label: "avenginemockup.image.queue")
    var pauseCapturing = false
    var supportsLockedFocus = true
    var isRunning = true
    var currentCameraPosition = AVCaptureDevice.Position.back
    var format: MockupAVFormat
    var avData: AVEngineData? = nil
    
    private var timer: Timer?
    private var sampleBuffer: CMSampleBuffer!
    
    var isFocusLocked = false
    var previousTimestamp = CFAbsoluteTimeGetCurrent()
    var startTime = CFAbsoluteTimeGetCurrent() - 0.02
    
    init(lockingQueue: DispatchQueue) {
        self.lockingQueue = lockingQueue
        
        self.format = MockupAVFormat()
        previousTimestamp = CFAbsoluteTimeGetCurrent()
        
        super.init()
        #if os(iOS)
        let image = UIImage(named: "tree1080_1920.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        
        let pixelBuffer = createCVPixelBuffer(from: image)
        setAttachments(to: pixelBuffer)
        let sampleBuffer = createSampleBufferWith(pixelBuffer: pixelBuffer)
        
        self.sampleBuffer = sampleBuffer
        format.mockFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(onTime), userInfo: nil, repeats: true)
        timer?.fire()
        #endif
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
    
    func lockFocus() {
        
    }
    
    func unlockFocus() {
        
    }
    
    @objc func onTime() {
        #if os(iOS)
        let now = CFAbsoluteTimeGetCurrent()
        let delta = now - previousTimestamp
        startTime += delta
        previousTimestamp = now
        let timestamp = CMTime(seconds: startTime, preferredTimescale: 1000000000)
        let retimedSampleBuffer = retimeSampleBuffer(sampleBuffer, timestamp: timestamp)
        
        //        delegate?.onPixelBuffer(pixelBuffer, timestamp: time, formatDescription: fd)
        delegate?.onSampleBuffer(retimedSampleBuffer, connection: AVCaptureConnection(inputPorts: [], output: MockupAVCaptureOutput()), timestamp: timestamp, output: MockupAVCaptureOutput(), isVideo: true)
        #endif
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
        #if os(iOS)
        delegate?.didStartRunning(format: format, session: session, avData: AVEngineData(format: format, session: session, cameraPosition: .front, fps: 30, focus: .autoFocus, lensPosition: 1.4, videoOrientation: .portrait))
        #endif
    }
}
