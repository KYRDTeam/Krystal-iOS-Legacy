//
//  AppTracker.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import Dependencies
import Mixpanel

class AppTracker: TrackerProtocol {
    
    func track(_ eventName: String, properties: [String: Any]) {
        MixPanelManager.track(eventName, properties: properties as? Properties)
    }
    
}
