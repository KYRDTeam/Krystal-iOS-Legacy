//
//  ErrorTracker.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

public protocol ErrorTracker {
    func track(error: Error)
}
