// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI
import KrystalWallets
import Dependencies

protocol KNSettingsCoordinatorDelegate: class {
  func settingsCoordinatorUserDidSelectExit()
}

class KNSettingsCoordinator: NSObject, Coordinator {

  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  private(set) var session: KNSession
  fileprivate(set) var balances: [String: Balance] = [:]
  
  var historyCoordinator: KNHistoryCoordinator?
  weak var delegate: KNSettingsCoordinatorDelegate?
  var notificationCoordinator: NotificationCoordinator?
  
  var deleteWallet: KWallet?
  var selectedWallet: KWallet?
  var selectedAddressType: KAddressType?
  
  lazy var rootViewController: KNSettingsTabViewController = {
    let controller = KNSettingsTabViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var contactVC: KNListContactViewController = {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode(cancellable: true)
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.observeAppEvents()
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
  }

  func removeObservers() {
    NotificationCenter.default.removeObserver(
      self,
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  func observeAppEvents() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  @objc func appDidSwitchAddress() {
//    self.listWalletsCoordinator?.appDidSwitchAddress()
    self.rootViewController.coordinatorAppSwitchAddress()
  }

  func appCoordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: balances)
  }

  func appCoordinatorUSDRateUpdate() {
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    return self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx) ?? false
  }
  
  func openHistoryScreen() {
      AppDependencies.router.openTransactionHistory()
  }
  
  func openWalletList() {
    let coordinator = KNListWalletsCoordinator(navigationController: navigationController)
    coordinator.onCompleted = { [weak self] in
      self?.removeCoordinator(coordinator)
    }
    coordinate(coordinator: coordinator)
  }
}

extension KNSettingsCoordinator: KNSettingsTabViewControllerDelegate {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent) {
    switch event {
    case .manageWallet:
      self.openWalletList()
    case .contact:
      self.navigationController.pushViewController(self.contactVC, animated: true)
    case .support:
      self.openMailSupport()
    case .changePIN:
      self.passcodeCoordinator = KNPasscodeCoordinator(
        navigationController: self.navigationController,
        type: .authenticate(isUpdating: true)
      )
      self.passcodeCoordinator.delegate = self
      self.passcodeCoordinator.start()
    case .community:
      let url = "https://docs.krystal.app/"
      self.openCommunityURL(url)
    case .shareWithFriends:
      self.openShareWithFriends()
    case .telegram:
      self.openCommunityURL("https://t.me/KrystalDefi")
    case .twitter:
      self.openCommunityURL("https://twitter.com/KrystalDefi")
    case .medium:
      self.openCommunityURL("https://medium.com/krystaldefi")
    case .reddit:
      self.openCommunityURL("https://www.reddit.com/r/kybernetwork")
    case .rateOurApp:
      self.navigationController.openSafari(with: "https://apps.apple.com/us/app/id1558105691")
    case .termOfUse:
      self.navigationController.openSafari(with: "https://files.krystal.app/terms.pdf")
    case .privacyPolicy:
      self.navigationController.openSafari(with: "https://files.krystal.app/privacy.pdf")
    case .fingerPrint(status: let status):
      UserDefaults.standard.setValue(status, forKey: "bio-auth")
    case .refPolicy:
      self.navigationController.openSafari(with: "https://files.krystal.app/referral.pdf")
    }
  }

  fileprivate func openCommunityURL(_ url: String) {
    self.navigationController.openSafari(with: url)
  }

  fileprivate func openShareWithFriends() {
    let text = NSLocalizedString(
      "share.with.friends.text",
      value: "I just found an awesome wallet app. Check out here https://apps.apple.com/us/app/id1558105691",
      comment: ""
    )
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.rootViewController.shareWithFriendsButton
    self.navigationController.present(activitiy, animated: true, completion: nil)
  }

  func settingsViewControllerDidClickExit() {
    self.delegate?.settingsCoordinatorUserDidSelectExit()
  }
  
  func settingsViewControllerWalletsButtonPressed() {
    openWalletList()
  }

  func settingsViewControllerPasscodeDidChange(_ isOn: Bool) {
    if isOn {
      self.passcodeCoordinator.start()
    } else {
      KNPasscodeUtil.shared.deletePasscode()
    }
  }

  func openMailSupport() {
    if MFMailComposeViewController.canSendMail() {
      let emailVC = MFMailComposeViewController()
      emailVC.mailComposeDelegate = self
      emailVC.setToRecipients(["support@krystal.app"])
      self.navigationController.present(emailVC, animated: true, completion: nil)
    } else {
      let message = NSLocalizedString(
        "please.send.your.request.to.support",
        value: "Please send your request to support@krystal.app",
        comment: ""
      )
      self.navigationController.showWarningTopBannerMessage(with: "", message: message, time: 1.5)
    }
  }

  func settingsViewControllerOpenDebug() {
    let debugVC = KNDebugMenuViewController()
    self.navigationController.present(debugVC, animated: true, completion: nil)
  }

  fileprivate func showAuthPasscode() {
    self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    self.passcodeCoordinator.delegate = self
    self.passcodeCoordinator.start()
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.sendTokenCoordinator?.coordinatorDidUpdatePendingTx()
  }
  
  func appCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.navigationController.popToRootViewController(animated: false)
  }
  
  func appCoordinatorDidAddTokens(srcToken: TokenObject?, destToken: TokenObject?) {
    self.navigationController.popToRootViewController(animated: false)
  }
}

extension KNSettingsCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .send(let address):
      self.openSendToken(address: address)
    case .select(let contact):
      self.openNewContact(address: contact.address, ens: nil)
    }
  }

  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel = KNNewContactViewModel(address: address, ens: ens)
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }

  fileprivate func openSendToken(address: String) {
    let from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      balances: self.balances,
      from: from
    )
    self.sendTokenCoordinator?.delegate = self
    self.sendTokenCoordinator?.start()
    self.sendTokenCoordinator?.coordinatorOpenSendView(to: address)
  }
}

extension KNSettingsCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    switch event {
    case .dismiss: self.navigationController.popViewController(animated: true)
    case .send(let address):
      self.openSendToken(address: address)
    }
  }
}

extension KNSettingsCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop {
      self.navigationController.showSuccessTopBannerMessage(
        with: Strings.success,
        message: Strings.pinCodeUpdated,
        time: 1.5
      )
    }
  }

  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop {
      self.passcodeCoordinator = KNPasscodeCoordinator(
        navigationController: self.navigationController,
        type: .setPasscode(cancellable: true)
      )
      self.passcodeCoordinator.delegate = self
      self.passcodeCoordinator.start()
    }
  }

  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator.stop {
      self.selectedWallet = nil
      self.deleteWallet = nil
    }
  }
}

extension KNSettingsCoordinator: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNSendTokenViewCoordinatorDelegate {
  
  func sendTokenCoordinatorDidClose(coordinator: KNSendTokenViewCoordinator) {
    self.sendTokenCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.appCoordinatorDidSelectAddToken(token)
  }
}

extension KNSettingsCoordinator: KNHistoryCoordinatorDelegate {

  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.appCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
  
}
