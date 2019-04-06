//
//  AVEngineFactory.swift
//  VideoReplaySportOfficials
//
//  Created by michal on 05/03/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import Foundation


struct AFEngineFactory {
    static func createAVEngine(lockingQueue: DispatchQueue) -> AVEngineProtocol {
#if targetEnvironment(simulator)
        return  AVEngineMockup(lockingQueue: lockingQueue)
#else
        return AVEngine(withLockingQueue: lockingQueue)
#endif
    }
}
