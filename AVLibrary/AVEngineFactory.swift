//
//  AVEngineFactory.swift
//  VideoReplaySportOfficials
//
//  Created by michal on 05/03/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import Foundation


public struct AVEngineFactory {
    public static func createAVEngine(videoQueue: DispatchQueue, audioQueue: DispatchQueue, mockup: Bool = false) -> AVEngineProtocol {
        if mockup {
            return AVEngineMockup(videoQueue: audioQueue)
        }
        #if targetEnvironment(simulator)
        return  AVEngineMockup(videoQueue: audioQueue)
        #else
        return AVEngine(videoQueue: videoQueue, audioQueue: audioQueue)
        #endif
    }
}
