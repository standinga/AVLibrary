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
class AVEngineMockup: NSObject, AVEngineProtocol, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var avSession: AVCaptureSession! = nil
    var availableCameraFormats: [CameraFormat] = AVEngineMockupUtils.formats
    var fps = 30
    weak var delegate: AVEngineDelegate?
    var imageQueue = DispatchQueue(label: "avenginemockup.image.queue")
    var pauseCapturing = false
    var supportsLockedFocus = true
    var isRunning = true
    var cameraIndex: Int = 0
    var format: MockupAVFormat
    var avData: AVEngineData? = nil
    var videoDevice: AVCaptureDevice?
    
    private var timer: Timer?
    private var sampleBuffer: CMSampleBuffer!
    
    var isFocusLocked = false
    var previousTimestamp = CFAbsoluteTimeGetCurrent()
    var startTime = CFAbsoluteTimeGetCurrent() - 0.02

    private var audioConnection: AVCaptureConnection?

    private var audioIn: AVCaptureDeviceInput?
    private var audioOut: AVCaptureAudioDataOutput?
    private var audioCompressionSettings: [AnyHashable : Any]?
    
    let videoQueue: DispatchQueue
    
    let audioQueue = DispatchQueue(label: "mockup audio queue")
    
    init(videoQueue: DispatchQueue) {
        self.videoQueue = videoQueue
        
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
        self.videoQueue = DispatchQueue(label: "mockup self inited")
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
        videoQueue.async {
            let now = CFAbsoluteTimeGetCurrent()
            let delta = now - self.previousTimestamp
            self.startTime += delta
            self.previousTimestamp = now
            let timestamp = CMTime(seconds: self.startTime, preferredTimescale: 1000000000)
            let retimedSampleBuffer = self.retimeSampleBuffer(self.sampleBuffer, timestamp: timestamp)
            
            self.delegate?.onSampleBuffer(retimedSampleBuffer, connection: AVCaptureConnection(inputPorts: [], output: MockupAVCaptureOutput()), timestamp: timestamp, output: MockupAVCaptureOutput(), isVideo: true)
        }
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
    
    func setupAVCapture(_ cameraIndex: Int, fps: Int, savedFormatString: String?, videoOrientation: AVCaptureVideoOrientation) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        } catch {
            print("error", error)
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("error", error)
            return
        }
        let audioDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: nil, position: .unspecified)

        let devices = audioDiscoverySession.devices

        let audioDevice = AVCaptureDevice.default(for: .audio)
        avSession = AVCaptureSession()
        avSession.beginConfiguration()

        initAudioInput(audioDevice: audioDevice, session: self.avSession)
        initAudioOutput(session: self.avSession)
        avSession.commitConfiguration()
        avSession.startRunning()
//        #if os(iOS)
        delegate?.didStartRunning(format: format, session: avSession, avData: AVEngineData(format: format, session: avSession, cameraIndex: cameraIndex, fps: 30, focus: .autoFocus, lensPosition: 1.4, videoOrientation: .portrait)!)
//        #endif
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
            #if os(iOS)
            audioCompressionSettings = audioOut.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov)
            #elseif os(macOS)
            audioCompressionSettings = [:]
            #endif
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
