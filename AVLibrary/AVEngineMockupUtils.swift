//
//  AVEngineMockupUtils.swift
//  VideoDelaySwift
//
//  Created by michal on 26/03/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import Foundation

struct AVEngineMockupUtils {
    static let formats = [
        CameraFormat(0, resolution: "190 x 140", format: nil),
        CameraFormat(1, resolution: "640 x 480", format: nil),
    ]
    
    static func createFormatDescription () {
        var desc: CMVideoFormatDescription?
        
        CMFormatDescriptionCreate(allocator: kCFAllocatorDefault, mediaType: kCMMediaType_Video, mediaSubType: FourCharCode(fourChar("avc1")), extensions: nil, formatDescriptionOut: &desc)
        
    }
    
    static func fourChar (_ s: String) -> Int {
        var n: Int = 0
        for UniCodeChar in s.unicodeScalars {
            n = (n << 8) + (Int(UniCodeChar.value) & 255)
        }
        return n
    }
}
