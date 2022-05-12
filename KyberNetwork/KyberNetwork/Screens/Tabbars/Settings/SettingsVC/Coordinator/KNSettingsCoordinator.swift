// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI

protocol KNSettingsCoordinatorDelegate: class {
  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidSelectExit()
  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidUpdateWalletObjects()
  func settingsCoordinatorUserDidSelectAddWallet(type: AddNewWalletType)
  func settingsCoordinatorDidSelectAddWallet()
  func settingsCoordinatorDidSelectWallet(_ wallet: Wallet)
  func settingsCoordinatorDidSelectManageWallet()
  func settingsCoordinatorDidImportDeepLinkTokens(srcToken: TokenObject?, destToken: TokenObject?)
  func settingsCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class KNSettingsCoordinator: NSObject, Coordinator {

  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  private(set) var session: KNSession
  fileprivate(set) var balances: [String: Balance] = [:]
  var selectedWallet: KNWalletObject?
  var historyCoordinator: KNHistoryCoordinator?
  weak var delegate: KNSettingsCoordinatorDelegate?
  var notificationCoordinator: NotificationCoordinator?

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
    let coordinator = AddTokenCoordinator(navigationController: self.navigationController, session: self.session)
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
//  fileprivate var manageAlertCoordinator: KNManageAlertCoordinator?

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    if resetRoot {
      self.navigationController.popToRootViewController(animated: true)
    }
    self.listWalletsCoordinator?.updateNewSession(self.session)
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
      let coordinator = KNTransactionHistoryCoordinator(navigationController: navigationController, session: session, type: .solana)
      coordinator.delegate = self
      coordinate(coordinator: coordinator)
    default:
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController,
        session: self.session
      )
      self.historyCoordinator?.delegate = self
      self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
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

  func settingsViewControllerBackUpButtonPressed(wallet: KNWalletObject) {
    let alertController = KNPrettyAlertController(
      title: "Export at your own risk!",
      isWarning: true,
      message: "NEVER share Keystore/Private Key/Mnemonic with anyone (including Krystal). These data grant access to all your funds and they may get stolen".toBeLocalised(),
      secondButtonTitle: NSLocalizedString("continue", value: "Continue", comment: ""),
      firstButtonTitle: NSLocalizedString("cancel", value: "Cancel", comment: ""),
      secondButtonAction: {
        self.selectedWallet = wallet
        self.showAuthPasscode()
      }, firstButtonAction: {
      }
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func showActionSheetBackupPhrase(walletObj: KNWalletObject) {
    var wallet: Wallet?
    
    if walletObj.chainType == 2 {
      wallet = Wallet(type: .solana(walletObj.address, walletObj.evmAddress, walletObj.walletID))
    } else {
      wallet = self.session.keystore.wallets.first(where: { $0.addressString.lowercased() == walletObj.address.lowercased() })
    }
  
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      var action = [UIAlertAction]()
      if let unwrap = wallet {
        if !unwrap.isSolanaWallet {
          action.append(UIAlertAction(
            title: NSLocalizedString("backup.keystore", value: "Backup Keystore", comment: ""),
            style: .default,
            handler: { _ in
              self.backupKeystore(wallet: unwrap)
            }
          ))
        }
        
        action.append(UIAlertAction(
          title: NSLocalizedString("backup.private.key", value: "Backup Private Key", comment: ""),
          style: .default,
          handler: { _ in
            self.backupPrivateKey(wallet: unwrap)
            self.saveBackedUpWallet(wallet: unwrap, name: walletObj.name)
          }
        ))
        
        if case .real(let account) = unwrap.type, case .success = self.session.keystore.exportMnemonics(account: account) {
          action.append(UIAlertAction(
            title: NSLocalizedString("backup.mnemonic", value: "Backup Mnemonic", comment: ""),
            style: .default,
            handler: { _ in
              self.backupMnemonic(wallet: unwrap)
              self.saveBackedUpWallet(wallet: unwrap, name: walletObj.name)
            }
          ))
        } else if case .solana(_, let evmAddress, _) = unwrap.type, let account = self.session.keystore.matchWithEvmAccount(address: evmAddress), case .success = self.session.keystore.exportMnemonics(account: account) {
          action.append(UIAlertAction(
            title: NSLocalizedString("backup.mnemonic", value: "Backup Mnemonic", comment: ""),
            style: .default,
            handler: { _ in
              let seedsWallet = Wallet(type: .real(account))
              self.backupMnemonic(wallet: seedsWallet)
              self.saveBackedUpWallet(wallet: seedsWallet, name: walletObj.name)
            }
          ))
        }
      }
      
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

  fileprivate func saveBackedUpWallet(wallet: Wallet, name: String) {
    let walletObject = self.selectedWallet?.clone()
    walletObject?.name = name
    if let unwrap = walletObject {
      KNWalletStorage.shared.add(wallets: [unwrap])
    }
    
  }

  fileprivate func showAuthPasscode() {
    self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    self.passcodeCoordinator.delegate = self
    self.passcodeCoordinator.start()
  }

  fileprivate func backupKeystore(wallet: Wallet) {
    let createPassword = KNCreatePasswordViewController(wallet: wallet, delegate: self)
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
  }

  fileprivate func backupPrivateKey(wallet: Wallet) {
    if case .solana(let address, let evmAddress, let walletID) = wallet.type {
      if !walletID.isEmpty {
        guard let pk = self.session.keystore.solanaUtil.exportKeyPair(walletID: walletID) else { return }
        let keypair = SolanaUtil.exportKeyPair(privateKey: pk)
        self.openShowBackUpView(data: keypair, wallet: wallet)
      } else {
        guard let account = self.session.keystore.matchWithEvmAccount(address: evmAddress) else { return }
        let seedResult = self.session.keystore.exportMnemonics(account: account)
        guard case .success(let mnemonics) = seedResult else { return }
        let privateKey = SolanaUtil.seedsToKeyPair(mnemonics)
        self.openShowBackUpView(data: privateKey, wallet: wallet)
      }
      
    } else {
      self.navigationController.displayLoading()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
        if case .real(let account) = wallet.type {
          let result = self.session.keystore.exportPrivateKey(account: account)
          self.navigationController.hideLoading()
          switch result {
          case .success(let data):
            self.openShowBackUpView(data: data.hexString, wallet: wallet)
          case .failure(let error):
            self.navigationController.topViewController?.displayError(error: error)
          }
        } else {
          self.navigationController.hideLoading()
        }
      }
    }
    
    
  }

  fileprivate func backupMnemonic(wallet: Wallet) {
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      if case .real(let account) = wallet.type {
        let result = self.session.keystore.exportMnemonics(account: account)
        self.navigationController.hideLoading()
        switch result {
        case .success(let data):
          self.openShowBackUpView(data: data, wallet: wallet)
        case .failure(let error):
          self.navigationController.topViewController?.displayError(error: error)
        }
      } else {
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func openShowBackUpView(data: String, wallet: Wallet) {
    let showBackUpVC = KNShowBackUpDataViewController(
      wallet: wallet.addressString,
      backupData: data
    )
    showBackUpVC.loadViewIfNeeded()
    self.navigationController.pushViewController(showBackUpVC, animated: true)
  }

  fileprivate func copyAddress(wallet: Wallet) {
    UIPasteboard.general.string = wallet.addressString
  }

  fileprivate func exportDataString(_ value: String, wallet: Wallet) {
    let fileName = "krystal_backup_\(wallet.addressString)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
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
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.availableWalletObjects
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.addressString.lowercased() })!
    self.settingsViewControllerBackUpButtonPressed(wallet: curWallet)
  }
  
  func appCoordinatorDidSelectDeleteWallet() {
    let alert = UIAlertController(title: "", message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cacnel", comment: ""), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: NSLocalizedString("remove", value: "Remove", comment: ""), style: .destructive, handler: { _ in
      self.delegate?.settingsCoordinatorUserDidRemoveWallet(self.session.wallet)
    }))
    self.navigationController.present(alert, animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String, wallet: Wallet) {
    if case .real(let account) = wallet.type {
      var name = "New Wallet"
      if let walletObject = KNWalletStorage.shared.wallets.first(where: { (item) -> Bool in
        return item.address.lowercased() == wallet.addressString.lowercased()
      }) {
        name = walletObject.name
      }
      self.saveBackedUpWallet(wallet: wallet, name: name)
      if let currentPassword = self.session.keystore.getPassword(for: account) {
        self.navigationController.topViewController?.displayLoading(text: "\(NSLocalizedString("preparing.data", value: "Preparing data", comment: ""))...", animated: true)
        self.session.keystore.export(account: account, password: currentPassword, newPassword: password, importType: .multiChain, completion: { [weak self] result in //NOTE: remove later
          self?.navigationController.topViewController?.hideLoading()
          switch result {
          case .success(let value):
            self?.exportDataString(value, wallet: wallet)
          case .failure(let error):
            self?.navigationController.topViewController?.displayError(error: error)
          }
        })
      }
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
      session: self.session,
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
        with: NSLocalizedString("success", value: "Success", comment: ""),
        message: NSLocalizedString("your.pin.has.been.update.successfully", value: "Your PIN has been updated successfully!", comment: ""),
        time: 1.5
      )
    }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    if case .verifyPasscode = self.passcodeCoordinator.type {
      self.passcodeCoordinator.stop {
        guard let wallet = self.selectedWallet else { return }
        self.showActionSheetBackupPhrase(walletObj: wallet)
        self.selectedWallet = nil
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
    }
  }
}

extension KNSettingsCoordinator: KNListWalletsCoordinatorDelegate {
  func listWalletsCoordinatorDidClickBack() {
    self.listWalletsCoordinator?.stop()
    self.listWalletsCoordinator = nil
  }

  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.listWalletsCoordinator?.stop()
    if wallet == self.session.wallet { return }
    self.delegate?.settingsCoordinatorUserDidSelectNewWallet(wallet)
  }

  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet) {
    self.delegate?.settingsCoordinatorUserDidRemoveWallet(wallet)
  }

  func listWalletsCoordinatorDidUpdateWalletObjects() {
    self.delegate?.settingsCoordinatorUserDidUpdateWalletObjects()
  }

  func listWalletsCoordinatorDidSelectAddWallet(type: AddNewWalletType) {
    self.delegate?.settingsCoordinatorUserDidSelectAddWallet(type: type)
  }

  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KNWalletObject) {
    self.settingsViewControllerBackUpButtonPressed(wallet: wallet)
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
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.settingsCoordinatorDidSelectWallet(wallet)
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
  
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.settingsCoordinatorDidSelectWallet(wallet)
  }
  
  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.settingsCoordinatorDidSelectManageWallet()
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.settingsCoordinatorDidSelectAddWallet()
  }
}
