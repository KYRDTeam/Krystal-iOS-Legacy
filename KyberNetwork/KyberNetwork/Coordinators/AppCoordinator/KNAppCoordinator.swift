// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Moya
import KrystalWallets
import AppState
import SwapModule
import EarnModule

class KNAppCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  let window: UIWindow
  internal var keystore: Keystore
  var coordinators: [Coordinator] = []
  internal var session: KNSession!
  
  let walletManager = WalletManager.shared
  let walletCache = WalletCache.shared
  
  var currentAddress: KAddress? {
    return AppState.shared.currentAddress
  }
  
  internal var loadBalanceCoordinator: KNLoadBalanceCoordinator?

    internal var swapV2Coordinator: SwapCoordinator?
//  internal var balanceTabCoordinator: KNBalanceTabCoordinator?
  internal var overviewTabCoordinator: OverviewCoordinator?
  internal var settingsCoordinator: KNSettingsCoordinator?
    var earnCoordinator: EarnModuleCoordinator?
  internal var rewardCoordinator: RewardCoordinator?
  internal var investCoordinator: InvestCoordinator?

  internal var tabbarController: KNTabBarController!
  internal var transactionStatusCoordinator: KNTransactionStatusCoordinator!

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  lazy var authenticationCoordinator: KNPasscodeCoordinator = {
    let passcode = KNPasscodeCoordinator(type: .authenticate(isUpdating: false))
    passcode.delegate = self
    return passcode
  }()

  lazy var landingPageCoordinator: KNLandingPageCoordinator = {
    let coordinator = KNLandingPageCoordinator(
      navigationController: self.navigationController
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var addWalletCoordinator: KNAddNewWalletCoordinator = {
    let coordinator = KNAddNewWalletCoordinator(parentViewController: navigationController)
    return coordinator
  }()
  
  internal var promoCodeCoordinator: KNPromoCodeCoordinator?
  var isFirstUpdateChain: Bool = true
  
  init(
    navigationController: UINavigationController = UINavigationController(),
    window: UIWindow,
    keystore: Keystore) {
      self.navigationController = navigationController
      self.window = window
      self.keystore = keystore
      super.init()
      self.window.rootViewController = self.navigationController
      self.window.makeKeyAndVisible()
    }
  
  deinit {
    self.removeInternalObserveNotification()
    self.removeObserveNotificationFromSession()
  }

  func start() {
    self.startLandingPageCoordinator()
    self.startFirstSessionIfNeeded()
    self.addInternalObserveNotification()
    self.setPredefineValues()
    if UIDevice.isIphone5 {
      self.navigationController.displaySuccess(title: "", message: "We are not fully supported iphone5 or small screen size. Some UIs might be broken.")
    }
  }

  fileprivate func setPredefineValues() {
    UserDefaults.standard.set(false, forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }
  
  func switchWallet(wallet: KWallet, chain: ChainType) {
      if let address = getAddresses(wallet: wallet, chain: chain).first {
        self.overviewTabCoordinator?.rootViewController.viewModel.currentChain = chain
        switchAddress(address: address)
        AppState.shared.updateChain(chain: chain)
      }
  }
  
  func didSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func switchToWatchAddress(address: KAddress, chain: ChainType) {
    switchAddress(address: address)
    AppState.shared.updateChain(chain: chain)
    AppState.shared.updateAddress(address: address, targetChain: chain)
  }
  
  func switchAddress(address: KAddress) {
    WalletCache.shared.lastUsedAddress = address
    KNAppTracker.updateAllTransactionLastBlockLoad(0, for: address.addressString)
    if self.tabbarController == nil {
      self.startNewSession(address: address)
    } else {
      self.restartSession(address: address)
    }
  }
  
  private func getAddresses(wallet: KWallet, chain: ChainType) -> [KAddress] {
    let addressType = getAddressType(forChain: chain)
    return walletManager.getAllAddresses(walletID: wallet.id, addressType: addressType)
  }
  
  private func getAddressType(forChain chain: ChainType) -> KAddressType {
    switch chain {
    case .solana:
      return .solana
    default:
      return .evm
    }
  }

  fileprivate func startLandingPageCoordinator() {
    self.addCoordinator(self.landingPageCoordinator)
    self.landingPageCoordinator.start()
  }

  fileprivate func startFirstSessionIfNeeded() {
    let lastUsedAddress = walletCache.lastUsedAddress
    let addresses = walletManager.getAllWallets().flatMap { walletManager.getAllAddresses(walletID: $0.id) }
    
    // For security, should always have passcode protection when user has imported wallets
    if let address = lastUsedAddress ?? addresses.first, KNPasscodeUtil.shared.currentPasscode() != nil {
      self.startNewSession(address: address)
      Tracker.updateUserID(address.addressString)
    }
  }

  func sendRefCode(_ code: String) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let signer = SignerFactory().getSigner(address: session.address)
    do {
      let signedData = try signer.signMessageHash(address: session.address, data: sendData, addPrefix: false)
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.registerReferrer(address: session.address.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            self.tabbarController.showTopBannerView(message: "Success register referral code")
          } else if let error = json["error"] as? String {
            self.tabbarController.showTopBannerView(message: error)
          } else {
            self.tabbarController.showTopBannerView(message: "Fail to register referral code")
          }
        }
      }
    } catch {
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
  
  func doLogin(_ completion: @escaping (Bool) -> Void) {
    let timestamp = Int(NSDate().timeIntervalSince1970)
    let message = "\(session.address.addressString)_\(timestamp)"
    let data = Data(message.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let signer = SignerFactory().getSigner(address: session.address)
    do {
      let signedData = try signer.signMessageHash(address: session.address, data: sendData, addPrefix: false)
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.requestWithFilter(.login(address: session.address.addressString, timestamp: timestamp, signature: signedData.hexEncoded)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result {
          print(resp.debugDescription)
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(LoginToken.self, from: resp.data)
            Storage.store(data, as: self.session.address.addressString + Constants.loginTokenStoreFileName)
            completion(true)
          } catch let error {
            print("[Login][Error] \(error.localizedDescription)")
            completion(false)
          }
        } else {
          completion(false)
        }
      }
    } catch {
      print("[Login] Failed to sign login message")
      completion(false)
    }
  }
}

// Application state
extension KNAppCoordinator {
  func appDidFinishLaunch() {
    if let passCode = KNPasscodeUtil.shared.currentPasscode(), !passCode.isEmpty, walletManager.getAllWallets().isNotEmpty {
      UserDefaults.standard.set(true, forKey: Constants.isCreatedPassCode)
    }
    self.splashScreenCoordinator.start()
    self.authenticationCoordinator.start()
    KNSession.resumeInternalSession()

    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedString.Key.foregroundColor: UIColor.Kyber.tabbarNormal, NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 10)],
      for: .normal
    )
    UITabBarItem.appearance().setTitleTextAttributes(
      [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWYellow],
      for: .selected
    )

    if isDebug {
      KNAppTracker.updateWonderWhyOrdersNotFilled(isRemove: true)
      KNAppTracker.updateCancelOpenOrderTutorial(isRemove: true)
    }

    // reset history filter every time open app
    KNAppTracker.removeHistoryFilterData()
    KNAppTracker.updateShouldShowUserTranserConsentPopUp(true)
  }

  func appDidBecomeActive() {
    KNSession.pauseInternalSession()
    KNSession.resumeInternalSession()
    self.loadBalanceCoordinator?.resume()
    KNNotificationUtil.postNotification(for: "viewDidBecomeActive")
  }

  func appWillEnterForeground() {
    if KNAppTracker.shouldShowAuthenticate() {
      self.authenticationCoordinator.start()
    }
  }

  func appDidEnterBackground() {
    self.splashScreenCoordinator.stop()
    KNSession.pauseInternalSession()
    self.loadBalanceCoordinator?.pause()
  }

  func appWillTerminate() {
  }

  func appDidReceiveLocalNotification(transactionHash: String) {
    let urlString = KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(transactionHash)"
    self.tabbarController.openSafari(with: urlString)
  }

}
