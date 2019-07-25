//
//  AVCaptureDevicePosition+Description.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

extension AVCaptureDevice.Position: CustomStringConvertible {
    public var description: String {
        let desc: String
        
        switch self {
            
        case .unspecified:
            desc = "unspecified"
        case .back:
            desc = "back"
        case .front:
            desc = "front"
        @unknown default:
            fatalError()
        }
        
        return desc
    }
}
