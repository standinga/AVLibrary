//
//  CameraFormat.swift
//  PrerecordCamera
//
//  Created by michal on 05/01/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import Foundation
import AVFoundation

public struct CameraFormat {
    public let index: Int
    public let resolution: String
    public var format: AVCaptureDevice.Format?
    public var currentFormat: AVCaptureDevice.Format?
    var formatDescriptionHash = -1
    
    public init(_ index: Int, resolution: String, format: AVCaptureDevice.Format?) {
        self.index = index
        self.resolution = resolution
        self.format = format
        if (format != nil) {
            self.formatDescriptionHash = format!.formatDescription.hashValue
        }
    }
}
