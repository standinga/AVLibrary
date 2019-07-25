//
//  AVCaptureVideoOrientation+Description.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

extension AVCaptureVideoOrientation: CustomStringConvertible {
    public var description: String {
        let desc: String
        switch self {
        case .portrait:
            desc = "portrait"
        case .portraitUpsideDown:
            desc = "portraitUpsideDown"
        case .landscapeRight:
            desc = "landscapeRight"
        case .landscapeLeft:
            desc = "landscapeLeft"
        @unknown default:
            fatalError()
        }
        return desc
    }
}
