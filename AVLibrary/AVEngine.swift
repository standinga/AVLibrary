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
    
    weak var delegate: AVEngineDelegate?
    
    var avSession: AVCaptureSession!
    var currentCameraPosition = AVCaptureDevice.Position.back
    var videoDevice: AVCaptureDevice?
    
    var isRunning = false
    
    var availableCameraFormats: [CameraFormat] {
        return AVUtils1.availableCameraForamats(videoDevice, currentFormat: videoFormat, maxFrameSize: 1920 * 1080 )
    }
    
    var fps: Int {
        return Int(videoDevice?.activeVideoMinFrameDuration.timescale ?? 0)
    }
    
    
    var pauseCapturing = false {
        didSet {
            videoConnection?.isEnabled = !pauseCapturing
            audioConnection?.isEnabled = !pauseCapturing
        }
    }
    var supportsLockedFocus: Bool {
        return videoDevice?.isFocusModeSupported(.locked) ?? false
    }
    
    var isFocusLocked: Bool {
        return videoDevice?.focusMode == .locked
    }
    
    var avData: AVEngineData? {
        return AVEngineData(format: videoFormat, session: avSession, cameraPosition: currentCameraPosition, fps: fps, focus: videoDevice?.focusMode , lensPosition: videoDevice?.lensPosition, videoOrientation: videoOrientation)
    }
    
    
    // MARK: session management:
    private var sesionPreset = AVCaptureSession.Preset.vga640x480
    private let sessionQueue = DispatchQueue(
        label:"co.borama.sessionQueue",
        qos: .userInitiated)
    
    private let videoQueue = DispatchQueue(label: "co.borama.videoQueue", qos: .userInitiated)
    private let audioQueue = DispatchQueue(label: "co.borama.audioQueue", qos: .userInitiated)
    
    private var videoIn: AVCaptureDeviceInput?
    private var videoOut: AVCaptureVideoDataOutput?
    private var videoConnection: AVCaptureConnection?
    private var audioConnection: AVCaptureConnection?
    
    private var audioIn: AVCaptureDeviceInput?
    private var audioOut: AVCaptureAudioDataOutput?
    private var audioCompressionSettings: [AnyHashable : Any]?
    
    private var lockQueue: DispatchQueue!
    private var currentFPS = 0
    
    private var frontCamera: AVCaptureDevice?
    private var rearCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    private var rearCameraInput: AVCaptureDeviceInput?
    
    private var videoOrientation: AVCaptureVideoOrientation?
    
    private var videoFormat: AVCaptureDevice.Format? {
        return videoDevice?.activeFormat
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
            device.setFocusModeLocked(lensPosition: lensPosition) { _ in }
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
        }
    }
    
    deinit {
        videoDevice?.removeObserver(self, forKeyPath: "focusMode")
        videoDevice?.removeObserver(self, forKeyPath: "lensPosition")
    }
    
    fileprivate func initVideoInput(videoDevice: AVCaptureDevice, session: AVCaptureSession) {
        do {
            try videoIn = AVCaptureDeviceInput.init(device: videoDevice)
            guard let videoIn = videoIn else { return }
            if  session.canAddInput(videoIn)  {
                session.addInput(videoIn)
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
            self.videoOrientation = videoOrientation
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
            
            self.isRunning = true
            
            guard let format = self.videoFormat, let session = self.avSession else {
                return
            }
            
            guard let avData = AVEngineData(format: format, session: self.avSession, cameraPosition: self.currentCameraPosition, fps: self.currentFPS, focus: self.videoDevice!.focusMode, lensPosition: self.videoDevice!.lensPosition, videoOrientation: videoOrientation) else {
                fatalError("avData nil in setup")
            }
            self.videoOrientation = videoOrientation
            DispatchQueue.main.async {
                self.delegate?.didStartRunning(format: format, session: session, avData: avData)
            }
        }
    }
    
    public func changeCameraFormat(_ format: AVCaptureDevice.Format?, fps: Int) {
        guard let format = format else {
            return
        }
        delegate?.startedChangingVideoFormat()
        sessionQueue.async { [weak self] in
            self?.changeCameraFormatSync(format, fps: fps)
        }
    }
    
    private func changeCameraFormatSync(_ format: AVCaptureDevice.Format, fps: Int) {
        do {
            try
                videoDevice?.lockForConfiguration()
            setCustomFormatOrDefault(format, device: videoDevice)
            let maxFPS = format.videoSupportedFrameRateRanges[0].maxFrameRate
            let newFPS = min(maxFPS, Float64(fps))
            videoDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(newFPS))
            videoDevice?.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(newFPS))
            videoDevice?.unlockForConfiguration()
            currentFPS = fps
            delegate?.didChangeVideoFormat(to: format)
        } catch let error {
            NSLog(error.localizedDescription)
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
        sessionQueue.async { [weak self] in
            do {
                try self?.videoDevice?.lockForConfiguration()
                self?.videoConnection?.videoOrientation = AVCaptureVideoOrientation(rawValue: rawValue)!
                self?.videoOrientation = AVCaptureVideoOrientation(rawValue: rawValue)
            } catch {
                NSLog("\(error.localizedDescription)")
            }
            self?.videoDevice?.unlockForConfiguration()
        }
    }
    
    public func toggleCamera() {
        sessionQueue.async {
            [weak self] in
            self?.toggleCameraSync()
        }
    }
    
    private func toggleCameraSync() {
        guard let inputs = avSession.inputs as? [AVCaptureDeviceInput] else {return}
        pauseCapturing = true
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
        videoDevice = newDevice
        do {
            try
                videoDevice?.lockForConfiguration()
            setCustomFormatOrDefault(nil, device: videoDevice)
            videoConnection = videoOut!.connection(with: .video)
            videoDevice = newDevice
            videoDevice?.unlockForConfiguration()
        } catch {
            NSLog(error.localizedDescription)
        }
        avSession.commitConfiguration()
        self.videoOrientation = videoConnection?.videoOrientation
        //        let avData = AVEngineData(format: format, session: avSession, cameraPosition: currentCameraPosition, fps: self.currentFPS, focus: self.videoDevice!.focusMode, lensPosition: self.videoDevice!.lensPosition, videoOrientation: videoOrientation)
        delegate?.didSwitchCamera(to: currentCameraPosition)
        addVideoDeviceObserver()
        pauseCapturing = false
    }
    
    public func destroy() {
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
        lockQueue.async { [weak self] in
            self?.captureOutputSync(output, didOutput: sampleBuffer, from: connection)
        }
    }
    
    private func captureOutputSync(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if pauseCapturing { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard let port = connection.inputPorts.first else { return }
        delegate?.onSampleBuffer(sampleBuffer,
                                 connection: connection,
                                 timestamp: timestamp,
                                 output: output,
                                 isVideo: port.mediaType == .video)
        
    }
}
