//
//  Logger.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/01/2022.
//

import Foundation
import Sentry

func debug(_ message: String, callerFunctionName: String = #function) {
  let crumb = Breadcrumb()
  crumb.level = SentryLevel.debug
  crumb.category = "Debug"
  crumb.message = "\(message) from: \(callerFunctionName)"
  SentrySDK.addBreadcrumb(crumb: crumb)
}

func info(_ message: String, callerFunctionName: String = #function) {
  let crumb = Breadcrumb()
  crumb.level = SentryLevel.error
  crumb.category = "Info"
  crumb.message = "\(message) from: \(callerFunctionName)"
  SentrySDK.addBreadcrumb(crumb: crumb)
}

func error(_ message: String, callerFunctionName: String = #function) {
  let crumb = Breadcrumb()
  crumb.level = SentryLevel.error
  crumb.category = "Error"
  crumb.message = "\(message) from: \(callerFunctionName)"
  SentrySDK.addBreadcrumb(crumb: crumb)
}
