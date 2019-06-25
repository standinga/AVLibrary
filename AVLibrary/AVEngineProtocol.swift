//
//  AVEngineProtocol.swift
//  VideoCaptureTheMoment
//
//  Created by michal on 05/11/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import AVFoundation

public protocol AVEngineProtocol : class {
    var avSession: AVCaptureSession! { get set }
    var availableCameraFormats: [CameraFormat] { get }
    var fps: Int { get }
    var delegate: AVEngineDelegate? { get set }
    var pauseCapturing: Bool  { get set }
    var hasLockedFocus: Bool { get }
    var isRunning: Bool { get set }
    var isFocusLocked: Bool { get }
    var currentCameraIndex: AVCaptureDevice.Position { get set }
    
    func flipCamera()
    func orientationChanged(rawValue: Int)
    func toggleFocus()
    func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int)
    func setupAVCapture (_ index: AVCaptureDevice.Position, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation)
    func updateLensPositionAndLockFocus(_ lensPosition: Float)
    func debug()
    func destroy()
}

public protocol AVEngineDelegate: class {
    func didStartRunning(format: AVCaptureDevice.Format?, session: AVCaptureSession?)
    func didSwitchCamera(_ camIndex: Int)
    func didChangeVideoFormat(to format: AVCaptureDevice.Format)
    func startedChangingVideoFormat()
    func didSetFocus(_ focus: AVCaptureDevice.FocusMode, lensPosition: Float)
    func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, timestamp: CMTime)
}

public extension AVEngineProtocol {
    func destroy() { }
}
