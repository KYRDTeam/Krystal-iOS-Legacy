//
//  KrytalCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation
import Moya
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnectSwift

protocol KrytalCoordinatorDelegate: class {
  func krytalCoordinatorDidSelectAddWallet()
  func krytalCoordinatorDidSelectWallet(_ wallet: Wallet)
  func krytalCoordinatorDidSelectManageWallet()
}

class KrytalCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  weak var delegate: KrytalCoordinatorDelegate?
  
  lazy var rootViewController: KrytalViewController = {
    let controller = KrytalViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var historyViewController: KrytalHistoryViewController = {
    let controller = KrytalHistoryViewController()
    controller.delegate = self
    return controller
  }()
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.addressString
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }
  
  fileprivate var historyTxTimer: Timer?

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.historyViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
    self.loadCachedReferralTiers()
    self.loadReferralOverview()
    self.loadReferralTiers()
    self.loadClaimHistory()
    self.historyTxTimer = Timer(timeInterval: KNLoadingInterval.seconds60, repeats: true, block: { (timer) in
      self.loadReferralTiers()
      self.loadReferralOverview()
    })
    self.checkWallet()
  }

  func stop() {
    
  }

  func loadReferralOverview() {
    guard let loginToken = Storage.retrieve(self.session.wallet.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.loadReferralOverview()
      }
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getReferralOverview(address: self.session.wallet.addressString, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralOverviewData.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateOverviewReferral(data)
          Storage.store(data, as: self.session.wallet.addressString + Constants.referralOverviewStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.loadReferralOverview()
          }
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.loadReferralOverview()
        }
      }
    }
  }
  
  func loadReferralTiers() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getReferralTiers(address: self.session.wallet.addressString)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralTiers.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateTiers(data)
          Storage.store(data, as: self.session.wallet.addressString + Constants.referralTiersStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.loadReferralTiers()
          }
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.loadReferralTiers()
        }
      }
    }
  }

  fileprivate func loadClaimHistory() {
    guard let loginToken = Storage.retrieve(self.session.wallet.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getClaimHistory(address: self.session.wallet.addressString, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ClaimHistoryResponse.self, from: resp.data)
          self.historyViewController.coordinatorDidUpdateClaimedTransaction(data.claims)
          Storage.store(data.claims, as: self.session.wallet.addressString + Constants.krytalHistoryStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
      }
    }
  }

  fileprivate func loadCachedReferralOverview() {
    let referralOverViewData = Storage.retrieve(self.session.wallet.addressString + Constants.referralOverviewStoreFileName, as: ReferralOverviewData.self)
    self.rootViewController.coordinatorDidUpdateOverviewReferral(referralOverViewData)
  }
  
  fileprivate func loadCachedReferralTiers() {
    let referralTiersData = Storage.retrieve(self.session.wallet.addressString + Constants.referralTiersStoreFileName, as: ReferralTiers.self)
    self.rootViewController.coordinatorDidUpdateTiers(referralTiersData)
  }
  
  fileprivate func loadCachedClaimHistory() {
    let history = Storage.retrieve(self.session.wallet.addressString + Constants.krytalHistoryStoreFileName, as: [Claim].self) ?? []
    self.historyViewController.coordinatorDidUpdateClaimedTransaction(history)
  }
  
  fileprivate func openWalletListView() {
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.availableWalletObjects,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
  
  fileprivate func showReferralTiers(tiers: [Tier]) {
    let viewModel = ReferralTiersViewModel(tiers: tiers)
    let controller = ReferralTiersViewController(viewModel: viewModel)
    self.navigationController.present(controller, animated: true, completion: nil)
  }
  
  fileprivate func showRewards() {
    let coordinator = RewardCoordinator(navigationController: self.navigationController, session: self.session)
    coordinator.start()
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.checkWallet()
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.historyViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
    self.loadCachedReferralTiers()
    self.loadCachedClaimHistory()
    self.loadReferralOverview()
    self.loadReferralTiers()
    self.loadClaimHistory()
  }
  
  fileprivate func checkWallet() {
    guard case .real(let account) = self.session.wallet.type else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      return
    }
  }
}

extension KrytalCoordinator: KrytalViewControllerDelegate {
  func krytalViewController(_ controller: KrytalViewController, run event: KrytalViewEvent) {
    switch event {
    case .openShareCode(refCode: let refCode, codeObject: let codeObject):
      let viewModel = ShareReferralLinkViewModel(refCode: refCode, codeObject: codeObject)
      let controller = ShareReferralLinkViewController(viewModel: viewModel)
      self.navigationController.present(controller, animated: true, completion: nil)
    case .openHistory:
      self.navigationController.pushViewController(self.historyViewController, animated: true)
    case .openWalletList:
      self.openWalletListView()
    case .showRefferalTiers(tiers: let tiers):
      self.showReferralTiers(tiers: tiers)
    case .claim:
      self.showRewards()
    }
  }
}

extension KrytalCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.krytalCoordinatorDidSelectManageWallet()
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.addressString == wallet.address.lowercased() }) else {
        return
      }
      self.delegate?.krytalCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.krytalCoordinatorDidSelectAddWallet()
    }
  }
}

extension KrytalCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let url = WCURL(result) else {
        self.navigationController.showTopBannerView(
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }

      if case .real(let account) = self.session.wallet.type {
        let result = self.session.keystore.exportPrivateKey(account: account)
        switch result {
        case .success(let data):
          DispatchQueue.main.async {
            let pkString = data.hexString
            let controller = KNWalletConnectViewController(
              wcURL: url,
              knSession: self.session,
              pk: pkString
            )
            self.navigationController.present(controller, animated: true, completion: nil)
          }
          
        case .failure(_):
          self.navigationController.showTopBannerView(
            with: "Private Key Error",
            message: "Can not get Private key",
            time: 1.5
          )
        }
      }
    }
  }
}

extension KrytalCoordinator: KrytalHistoryViewControllerDelegate {
  func krytalHistoryViewController(_ controller: KrytalHistoryViewController, run event: KrytalHistoryViewEvent) {
    switch event {
    case .openWalletList:
      self.openWalletListView()
    case .select(hash: let hash):
    self.navigationController.openSafari(with: KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(hash)")
    }
  }
}
