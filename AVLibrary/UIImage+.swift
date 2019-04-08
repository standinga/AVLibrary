//
//  UIImage+.swift
//  VideoReplaySportOfficials
//
//  Created by michal on 05/03/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {
    
    var pixelBuffer: CVPixelBuffer? {
        let cgImage = self.cgImage!
        let options = [kCVPixelBufferCGImageCompatibilityKey : kCFBooleanTrue,
                       kCVPixelBufferCGBitmapContextCompatibilityKey : kCFBooleanTrue
            ] as CFDictionary
        
        let width = cgImage.width
        let height = cgImage.height
        
        var pixelBuffer: CVPixelBuffer?
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, options, &pixelBuffer)
        guard status == 0 else {
            fatalError("can't create CVPixelBuffer status > 0")
        }
        return pixelBuffer
    }
}
