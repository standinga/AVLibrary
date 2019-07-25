//
//  AVCaptureFocusMode+Description.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

extension AVCaptureDevice.FocusMode: CustomStringConvertible {
    public var description: String {
        let desc: String
        switch self {
        case .locked:
            desc = "locked"
        case .autoFocus:
            desc = "autoFocus"
        case .continuousAutoFocus:
            desc = "continuousAutoFocus"
        default: desc = "unknown"
        }
        return desc
    }
}
