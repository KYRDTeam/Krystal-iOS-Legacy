//
//  ErrorTracker.swift
//  Services
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation

public protocol ErrorTracker {
    func track(error: NSError)
}
