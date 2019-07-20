//
//  AVEngineFactory.swift
//  VideoReplaySportOfficials
//
//  Created by michal on 05/03/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import Foundation


public struct AVEngineFactory {
    public static func createAVEngine(lockingQueue: DispatchQueue, mockup: Bool = false) -> AVEngineProtocol {
        if mockup {
            return AVEngineMockup(lockingQueue: lockingQueue)
        }
        #if targetEnvironment(simulator)
        return  AVEngineMockup(lockingQueue: lockingQueue)
        #else
        return AVEngine(withLockingQueue: lockingQueue)
        #endif
    }
}
