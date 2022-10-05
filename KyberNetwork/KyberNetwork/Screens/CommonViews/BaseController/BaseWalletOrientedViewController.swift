//
//  BaseWalletOrientedViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 24/08/2022.
//

import UIKit
import KrystalWallets
import QRCodeReaderViewController
import WalletConnectSwift

class BaseWalletOrientedViewController: KNBaseViewController {
  @IBOutlet weak var walletButton: UIButton?
  @IBOutlet weak var backupIcon: UIImageView?
  @IBOutlet weak var chainIcon: UIImageView?
  @IBOutlet weak var chainButton: UIButton?
  @IBOutlet weak var walletView: UIView?

  lazy var addWalletCoordinator: KNAddNewWalletCoordinator = {
    let coordinator = KNAddNewWalletCoordinator(parentViewController: navigationController!)
    return coordinator
  }()
  
  var supportAllChainOption: Bool {
    return false
  }
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  let service = KrystalService()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupGestures()
    observeNotifications()
    reloadWallet()
    reloadChain()
  }
  
  func setupGestures() {
    walletView?.isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(onWalletButtonTapped))
    gesture.cancelsTouchesInView = false
    walletView?.addGestureRecognizer(gesture)
  }
  
  deinit {
    unobserveNotifications()
  }
  
  func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppSwitchChain),
      name: AppEventCenter.shared.kAppDidSwitchChain,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onWalletListUpdated),
      name: AppEventCenter.shared.kWalletListHasUpdate,
      object: nil
    )
  }
  
  func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidSwitchChain, object: nil)
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kWalletListHasUpdate, object: nil)
  }
  
  func reloadWallet() {
    walletButton?.setTitle(currentAddress.name, for: .normal)
    backupIcon?.isHidden = currentAddress.walletID.isEmpty || WalletCache.shared.isWalletBackedUp(walletID: currentAddress.walletID)
  }
  
  func reloadChain() {
    chainIcon?.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainButton?.setTitle(KNGeneralProvider.shared.currentChain.chainName(), for: .normal)
  }
  
  @objc func onWalletListUpdated() {
    reloadWallet()
  }
  
  @objc func onWalletButtonTapped() {
    openWalletList()
  }
  
  @IBAction func onChainButtonTapped(_ sender: Any) {
    openSwitchChain()
  }
  
  @objc func onAppSwitchChain() {
    reloadChain()
  }
  
  @objc func onAppSwitchAddress() {
    reloadWallet()
  }
  
  func openWalletConnect() {
    ScannerModule.start(previousScreen: ScreenName.explore, viewController: self, acceptedResultTypes: [.walletConnect], scanModes: [.qr]) { [weak self] text, type in
      guard let self = self else { return }
      switch type {
      case .walletConnect:
        AppEventCenter.shared.didScanWalletConnect(address: self.currentAddress, url: text)
      default:
        return
      }
    }
  }
  
  func openWalletList() {
    let walletsList = WalletListV2ViewController()
    walletsList.delegate = self
    let navigation = UINavigationController(rootViewController: walletsList)
    navigation.setNavigationBarHidden(true, animated: false)
    present(navigation, animated: true, completion: nil)
  }
  
  func openSwitchChain() {
    MixPanelManager.track("import_select_chain_open", properties: ["screenid": "import_select_chain"])
    let popup = SwitchChainViewController(selected: currentChain)
    var chains = WalletManager.shared.getAllAddresses(walletID: currentAddress.walletID).flatMap { address in
      return ChainType.getAllChain().filter { chain in
        return chain != .all && chain.addressType == address.addressType
      }
    }
    if supportAllChainOption {
      chains = [.all] + chains
    }
    popup.dataSource = chains
    popup.completionHandler = { [weak self] selectedChain in
      self?.onChainSelected(chain: selectedChain)
    }
    present(popup, animated: true, completion: nil)
  }
  
  func onChainSelected(chain: ChainType) {
    KNGeneralProvider.shared.currentChain = chain
    AppEventCenter.shared.switchChain(chain: chain)
    AppDelegate.shared.coordinator.loadBalanceCoordinator?.shouldFetchAllChain = (chain == .all)
    AppDelegate.shared.coordinator.loadBalanceCoordinator?.resume()
  }
  
  func addNewWallet(wallet: KWallet, chain: ChainType) {
    AppDelegate.shared.coordinator.tabbarController.selectedIndex = 0
    onChainSelected(chain: chain)
    didSelectWallet(wallet: wallet)
  }
  
  func addNewWallet(watchAddress: KAddress, chain: ChainType) {
    onChainSelected(chain: chain)
    didSelectWatchWallet(address: watchAddress)
  }
  
  func addNewWalletDidSendRefCode(_ code: String) {
    service.sendRefCode(address: currentAddress, code.uppercased()) { _, message in
      AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
    }
  }
}

extension BaseWalletOrientedViewController: WalletListV2ViewControllerDelegate {
  func didSelectWallet(wallet: KWallet) {
    didSelectWallet(wallet: wallet, isCreatedFromBrowsing: false)
  }
  
  func didSelectAddWallet() {
    tabBarController?.present(addWalletCoordinator.navigationController, animated: false) {
      self.addWalletCoordinator.start(type: .full)
    }
  }
  
  func didSelectAddWatchWallet() {
    guard let tabBarController = tabBarController else {
      return
    }
    tabBarController.dismiss(animated: true) {
      let coordinator = AddWatchWalletCoordinator(parentViewController: tabBarController, editingAddress: nil)
      coordinator.start()
    }
  }
  
  func didSelectWallet(wallet: KWallet, isCreatedFromBrowsing: Bool = false) {
    let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
    guard addresses.isNotEmpty else { return }
    if let matchingChainAddress = addresses.first(where: { $0.addressType == currentChain.addressType }) {
      AppDelegate.shared.coordinator.switchAddress(address: matchingChainAddress, isCreatedFromBrowsing: isCreatedFromBrowsing)
    } else {
      let address = addresses.first!
      guard let chain = ChainType.allCases.first(where: {
        return ($0 != .all || supportAllChainOption) && $0.addressType == address.addressType
      }) else { return }
      self.onChainSelected(chain: chain)
      AppDelegate.shared.coordinator.switchAddress(address: address)
    }
  }
  
  func didSelectWatchWallet(address: KAddress) {
    if address.addressType == currentChain.addressType {
      if currentChain == .all {
        AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: KNGeneralProvider.shared.currentChain)
        onChainSelected(chain: .all)
      } else {
        AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: currentChain)
      }
    } else {
      guard let chain = ChainType.allCases.first(where: { $0 != .all && $0.addressType == address.addressType }) else { return }
      AppDelegate.shared.coordinator.switchToWatchAddress(address: address, chain: chain)
    }
  }
  
}
