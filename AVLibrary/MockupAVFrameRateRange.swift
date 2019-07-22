//
//  MockupAVFrameRateRange.swift
//  AVLibrary
//
//  Created by michal on 22/07/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import AVFoundation

class MockupAVFrameRateRange: AVFrameRateRange {
    
    override var minFrameRate: Float64 {
        return 2
    }
    
    override var maxFrameRate: Float64 {
        return 60
    }
    
    public init(mockup: Void = ()) { }
}
