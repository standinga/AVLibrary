//
//  MockupAVFormat.swift
//  AVLibrary
//
//  Created by michal on 15/07/2019.
//

import AVFoundation

public class MockupAVFormat: AVCaptureDevice.Format {
    
    var mockFormatDescription: CMFormatDescription!
    
    override public var formatDescription: CMFormatDescription {
        return mockFormatDescription
    }
    public init(_ mocked: Void = ()) { }
}
