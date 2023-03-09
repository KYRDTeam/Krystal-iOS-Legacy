// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import MessageUI
import KrystalWallets
import AppState
import Dependencies

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: KWallet, chain: ChainType)
  func landingPageCoordinatorStartedBrowsing()
  func landingPageCoordinatorShouldStartSession()
}

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
      if !AppStorage.shared.isAppOpenedBefore {
        self.navigationController.viewControllers = [self.rootViewController]
      }
      return
    }
    
    if !wallets.isEmpty {
      if KNPasscodeUtil.shared.currentPasscode() == nil {
        self.navigationController.viewControllers = [self.rootViewController]
        self.newWallet = wallets.first
        self.passcodeCoordinator.start()
      } else if !AppStorage.shared.isAppOpenedBefore {
        AppStorage.shared.markAppAsOpenedBefore()
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

extension KNLandingPageCoordinator: WelcomeViewControllerDelegate {
    func didTapCreate(controller: UIViewController) {
        self.delegate?.landingPageCoordinatorShouldStartSession()
        Tracker.track(event: .introCreateWallet)
        if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
          self.termViewController.nextAction = {
            
            self.createWallet()
          }
          self.navigationController.present(self.termViewController, animated: true, completion: nil)
          return
        }
        self.createWallet()
    }
    
    func didTapImport(controller: UIViewController) {
        self.delegate?.landingPageCoordinatorShouldStartSession()
        Tracker.track(event: .introImportWallet)
        if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
          self.termViewController.nextAction = {
              self.importAWallet()
          }
          self.navigationController.present(self.termViewController, animated: true, completion: nil)
          return
        }
        importAWallet()
    }
    
    func didTapExplore(controller: UIViewController) {
        if UserDefaults.standard.bool(forKey: Constants.acceptedTermKey) == false {
          self.termViewController.nextAction = {
            self.delegate?.landingPageCoordinatorStartedBrowsing()
            AppStorage.shared.markAppAsOpenedBefore()
          }
          self.navigationController.present(self.termViewController, animated: true, completion: nil)
          return
        }
        self.delegate?.landingPageCoordinatorStartedBrowsing()
    }
    
    fileprivate func createWallet() {
        self.navigationController.displayLoading(text: Strings.creating, animated: true)
        do {
          let wallets = WalletManager.shared.getAllWallets()
          let wallet = try self.walletManager.createWallet(name: "Wallet \(wallets.count + 1)")
          DispatchQueue.main.async {
              self.navigationController.hideLoading()
              let viewModel = FinishImportViewModel(wallet: wallet)
              let finishVC = FinishImportViewController(viewModel: viewModel)
              self.navigationController.show(finishVC, sender: nil)
          }
        } catch {
          return
        }
    }
    
    fileprivate func importAWallet() {
        let importVC = ImportWalletViewController.instantiateFromNib()
        self.navigationController.pushViewController(importVC, animated: true)
    }
}

extension KNLandingPageCoordinator: KNLandingPageViewControllerDelegate {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent) {
    switch event {
    case .getStarted:
        let vc = WelcomeViewController.instantiateFromNib()
        vc.delegate = self
        self.rootViewController.show(vc, sender: nil)
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
  
  func openCreateWallet() {
    let coordinator = KNCreateWalletCoordinator(navigationController: self.navigationController, newWallet: nil, name: nil)
    coordinate(coordinator: coordinator)
  }
}

extension KNLandingPageCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
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

  func createWalletCoordinatorDidClose(coordinator: KNCreateWalletCoordinator) {
    removeCoordinator(coordinator)
  }

  func createWalletCoordinatorDidCreateWallet(coordinator: KNCreateWalletCoordinator, _ wallet: KWallet?, name: String?, chain: ChainType) {
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
