// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

protocol KNPasscodeCoordinatorDelegate: class {
  func passcodeCoordinatorDidCancel()
  func passcodeCoordinatorDidEvaluatePIN()
  func passcodeCoordinatorDidCreatePasscode()
}

class KNPasscodeCoordinator: Coordinator {
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let window: UIWindow = UIWindow()
  let type: KNPasscodeViewType
  
  weak var delegate: KNPasscodeCoordinatorDelegate?
  
  lazy var passcodeViewController: KNPasscodeViewController = {
    let controller = KNPasscodeViewController(viewType: self.type, delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()
  
  init(
    navigationController: UINavigationController = UINavigationController(),
    type: KNPasscodeViewType
  ) {
    self.navigationController = navigationController
    self.type = type
    if case .authenticate(let isUpdating) = self.type, !isUpdating {
      self.window.windowLevel = UIWindow.Level.statusBar + 1.0
      self.window.rootViewController = self.passcodeViewController
      self.window.isHidden = true
    }
  }
  
  func start() {
    let wallets = WalletManager.shared.getAllWallets()
    if wallets.isEmpty || KNPasscodeUtil.shared.currentPasscode() == nil, case .authenticate = self.type {
      if AppDelegate.shared.coordinator.tabbarController != nil {
        AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = false
      }
      return
    }
    self.passcodeViewController.resetUI()
    if case .authenticate(let isUpdating) = self.type {
      if isUpdating {
        self.navigationController.present(self.passcodeViewController, animated: true, completion: nil)
      } else {
        self.window.makeKeyAndVisible()
        self.window.isHidden = false
        DispatchQueue.main.async {
          self.passcodeViewController.showBioAuthenticationIfNeeded()
        }
      }
    } else if case .setPasscode(let cancellable) = self.type {
      if cancellable {
        self.navigationController.present(self.passcodeViewController, animated: true, completion: nil)
      } else {
        self.navigationController.pushViewController(self.passcodeViewController, animated: true)
      }
    } else if case .verifyPasscode = self.type {
      DispatchQueue.main.async {
        self.navigationController.present(self.passcodeViewController, animated: true, completion: nil)
      }
    }
  }
  
  func stop(completion: @escaping () -> Void) {
    DispatchQueue.main.async {
      if case .authenticate(let isUpdating) = self.type {
        if isUpdating {
          self.navigationController.dismiss(animated: true, completion: completion)
        } else {
          self.window.isHidden = true
          completion()
        }
      } else if case .setPasscode(let cancellable) = self.type {
        if cancellable {
          self.navigationController.dismiss(animated: true, completion: completion)
        } else {
          self.navigationController.popViewController(animated: true, completion: completion)
        }
      } else if case .verifyPasscode = self.type {
        self.navigationController.dismiss(animated: true, completion: completion)
      }
    }
  }
}

extension KNPasscodeCoordinator: KNPasscodeViewControllerDelegate {
  func passcodeViewController(_ controller: KNPasscodeViewController, run event: KNPasscodeViewEvent) {
    switch event {
    case .cancel:
      self.delegate?.passcodeCoordinatorDidCancel()
    case .evaluatedPolicyWithBio:
      self.didFinishEvaluatingWithBio()
    case .enterPasscode(let passcode):
      self.didFinishEnterPasscode(passcode)
    case .createNewPasscode(let passcode):
      self.didCreateNewPasscode(passcode)
    }
  }
  
  fileprivate func didFinishEvaluatingWithBio() {
    KNPasscodeUtil.shared.deleteNumberAttempts()
    KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
    KNAppTracker.saveLastTimeAuthenticate()
    self.delegate?.passcodeCoordinatorDidEvaluatePIN()
    if AppDelegate.shared.coordinator.tabbarController != nil {
      AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = false
    }
  }
  
  fileprivate func didFinishEnterPasscode(_ passcode: String) {
    guard let currentPasscode = KNPasscodeUtil.shared.currentPasscode() else {
      self.stop {}
      return
    }
    if currentPasscode == passcode {
      KNPasscodeUtil.shared.deleteNumberAttempts()
      KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
      KNAppTracker.saveLastTimeAuthenticate()
      self.delegate?.passcodeCoordinatorDidEvaluatePIN()
    } else {
      KNPasscodeUtil.shared.recordNewAttempt()
      if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
        KNPasscodeUtil.shared.recordNewMaxAttemptTime()
      }
      self.passcodeViewController.userDidTypeWrongPasscode()
    }
    if AppDelegate.shared.coordinator.tabbarController != nil {
      AppDelegate.shared.coordinator.tabbarController.tabBar.isHidden = false
    }
  }
  
  fileprivate func didCreateNewPasscode(_ passcode: String) {
    KNPasscodeUtil.shared.setNewPasscode(passcode)
    UserDefaults.standard.set(true, forKey: Constants.isCreatedPassCode)
    self.delegate?.passcodeCoordinatorDidCreatePasscode()
  }
}
