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
    public var cameraPosition: AVCaptureDevice.Position
    public var fps: Int
    public var focus: AVCaptureDevice.FocusMode
    public var lensPosition: Float
    public var videoOrientation: AVCaptureVideoOrientation
}

extension AVEngineData {
    init?(format: AVCaptureDevice.Format?, session: AVCaptureSession?,
          cameraPosition: AVCaptureDevice.Position?, fps: Int?,
          focus: AVCaptureDevice.FocusMode?, lensPosition: Float?, videoOrientation: AVCaptureVideoOrientation?) {
        guard let format = format,
            let session = session,
            let cameraPosition = cameraPosition,
            let fps = fps,
            let focus = focus,
            let lensPosition = lensPosition,
            let orientation = videoOrientation else {
                return nil
        }
        self.format = format
        self.session = session
        self.cameraPosition = cameraPosition
        self.fps = fps
        self.focus = focus
        self.lensPosition = lensPosition
        self.videoOrientation = orientation
    }
}

extension AVEngineData: CustomStringConvertible {
    public var description: String {
        let desc =
        """
        format: \(format.description),
        position: \(cameraPosition.description),
        fps: \(fps),
        focus: \(focus.description),
        lensPosition: \(lensPosition),
        videoOrientation: \(videoOrientation.description)
        """
        return desc
    }
}
