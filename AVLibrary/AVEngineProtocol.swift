//
//  AVEngineProtocol.swift
//  VideoCaptureTheMoment
//
//  Created by michal on 05/11/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import AVFoundation

public protocol AVEngineProtocol : class {
    var cameraIndex: Int { get set }
    var avSession: AVCaptureSession! { get set }
    var availableCameraFormats: [CameraFormat] { get }
    var fps: Int { get }
    var delegate: AVEngineDelegate? { get set }
    var pauseCapturing: Bool  { get set }
    var supportsLockedFocus: Bool { get }
    var isRunning: Bool { get set }
    var isFocusLocked: Bool { get }
    var avData: AVEngineData? { get }
    var audioQueue: DispatchQueue { get }
    var videoQueue: DispatchQueue { get }
    var videoDevice: AVCaptureDevice? { get }
    
    func toggleCamera()
    func orientationChanged(rawValue: Int)
    func toggleFocus()
    func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int)
    func setupAVCapture (_ cameraIndex: Int, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation)
    func updateLensPositionAndLockFocus(_ lensPosition: Float)
    func debug()
    func destroy()
    func lockFocus()
    func unlockFocus()
}

public protocol AVEngineDelegate: class {
    #if os(iOS)
    func didStartRunning(format: AVCaptureDevice.Format, session: AVCaptureSession, avData: AVEngineData)
    #elseif os(macOS)
    func didStartRunning(format: AVCaptureDevice.Format, session: AVCaptureSession)
    #endif
    func didSwitchCamera(to cameraIndex: Int, avData: AVEngineData?)
    func didChangeVideoFormat(to format: AVCaptureDevice.Format)
    func startedChangingVideoFormat()
    func didSetFocus(_ focus: AVCaptureDevice.FocusMode, lensPosition: Float)
    func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection, timestamp: CMTime, output: AVCaptureOutput, isVideo: Bool)
}

public extension AVEngineProtocol {
    func destroy() { }
}

public extension AVEngineDelegate {
    func didSetFocus(_ focus: AVCaptureDevice.FocusMode, lensPosition: Float) { }
    func startedChangingVideoFormat() { }
}
