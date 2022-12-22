// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import APIKit
import Result
import JSONRPCKit

//protocol Coordinator: class {
//  var coordinators: [Coordinator] { get set }
//  
//  func start()
//}

extension Coordinator {
//
//  func addCoordinator(_ coordinator: Coordinator) {
//    coordinators.append(coordinator)
//  }
//
//  func removeCoordinator(_ coordinator: Coordinator) {
//    coordinators = coordinators.filter { $0 !== coordinator }
//  }
//
//  func removeAllCoordinators() {
//    coordinators.removeAll()
//  }
//
//  func coordinate(coordinator: Coordinator) {
//    addCoordinator(coordinator)
//    coordinator.start()
//  }
  
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
