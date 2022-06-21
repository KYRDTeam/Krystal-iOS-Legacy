// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI
import KrystalWallets

protocol KNSettingsCoordinatorDelegate: class {
  func settingsCoordinatorUserDidSelectExit()
  func settingsCoordinatorUserDidRemoveWallet(_ wallet: KWallet)
  func settingsCoordinatorUserDidRemoveWatchAddress(_ address: KAddress)
  func settingsCoordinatorUserDidSelectRemoveCurrentWallet()
  func settingsCoordinatorUserDidSelectAddWallet(type: AddNewWalletType)
  func settingsCoordinatorDidSelectAddWallet()
  func settingsCoordinatorDidSelectManageWallet()
  func settingsCoordinatorDidImportDeepLinkTokens(srcToken: TokenObject?, destToken: TokenObject?)
  func settingsCoordinatorDidSelectAddChainWallet(chainType: ChainType)
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

  var listWalletsCoordinator: KNListWalletsCoordinator?

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
  
  lazy var customTokenCoordinator: AddTokenCoordinator = {
    let coordinator = AddTokenCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
//  fileprivate var manageAlertCoordinator: KNManageAlertCoordinator?

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
    self.removeObservers()
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
    self.listWalletsCoordinator?.appDidSwitchAddress()
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
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  func openHistoryScreen() {
    switch KNGeneralProvider.shared.currentChain {
    case .solana:
      let coordinator = KNTransactionHistoryCoordinator(navigationController: navigationController, type: .solana)
      coordinator.delegate = self
      coordinate(coordinator: coordinator)
    default:
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController
      )
      self.historyCoordinator?.delegate = self
      self.historyCoordinator?.appDidSwitchAddress()
      self.historyCoordinator?.start()
    }
  }
}

extension KNSettingsCoordinator: KNSettingsTabViewControllerDelegate {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent) {
    switch event {
    case .manageWallet:
      self.settingsViewControllerWalletsButtonPressed()
    case .manageAlerts:
//      if let _ = IEOUserStorage.shared.user {
//        self.manageAlertCoordinator = KNManageAlertCoordinator(navigationController: self.navigationController)
//        self.manageAlertCoordinator?.start()
//      } else {
//        self.navigationController.showWarningTopBannerMessage(
//          with: NSLocalizedString("error", value: "Error", comment: ""),
//          message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
//          time: 1.5
//        )
//      }
    break
    case .alertMethods:
      let coordinator = NotificationCoordinator(navigationController: self.navigationController)
      coordinator.start()
      self.notificationCoordinator = coordinator
    case .contact:
      self.navigationController.pushViewController(self.contactVC, animated: true)
    case .support:
      self.openMailSupport()
    case .about:
      self.openCommunityURL("https://medium.com/kyberswap/get-started-on-kyberswap-ios-app-942ee1dffdc4")
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
    case .github:
      self.openCommunityURL("https://github.com/KyberNetwork/KyberSwap-iOS")
    case .twitter:
      self.openCommunityURL("https://twitter.com/KrystalDefi")
    case .facebook:
      self.openCommunityURL("https://www.facebook.com/kybernetwork")
    case .medium:
      self.openCommunityURL("https://medium.com/krystaldefi")
    case .reddit:
      self.openCommunityURL("https://www.reddit.com/r/kybernetwork")
    case .linkedIn:
      self.openCommunityURL("https://www.linkedin.com/company/kybernetwork")
    case .reportBugs:
      self.navigationController.openSafari(with: "https://goo.gl/forms/ZarhiV7MPE0mqr712")
    case .rateOurApp:
      self.navigationController.openSafari(with: "https://apps.apple.com/us/app/id1558105691")
    case .addCustomToken:
      self.customTokenCoordinator.rootViewController.tokenObject = nil
      self.customTokenCoordinator.start()
    case .manangeCustomToken:
      self.customTokenCoordinator.start(showList: true)
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
    let coordinator = KNListWalletsCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      delegate: self
    )
    coordinator.start()
    self.listWalletsCoordinator = coordinator
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

  func settingsViewControllerBackUpButtonPressed(wallet: KWallet, addressType: KAddressType) {
    let alertController = KNPrettyAlertController(
      title: "Export at your own risk!",
      isWarning: true,
      message: "NEVER share Keystore/Private Key/Mnemonic with anyone (including Krystal). These data grant access to all your funds and they may get stolen".toBeLocalised(),
      secondButtonTitle: NSLocalizedString("continue", value: "Continue", comment: ""),
      firstButtonTitle: NSLocalizedString("cancel", value: "Cancel", comment: ""),
      secondButtonAction: {
        self.selectedWallet = wallet
        self.selectedAddressType = addressType
        self.showAuthPasscode()
      }, firstButtonAction: {
      }
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func showActionSheetBackupPhrase(wallet: KWallet, addressType: KAddressType) {
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      var action = [UIAlertAction]()
      
      switch wallet.importType {
      case .mnemonic:
        action.append(UIAlertAction(
          title: NSLocalizedString("backup.mnemonic", value: "Backup Mnemonic", comment: ""),
          style: .default,
          handler: { _ in
            self.backupMnemonic(wallet: wallet)
          }
        ))
      case .privateKey:
        // TODO: - TUNG - not for solana
        break
      }
      
      action.append(UIAlertAction(
        title: NSLocalizedString("backup.keystore", value: "Backup Keystore", comment: ""),
        style: .default,
        handler: { _ in
          self.backupKeystore(wallet: wallet)
        }
      ))
      action.append(UIAlertAction(
        title: NSLocalizedString("backup.private.key", value: "Backup Private Key", comment: ""),
        style: .default,
        handler: { _ in
          self.backupPrivateKey(wallet: wallet, addressType: addressType)
        }
      ))
      
      guard !action.isEmpty else { return }
      
      action.append(UIAlertAction(
        title: NSLocalizedString("cancel", value: "Cancel", comment: ""),
        style: .cancel,
        handler: nil)
      )
      
      let alertController = KNActionSheetAlertViewController(title: "", actions: action)
      self.navigationController.hideLoading()
      self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
    }
  }

  fileprivate func showAuthPasscode() {
    self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    self.passcodeCoordinator.delegate = self
    self.passcodeCoordinator.start()
  }

  fileprivate func backupKeystore(wallet: KWallet) {
    let createPassword = KNCreatePasswordViewController(wallet: wallet, delegate: self)
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
  }

  fileprivate func backupPrivateKey(wallet: KWallet, addressType: KAddressType) {
    do {
      let privateKey = try WalletManager.shared.exportPrivateKey(walletID: wallet.id, addressType: addressType)
      self.openShowBackUpView(data: privateKey, wallet: wallet)
    } catch {
      self.navigationController.topViewController?.displayError(error: error)
    }
  }

  fileprivate func backupMnemonic(wallet: KWallet) {
    do {
      let mnemonic = try WalletManager.shared.exportMnemonic(walletID: wallet.id)
      self.openShowBackUpView(data: mnemonic, wallet: wallet)
    } catch {
      self.navigationController.topViewController?.displayError(error: error)
    }
  }

  fileprivate func openShowBackUpView(data: String, wallet: KWallet) {
    guard let address = WalletManager.shared.getAllAddresses(walletID: wallet.id).first?.addressString else {
      return
    }
    let showBackUpVC = KNShowBackUpDataViewController(
      address: address,
      backupData: data
    )
    showBackUpVC.loadViewIfNeeded()
    self.navigationController.pushViewController(showBackUpVC, animated: true)
  }
  
  fileprivate func exportDataString(_ value: String, address: KAddress) {
    let fileName = "krystal_backup_\(address.addressString)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
    do {
      try value.data(using: .utf8)!.write(to: url)
    } catch { return }

    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, result, _, error in
      do { try FileManager.default.removeItem(at: url)
      } catch { }
    }
    activityViewController.popoverPresentationController?.sourceView = navigationController.view
    activityViewController.popoverPresentationController?.sourceRect = navigationController.view.centerRect
    self.navigationController.topViewController?.present(activityViewController, animated: true, completion: nil)
  }

  func appCoordinatorPendingTransactionsDidUpdate() {
    self.sendTokenCoordinator?.coordinatorDidUpdatePendingTx()
  }
  
  func appCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.navigationController.popToRootViewController(animated: false)
    self.customTokenCoordinator.start()
    self.customTokenCoordinator.coordinatorDidUpdateTokenObject(token)
  }
  
  func appCoordinatorDidAddTokens(srcToken: TokenObject?, destToken: TokenObject?) {
    self.navigationController.popToRootViewController(animated: false)
    self.customTokenCoordinator.start()
    self.customTokenCoordinator.coordinatorDidUpdateTokensObject(srcToken: srcToken, destToken: destToken)
  }

  func appCoordinatorDidUpdateChain() {
    self.sendTokenCoordinator?.appCoordinatorDidUpdateChain()
  }
  
  func appCoordinatorDidSelectRenameWallet() {
    self.listWalletsCoordinator?.startEditWallet()
  }
  
  func appCoordinatorDidSelectExportWallet() {
    if currentAddress.isWatchWallet {
      return
    }
    guard let wallet = WalletManager.shared.wallet(forAddress: currentAddress) else {
      return
    }
    self.settingsViewControllerBackUpButtonPressed(wallet: wallet, addressType: currentAddress.addressType)
  }
  
  func appCoordinatorDidSelectDeleteWallet() {
    let alert = UIAlertController(title: "", message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cacnel", comment: ""), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: NSLocalizedString("remove", value: "Remove", comment: ""), style: .destructive, handler: { _ in
      self.delegate?.settingsCoordinatorUserDidSelectRemoveCurrentWallet()
    }))
    self.navigationController.present(alert, animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String, wallet: KWallet) {
    do {
      // TODO: Tung - export keystore
//      let key = try WalletManager.shared.exportKeystore(wallet: wallet, password: password)
//      self.exportDataString(key)
    } catch {
      self.navigationController.topViewController?.displayError(error: error)
    }
  }

  func createPasswordDidCancel(sender: KNCreatePasswordViewController) {
    sender.dismiss(animated: true, completion: nil)
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
  func passcodeCoordinatorDidCreatePasscode() {
    self.passcodeCoordinator.stop {
      self.navigationController.showSuccessTopBannerMessage(
        with: Strings.success,
        message: Strings.pinCodeUpdated,
        time: 1.5
      )
    }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    if case .verifyPasscode = self.passcodeCoordinator.type {
      self.passcodeCoordinator.stop {
        if let wallet = self.selectedWallet, let selectedAddressType = self.selectedAddressType {
          self.showActionSheetBackupPhrase(wallet: wallet, addressType: selectedAddressType)
          self.selectedWallet = nil
          self.selectedAddressType = nil
        }
        if let wallet = self.deleteWallet {
          try? WalletManager.shared.remove(wallet: wallet)
          self.delegate?.settingsCoordinatorUserDidRemoveWallet(wallet)
          self.deleteWallet = nil
        }
      }
    } else {
      self.passcodeCoordinator.stop {
        self.passcodeCoordinator = KNPasscodeCoordinator(
          navigationController: self.navigationController,
          type: .setPasscode(cancellable: true)
        )
        self.passcodeCoordinator.delegate = self
        self.passcodeCoordinator.start()
      }
    }
  }

  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop {
      self.selectedWallet = nil
      self.deleteWallet = nil
    }
  }
}

extension KNSettingsCoordinator: KNListWalletsCoordinatorDelegate {
  func listWalletsCoordinatorDidClickBack() {
    self.listWalletsCoordinator?.stop()
    self.listWalletsCoordinator = nil
  }

  func listWalletsCoordinatorDidRemoveWatchAddress(_ address: KAddress) {
    self.delegate?.settingsCoordinatorUserDidRemoveWatchAddress(address)
  }

  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: KWallet) {
    self.deleteWallet = wallet
    self.showAuthPasscode()
  }

  func listWalletsCoordinatorDidSelectAddWallet(type: AddNewWalletType) {
    self.delegate?.settingsCoordinatorUserDidSelectAddWallet(type: type)
  }

  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KWallet, addressType: KAddressType) {
    self.settingsViewControllerBackUpButtonPressed(wallet: wallet, addressType: addressType)
  }
}

extension KNSettingsCoordinator: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.settingsCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func sendTokenCoordinatorDidClose() {
    self.sendTokenCoordinator = nil
  }
  
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.appCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.settingsCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.settingsCoordinatorDidSelectAddWallet()
  }
}

extension KNSettingsCoordinator: AddTokenCoordinatorDelegate {
  func addCoordinatorDidImportDeepLinkTokens(srcToken: TokenObject?, destToken: TokenObject?) {
    self.delegate?.settingsCoordinatorDidImportDeepLinkTokens(srcToken: srcToken, destToken: destToken)
  }
}

extension KNSettingsCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.settingsCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
  
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.appCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidClose() {
    self.historyCoordinator = nil
  }
  
  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.settingsCoordinatorDidSelectManageWallet()
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.settingsCoordinatorDidSelectAddWallet()
  }
}
