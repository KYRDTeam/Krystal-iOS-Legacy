//
//  AppErrorTracker.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import Sentry
import Services

class AppErrorTracker: ErrorTracker {
    
    func track(error: NSError) {
        SentrySDK.capture(error: error)
    }
    
}
