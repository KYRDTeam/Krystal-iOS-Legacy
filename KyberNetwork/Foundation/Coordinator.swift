// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import APIKit
import Result
import JSONRPCKit

extension Coordinator {
  
  func showErrorMessage(_ error: AnyError, viewController: UIViewController) {
    var errorMessage = error.description
    if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
      errorMessage = apiKitError.localizedDescription
      if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
        errorMessage = message
      }
    }
    viewController.showErrorTopBannerMessage(
      with: "Error",
      message: errorMessage,
      time: 1.5
    )
  }
}
