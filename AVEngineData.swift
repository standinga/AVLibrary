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
