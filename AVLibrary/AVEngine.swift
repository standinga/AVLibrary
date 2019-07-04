//
//  AVWrapper.swift
//  PrerecordCamera
//
//  Created by michal on 27/12/2017.
//  Copyright © 2017 borama. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class AVEngine: NSObject, AVEngineProtocol {
    
    var avSession: AVCaptureSession!
    var currentCameraPosition = AVCaptureDevice.Position.back
    
    // MARK: session management:
    private var sesionPreset = AVCaptureSession.Preset.vga640x480
    private let sessionQueue = DispatchQueue(
        label:"co.borama.sessionQueue",
        qos: .userInitiated)
    
    private let videoQueue = DispatchQueue(label: "co.borama.videoQueue", qos: .userInitiated)
    private let audioQueue = DispatchQueue(label: "co.borama.audioQueue", qos: .userInitiated)
    
    private var videoIn: AVCaptureDeviceInput?
    private var videoOut: AVCaptureVideoDataOutput?
    var videoDevice: AVCaptureDevice?
    private var videoFormat: AVCaptureDevice.Format? {
        return videoDevice?.activeFormat
    }
    private var videoConnection: AVCaptureConnection?
    
    private var audioIn: AVCaptureDeviceInput?
    private var audioOut: AVCaptureAudioDataOutput?
    private var audioConnection: AVCaptureConnection?
    private var audioCompressionSettings: [AnyHashable : Any]?
    
    private var lockQueue: DispatchQueue!
    private var currentFPS = 0
    
    private var frontCamera: AVCaptureDevice?
    private var rearCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    private var rearCameraInput: AVCaptureDeviceInput?
    
    var availableCameraFormats: [CameraFormat] {
        return AVUtils1.availableCameraForamats(videoDevice, currentFormat: videoFormat, maxFrameSize: 5000 * 5000 )
    }
    
    var isRunning = false
    
    var fps: Int {
        return Int(videoDevice?.activeVideoMinFrameDuration.timescale ?? 0)
    }
    
    
    // MARK: delegate:f
    weak var delegate: AVEngineDelegate?
    
    var pauseCapturing = false
    var hasLockedFocus: Bool {
        return videoDevice?.isFocusModeSupported(.locked) ?? false
    }
    
    var isFocusLocked: Bool {
        return videoDevice?.focusMode == .locked
    }
    
    init (withLockingQueue: DispatchQueue) {
        lockQueue = withLockingQueue
        super.init()
    }
    
    func debug() { }
    
    func updateLensPositionAndLockFocus(_ lensPosition: Float) {
        guard let device = videoDevice, device.isFocusModeSupported(.locked) else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.setFocusModeLocked(lensPosition: lensPosition) { time in
                print("AVEngine did set focus", lensPosition)
            }
            device.focusMode = .locked
            device.unlockForConfiguration()
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let device = videoDevice else { return }
        if keyPath == "focusMode" {
            if let change = change, let rawFocusMode = change[.newKey] as? Int {
                let lensPosition = device.lensPosition
                let fm = AVCaptureDevice.FocusMode(rawValue: rawFocusMode) ?? .continuousAutoFocus
                delegate?.didSetFocus(lensPosition > 0.9999 ? .continuousAutoFocus : fm, lensPosition: lensPosition)
            }
        } else {
            //            print("AVEngine lens")
        }
    }
    
    deinit {
        videoDevice?.removeObserver(self, forKeyPath: "focusMode")
        videoDevice?.removeObserver(self, forKeyPath: "lensPosition")
        NSLog("AVEngine deinited!!!")
    }
    
    fileprivate func initVideoInput(videoDevice: AVCaptureDevice, session: AVCaptureSession) {
        do {
            try videoIn = AVCaptureDeviceInput.init(device: videoDevice)
            guard let videoIn = videoIn else { return }
            if  session.canAddInput(videoIn)  {
                session.addInput(videoIn)
                NSLog("addedInput")
            }
        } catch {
            NSLog("initvideoinput error")
        }
    }
    
    fileprivate func initVideoOutput(session: AVCaptureSession, videoOrientation: AVCaptureVideoOrientation) {
        videoOut = AVCaptureVideoDataOutput()
        videoOut?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        videoOut?.alwaysDiscardsLateVideoFrames = false
        videoOut?.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOut!) {
            session.addOutput(videoOut!)
            videoConnection = videoOut!.connection(with: .video)
            videoConnection?.videoOrientation = videoOrientation
            NSLog("videoConnection?.isVideoMirroringSupported \(videoConnection?.isVideoMirroringSupported)")
        }
    }
    
    fileprivate func initAudioInput(audioDevice: AVCaptureDevice?, session: AVCaptureSession) {
        guard let audioDevice = audioDevice else { return }
        do {
            try
                audioIn = AVCaptureDeviceInput.init(device: audioDevice)
            guard let audioIn = audioIn else {return}
            if session.canAddInput(audioIn) {
                session.addInput(audioIn)
            }
        } catch let error {
            NSLog(error.localizedDescription)
            return
        }
    }
    
    fileprivate func initAudioOutput(session: AVCaptureSession) {
        if (audioOut != nil) {
            session.removeOutput(audioOut!)
        }
        audioOut = AVCaptureAudioDataOutput()
        guard let audioOut = audioOut else { return }
        
        audioOut.setSampleBufferDelegate(self, queue: audioQueue)
        if session.canAddOutput(audioOut) {
            session.addOutput(audioOut)
            audioConnection = audioOut.connection(with: .audio)
            audioCompressionSettings = audioOut.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov)
        }
    }
    
    func toggleFocus() {
        guard let device = self.videoDevice else {
            return
        }
        do {
            try
                device.lockForConfiguration()
            if device.isFocusModeSupported(.locked) {
                let fMode = device.focusMode
                device.focusMode = fMode == AVCaptureDevice.FocusMode.locked ? .continuousAutoFocus : .locked
            }
            device.unlockForConfiguration()
            delegate?.didSetFocus(device.focusMode, lensPosition: device.lensPosition)
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }
    
    
    public func setupAVCapture (_ cameraPosition: AVCaptureDevice.Position, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation) {
        currentCameraPosition = cameraPosition
        NSLog("AVEngine setupAVCapture")
        requestCameraAccess()
        
        avSession = AVCaptureSession()
        avSession.sessionPreset = sesionPreset
        videoDevice = getChosenCamera(currentCameraPosition)
        addVideoDeviceObserver()
        let cameraFormats = AVUtils1.availableCameraForamats(videoDevice, currentFormat: nil )
        let format = AVUtils1.getFormatFromFormatString(cameraFormats, formatString: savedFormatString)
        
        let audioDevice = AVCaptureDevice.default(for: .audio)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.avSession.beginConfiguration()
            
            self.initVideoInput(videoDevice: self.videoDevice!, session: self.avSession)
            self.initVideoOutput(session: self.avSession, videoOrientation: videoOrientation)
            
            self.initAudioInput(audioDevice: audioDevice, session: self.avSession)
            self.initAudioOutput(session: self.avSession)
            
            self.avSession.commitConfiguration()
            self.avSession.startRunning()
            
            if let device = self.videoDevice {
                do {
                    try
                        device.lockForConfiguration()
                    if let format = format {
                        self.setCustomFormatOrDefault(format, device: self.videoDevice)
                    }
                    var fps = Int32(fps)
                    let maxFrameRate = device.activeFormat.videoSupportedFrameRateRanges[0].maxFrameRate
                    fps = min(Int32(maxFrameRate), fps)
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: fps)
                    device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: fps)
                    self.currentFPS = Int(fps)
                    device.unlockForConfiguration()
                } catch let error {
                    NSLog(error.localizedDescription)
                }
            }
            
            if (self.videoFormat != nil) {
                let formatString = AVUtils1.formatToString(self.videoFormat)
                #warning("needs to be done where delegate is implemented")
                //                UserDefaults.setCameraFormat(formatString)
            }
            self.isRunning = true
            DispatchQueue.main.async {
                self.delegate?.didStartRunning(format: self.videoFormat, session: self.avSession)
            }
        }
    }
    
    public func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int) {
        guard let format = format else {
            return
        }
        delegate?.startedChangingVideoFormat()
        sessionQueue.async { [weak self] in
            NSLog("changeCameraFormat in queue")
            guard let self = self else { return }
            do {
                try
                    self.videoDevice?.lockForConfiguration()
                self.setCustomFormatOrDefault(format, device: self.videoDevice)
                let maxFPS = format.videoSupportedFrameRateRanges[0].maxFrameRate
                let newFPS = min(maxFPS, Float64(fps))
                self.videoDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(newFPS))
                self.videoDevice?.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(newFPS))
                self.videoDevice?.unlockForConfiguration()
                self.currentFPS = fps
                self.delegate?.didChangeVideoFormat(to: format)
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    private func setCustomFormatOrDefault(_ format: AVCaptureDevice.Format?, device: AVCaptureDevice?) {
        guard let format = format else {
            setFormatTo640480(device)
            return
        }
        if let supported = device?.formats.filter({$0 == format}).first {
            device?.activeFormat = supported
        } else {
            setFormatTo640480(device)
        }
    }
    
    private func setFormatTo640480(_ device: AVCaptureDevice?) {
        guard let device = device else {
            return
        }
        let formats = device.formats
        for format in formats {
            let formatDescription = format.formatDescription
            let dimens = CMVideoFormatDescriptionGetDimensions(formatDescription)
            if dimens.width * dimens.height == 640 * 480 {
                device.activeFormat = format
                return
            }
        }
    }
    
    public func orientationChanged(rawValue: Int) {
        defer {
            self.videoDevice?.unlockForConfiguration()
            NSLog("AVEngine videoDevice?.unlockForConfiguration()")
        }
        do {
            NSLog("AVEngine orientationChanged try videoDevice?.lockForConfiguration()")
            try self.videoDevice?.lockForConfiguration()
            self.videoConnection?.videoOrientation = AVCaptureVideoOrientation(rawValue: rawValue)!
        } catch {
            NSLog(error.localizedDescription)
        }
        
    }
    
    public func toggleCamera() {
        guard let inputs = avSession.inputs as? [AVCaptureDeviceInput] else {return}
        currentCameraPosition = currentCameraPosition == .front ? .back : .front
        avSession.beginConfiguration()
        
        let newDevice = getChosenCamera(currentCameraPosition)
        
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch let error {
            NSLog(error.localizedDescription)
            return
        }
        
        for input in inputs {
            let inputDescription = input.description
            if inputDescription.contains("amera") {
                avSession.removeInput(input)
            }
        }
        
        if avSession.canAddInput(deviceInput) {
            avSession.addInput(deviceInput)
        }
        videoConnection = videoOut!.connection(with: .video)
        videoConnection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.deviceOrientation.rawValue)!
        videoDevice = newDevice
        do {
            try
                videoDevice?.lockForConfiguration()
            setCustomFormatOrDefault(nil, device: videoDevice)
            videoDevice?.unlockForConfiguration()
        } catch {
            NSLog(error.localizedDescription)
        }
        avSession.commitConfiguration()
        delegate?.didSwitchCamera(currentCameraPosition.rawValue)
        addVideoDeviceObserver()
    }
    
    public func destroy() {
        NSLog("AVEngine destroy")
        sessionQueue.async { [weak self] in
            self?.avSession?.stopRunning()
            self?.avSession = nil
        }
    }
    
    public func initCameras() {
        if #available(iOS 10.0, *) {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            session.devices.forEach {
                if $0.position == .front {
                    frontCamera = $0
                }
                if $0.position == .back {
                    rearCamera = $0
                }
            }
        } else {
            let devices = AVCaptureDevice.devices(for: .video)
            devices.forEach {
                if $0.position == .front {
                    frontCamera = $0
                }
                if $0.position == .back {
                    rearCamera = $0
                }
            }
        }
    }
    
    private func addVideoDeviceObserver() {
        NSLog("addVideoDeviceObserver")
        videoDevice?.addObserver(self, forKeyPath: "focusMode", options: .new, context: nil)
        videoDevice?.addObserver(self, forKeyPath: "lensPosition", options: .new, context: nil)
    }
    
    @available(iOS, deprecated: 12.0)
    fileprivate func getChosenCamera(_ cameraPosition: AVCaptureDevice.Position)->AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices {
            if device.position == cameraPosition {
                return device
            }
        }
        return nil
    }
    
    fileprivate func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) {
            (granted: Bool) -> Void in
            guard granted else {
                
                return
            }
        }
    }
    
    fileprivate func timestamp(sampleBuffer: CMSampleBuffer?)-> Double {
        guard let sampleBuffer = sampleBuffer else {return 0}
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard time != .invalid else {return 0}
        return (Double)(time.value) / (Double)(time.timescale);
    }
    
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

extension AVEngine: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if pauseCapturing { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        lockQueue.async { [weak self] in
            self?.delegate?.onSampleBuffer(sampleBuffer, connection: connection, timestamp: timestamp, output: output, isVideo: connection == self?.videoConnection)
        }
    }
}
