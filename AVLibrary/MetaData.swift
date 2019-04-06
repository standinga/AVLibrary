//
//  MetaData.swift
//  PrerecordCamera
//
//  Created by michal on 05/01/2018.
//  Copyright © 2018 borama. All rights reserved.
//

import Foundation
import AVFoundation

struct MetaData {
    
    var videoFormatDescription: CMFormatDescription?
    var timestamp: CMTime?
    
    init (videoFormatDescription: CMFormatDescription?, timestamp: CMTime?) {
        self.videoFormatDescription = videoFormatDescription
        self.timestamp = timestamp
    }
}
