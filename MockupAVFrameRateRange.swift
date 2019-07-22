//
//  MockupAVFrameRateRange.swift
//  AVLibrary
//
//  Created by michal on 21/07/2019.
//

import Foundation

class MockupAVFrameRateRange: AVFrameRateRange {
    
    public init(_ mocked: Void = ()) { }
    
    override var minFrameRate: Float64 {
        return 2
    }
    override var maxFrameRate: Float64 {
        return 60
    }
    override var maxFrameDuration: CMTime {
        return CMTime(seconds: 2, preferredTimescale: 1000000000)
    }
    override var minFrameDuration: CMTime {
        return CMTime(seconds: 0.002, preferredTimescale: 1000000000)
    }
}
