// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import MessageUI
import KrystalWallets

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: KWallet, chain: ChainType)
  func landingPageCoordinator(add watchAddress: KAddress, chain: ChainType)
  func landingPageCoordinatorDidSendRefCode(_ code: String)
  func landingPageCoordinatorStartedBrowsing()
}

/**
 Flow:
 1. Create Wallet:
  - Enter password
  - Backup 12 words seed for new wallet
  - Testing backup
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 2. Import Wallet:
  - JSON/Private Key/Seeds
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 */
class KNLandingPageCoordinator: NSObject, Coordinator {

  weak var delegate: KNLandingPageCoordinatorDelegate?
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []

  private var newWallet: KWallet?
  private var targetChain: ChainType?
  fileprivate var isCreate: Bool = false
  let walletManager = WalletManager.shared

  lazy var rootViewController: KNLandingPageViewController = {
    let controller = KNLandingPageViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      newWallet: self.newWallet,
      name: nil
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    return coordinator
  }()

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode(cancellable: false)
    )
    coordinator.delegate = self
    return coordinator
  }()
  
  lazy var termViewController: TermsAndConditionsViewController = {
    let controller = TermsAndConditionsViewController()
    return controller
  }()
  
  init(
    navigationController: UINavigationController = UINavigationController()
  ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    let wallets = walletManager.getAllWallets()
    if wallets.isEmpty && KNPasscodeUtil.shared.currentPasscode() != nil {
      self.navigationController.viewControllers = [self.rootViewController]
    }
    
    if !wallets.isEmpty {
      if KNPasscodeUtil.shared.currentPasscode() == nil {
        self.navigationController.viewControllers = [self.rootViewController]
        self.newWallet = wallets.first
        self.passcodeCoordinator.start()
      }
    } else {
      self.navigationController.viewControllers = [self.rootViewController]
    }
  }

  func updateNewWallet(wallet: KWallet) {
    self.newWallet = wallet
  }
  
  func didImportWallet(wallet: KWallet, chain: ChainType) {
    self.newWallet = wallet
    self.targetChain = chain
    
    // Check if first wallet
    if WalletManager.shared.getAllWallets().count == 1 {
      KNPasscodeUtil.shared.deletePasscode()
      self.passcodeCoordinator.start()
    } else {
      self.delegate?.landingPageCoordinator(import: wallet, chain: chain)
    }
  }

  func resetNavigationToRoot() {
    navigationController.popToRootViewController(animated: true)
    navigationController.viewControllers = [self.rootViewController]
  }
  
}

extension KNLandingPageCoordinator: KNLandingPageViewControllerDelegate {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent) {
    switch event {
    case .getStarted:
      if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
        self.termViewController.nextAction = {
          self.delegate?.landingPageCoordinatorStartedBrowsing()
        }
        self.navigationController.present(self.termViewController, animated: true, completion: nil)
        return
      }
      self.delegate?.landingPageCoordinatorStartedBrowsing()
    case .openCreateWallet:
      Tracker.track(event: .introCreateWallet)
      if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
        self.termViewController.nextAction = {
          self.createWalletCoordinator.updateNewWallet(nil, name: nil)
          self.createWalletCoordinator.start()
        }
        self.navigationController.present(self.termViewController, animated: true, completion: nil)
        return
      }
      self.createWalletCoordinator.updateNewWallet(nil, name: nil)
      self.createWalletCoordinator.start()
    case .openImportWallet:
      Tracker.track(event: .introImportWallet)
      if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
        self.termViewController.nextAction = {
          self.importWalletCoordinator.start()
        }
        self.navigationController.present(self.termViewController, animated: true, completion: nil)
        return
      }
      self.importWalletCoordinator.start()
    case .openTermAndCondition:
      let url: String = "https://files.krystal.app/terms.pdf"
      self.navigationController.topViewController?.openSafari(with: url)
    case .openMigrationAlert:
      self.openMigrationAlert()
    }
  }

  fileprivate func openMigrationAlert() {
    let alert = KNPrettyAlertController(
      title: "Information".toBeLocalised(),
      message: "Have you installed the old KyberSwap iOS app? Read our guide on how to migrate your wallets from old app to this new app.".toBeLocalised(),
      secondButtonTitle: "OK".toBeLocalised(),
      firstButtonTitle: "No".toBeLocalised(),
      secondButtonAction: {
        self.navigationController.dismiss(animated: true) {
          let viewModel = KNMigrationTutorialViewModel()
          let tutorialVC = KNMigrationTutorialViewController(viewModel: viewModel)
          tutorialVC.delegate = self
          self.navigationController.present(tutorialVC, animated: true, completion: nil)
        }
      },
      firstButtonAction: {
      }
    )
    self.navigationController.present(alert, animated: true, completion: nil)
  }
}

extension KNLandingPageCoordinator: KNImportWalletCoordinatorDelegate {
  
  func importWalletCoordinatorDidImport(watchAddress: KAddress, chain: ChainType) {
    delegate?.landingPageCoordinator(add: watchAddress, chain: chain)
  }
  
  func importWalletCoordinatorDidImport(wallet: KWallet, chain: ChainType) {
    didImportWallet(wallet: wallet, chain: chain)
  }
  
  func importWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.landingPageCoordinatorDidSendRefCode(code.uppercased())
  }

  func importWalletCoordinatorDidClose() {
  }
}

extension KNLandingPageCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode() {
    guard let wallet = self.newWallet else {
      return
    }
    guard let address = walletManager.address(forWalletID: wallet.id) else {
      return
    }
    guard let chain = ChainType.allCases.first(where: { $0.addressType == address.addressType }) else {
      return
    }
    self.delegate?.landingPageCoordinator(import: wallet, chain: self.targetChain ?? chain)
  }
}

extension KNLandingPageCoordinator: KNCreateWalletCoordinatorDelegate {

  func createWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.landingPageCoordinatorDidSendRefCode(code.uppercased())
  }
  
  func createWalletCoordinatorDidClose() {
  }

  func createWalletCoordinatorDidCreateWallet(_ wallet: KWallet?, name: String?, chain: ChainType) {
    guard let wallet = wallet else { return }
    didImportWallet(wallet: wallet, chain: chain)
  }
}

extension KNLandingPageCoordinator: KNMigrationTutorialViewControllerDelegate {
  func kMigrationTutorialViewControllerDidClickKyberSupportContact(_ controller: KNMigrationTutorialViewController) {
    if MFMailComposeViewController.canSendMail() {
      let emailVC = MFMailComposeViewController()
      emailVC.mailComposeDelegate = self
      emailVC.setToRecipients(["support@kyberswap.com"])
      self.navigationController.present(emailVC, animated: true, completion: nil)
    } else {
      let message = NSLocalizedString(
        "please.send.your.request.to.support",
        value: "Please send your request to support@kyberswap.com",
        comment: ""
      )
      self.navigationController.showWarningTopBannerMessage(with: "", message: message, time: 1.5)
    }
  }
}

extension KNLandingPageCoordinator: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
  }
}
