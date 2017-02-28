//
//  TrackingPathGenerating.swift
//  Watchable
//
//  Created by Dan Murrell on 1/25/17.
//  Copyright © 2017 comcast. All rights reserved.
//

import Foundation

@objc protocol TrackingPathGenerating: class {
    func generateTrackingPath() -> String
}
