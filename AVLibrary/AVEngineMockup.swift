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
    weak var delegate: AVEngineDelegate!
    var lockingQueue: DispatchQueue!
    var imageQueue = DispatchQueue(label: "avenginemockup.image.queue")
    var pauseCapturing = false
    var hasLockedFocus = true
    var isRunning = true
    var currentCameraIndex = AVCaptureDevice.Position.back
    private var timer: Timer?
    private var timevalue: Int64 = 46735832821083
    
    var isFocusLocked = false
    var blackImage: UIImage!
    
    init(lockingQueue: DispatchQueue) {
        self.lockingQueue = lockingQueue
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 600, height: 800))
        let ciimage = CIImage(color: CIColor(color: .black))
        let cgImage = CIContext().createCGImage(ciimage, from: frame)!
        blackImage = UIImage(cgImage: cgImage)
        super.init()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(onTime), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    override init() {
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
        let time = CMTime(value: timevalue, timescale: 1000000000)
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        guard let fd = formatDescription else {
            fatalError("can't create formatDescription")
        }
//        delegate?.onPixelBuffer(pixelBuffer, timestamp: time, formatDescription: fd)
    }
    
    func flipCamera() {
        
    }
    
    func orientationChanged(rawValue: Int) {
        
    }
    
    func toggleFocus() {
        
    }
    
    func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int) {
        
    }
    
    func setupAVCapture(_ index: AVCaptureDevice.Position, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation) {
        delegate.didStartRunning()
    }
}
