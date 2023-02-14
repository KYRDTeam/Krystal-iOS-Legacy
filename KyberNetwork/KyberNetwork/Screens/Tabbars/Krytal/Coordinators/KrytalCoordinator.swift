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
import KrystalWallets

protocol KrytalCoordinatorDelegate: class {
  func krytalCoordinatorDidSelectAddWallet()
  func krytalCoordinatorDidSelectManageWallet()
}

class KrytalCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
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
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  fileprivate var historyTxTimer: Timer?

  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorAppSwitchAddress()
    self.historyViewController.coordinatorAppSwitchAddress()
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
    guard let loginToken = Storage.retrieve(currentAddress.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.loadReferralOverview()
      }
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getReferralOverview(address: currentAddress.addressString, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralOverviewData.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateOverviewReferral(data)
          Storage.store(data, as: self.currentAddress.addressString + Constants.referralOverviewStoreFileName)
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
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getReferralTiers(address: currentAddress.addressString)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralTiers.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateTiers(data)
          Storage.store(data, as: self.currentAddress.addressString + Constants.referralTiersStoreFileName)
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
    guard let loginToken = Storage.retrieve(currentAddress.addressString + Constants.loginTokenStoreFileName, as: LoginToken.self) else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.getClaimHistory(address: currentAddress.addressString, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ClaimHistoryResponse.self, from: resp.data)
          self.historyViewController.coordinatorDidUpdateClaimedTransaction(data.claims)
          Storage.store(data.claims, as: self.currentAddress.addressString + Constants.krytalHistoryStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
      }
    }
  }

  fileprivate func loadCachedReferralOverview() {
    let referralOverViewData = Storage.retrieve(currentAddress.addressString + Constants.referralOverviewStoreFileName, as: ReferralOverviewData.self)
    self.rootViewController.coordinatorDidUpdateOverviewReferral(referralOverViewData)
  }
  
  fileprivate func loadCachedReferralTiers() {
    let referralTiersData = Storage.retrieve(currentAddress.addressString + Constants.referralTiersStoreFileName, as: ReferralTiers.self)
    self.rootViewController.coordinatorDidUpdateTiers(referralTiersData)
  }
  
  fileprivate func loadCachedClaimHistory() {
    let history = Storage.retrieve(currentAddress.addressString + Constants.krytalHistoryStoreFileName, as: [Claim].self) ?? []
    self.historyViewController.coordinatorDidUpdateClaimedTransaction(history)
  }
  
  fileprivate func openWalletListView() {
    let viewModel = WalletsListViewModel()
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
    let coordinator = RewardCoordinator(navigationController: self.navigationController)
    coordinator.start()
  }

  func coordinatorAppSwitchAddress() {
    self.checkWallet()
    self.rootViewController.coordinatorAppSwitchAddress()
    self.historyViewController.coordinatorAppSwitchAddress()
    self.loadCachedReferralOverview()
    self.loadCachedReferralTiers()
    self.loadCachedClaimHistory()
    self.loadReferralOverview()
    self.loadReferralTiers()
    self.loadClaimHistory()
  }
  
  fileprivate func checkWallet() {
    if currentAddress.isWatchWallet {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
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
      MixPanelManager.track("referral_code_pop_up_open", properties: ["screenid": "referral_code_pop_up"])
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
    case .didSelect(let address):
      return
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
          with: Strings.invalidSession,
          message: Strings.invalidSessionTryOtherQR,
          time: 1.5
        )
        return
      }

      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: self.currentAddress)
        DispatchQueue.main.async {
          let controller = KNWalletConnectViewController(
            wcURL: url,
            pk: privateKey
          )
          self.navigationController.present(controller, animated: true, completion: nil)
        }
      } catch {
        self.navigationController.showTopBannerView(
          with: Strings.privateKeyError,
          message: Strings.canNotGetPrivateKey,
          time: 1.5
        )
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
