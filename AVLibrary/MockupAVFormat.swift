//
//  MockupAVFormat.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

public class MockupAVFormat: AVCaptureDevice.Format {
    
    var mockFormatDescription: CMFormatDescription!
    public override var videoSupportedFrameRateRanges: [AVFrameRateRange] {
        return [MockupAVFrameRateRange()]
    }
    
    public override var minISO: Float {
        return 100
    }
    public override var maxISO: Float {
        return 6000
    }
    override public var formatDescription: CMFormatDescription {
        return mockFormatDescription
    }
    public init(_ mocked: Void = ()) { }
}
