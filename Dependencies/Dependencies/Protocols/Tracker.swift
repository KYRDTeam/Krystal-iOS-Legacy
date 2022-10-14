//
//  TrackingDelegate.swift
//  Dependencies
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation

public protocol Tracker {
    func track(_ eventName: String, properties: [String: Any])
}
