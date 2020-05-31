//
//  AVEngineData.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

public struct AVEngineData {
    public var format: AVCaptureDevice.Format
    public var session: AVCaptureSession
    public var cameraIndex: Int
    public var fps: Int
    public var focus: AVCaptureDevice.FocusMode
    public var lensPosition: Float
    public var videoOrientation: AVCaptureVideoOrientation
    public var cameraPosition: AVCaptureDevice.Position
}

extension AVEngineData {
    init?(format: AVCaptureDevice.Format?,
          session: AVCaptureSession?,
          cameraIndex: Int?,
          fps: Int?,
          focus: AVCaptureDevice.FocusMode?,
          lensPosition: Float?,
          videoOrientation: AVCaptureVideoOrientation?,
          cameraPosition: AVCaptureDevice.Position = .unspecified) {
        guard let format = format,
            let session = session,
            let cameraIndex = cameraIndex,
            let fps = fps,
            let focus = focus,
            let lensPosition = lensPosition,
            let orientation = videoOrientation else {
                return nil
        }
        self.format = format
        self.session = session
        self.cameraIndex = cameraIndex
        self.fps = fps
        self.focus = focus
        self.lensPosition = lensPosition
        self.videoOrientation = orientation
        self.cameraPosition = cameraPosition
    }
}

extension AVEngineData: CustomStringConvertible {
    public var description: String {
        let desc =
        """
        format: \(format.description),
        fps: \(fps),
        lensPosition: \(lensPosition),
        """
        return desc
    }
}
