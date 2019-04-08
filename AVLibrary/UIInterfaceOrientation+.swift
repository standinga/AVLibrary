//
//  UIInterfaceOrientation+.swift
//  VideoReplaySportOfficials
//
//  Created by michal on 25/02/2019.
//  Copyright © 2019 michal. All rights reserved.
//

import UIKit

extension UIInterfaceOrientation {
    var deviceOrientation: UIDeviceOrientation {
        var orientation: UIDeviceOrientation = .portrait
        switch self {
        case .landscapeLeft:
            orientation = .landscapeRight
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portrait:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .portrait
        }
        return orientation
    }
}
