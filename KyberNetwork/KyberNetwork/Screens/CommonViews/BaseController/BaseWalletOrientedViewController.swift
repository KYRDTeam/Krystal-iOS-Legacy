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
  
  var walletConnectQRReaderDelegate: KQRCodeReaderDelegate?
  
  lazy var addWalletCoordinator: KNAddNewWalletCoordinator = {
    let coordinator = KNAddNewWalletCoordinator()
    coordinator.delegate = self
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
    setupDelegates()
  }
  
  func setupGestures() {
    walletView?.isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(onWalletButtonTapped))
    gesture.cancelsTouchesInView = false
    walletView?.addGestureRecognizer(gesture)
  }
  
  func setupDelegates() {
    walletConnectQRReaderDelegate = KQRCodeReaderDelegate(onResult: { result in
      self.handleWalletConnectQRCode(result: result)
    })
  }
  
  func handleWalletConnectQRCode(result: String) {
    guard let url = WCURL(result) else {
      self.showTopBannerView(
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
        self.present(controller, animated: true, completion: nil)
      }
    } catch {
      self.showTopBannerView(
        with: Strings.privateKeyError,
        message: Strings.canNotGetPrivateKey,
        time: 1.5
      )
    }
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
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = walletConnectQRReaderDelegate
    present(qrcode, animated: true, completion: nil)
  }
  
  func openWalletList() {
    let walletsList = WalletListV2ViewController()
    walletsList.delegate = self
    let navigation = UINavigationController(rootViewController: walletsList)
    navigation.setNavigationBarHidden(true, animated: false)
    present(navigation, animated: true, completion: nil)
  }
  
  func openSwitchChain() {
    let popup = SwitchChainViewController(selected: currentChain)
    var chains = WalletManager.shared.getAllAddresses(walletID: currentAddress.walletID).flatMap { address in
      return ChainType.allCases.filter { chain in
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
}

extension BaseWalletOrientedViewController: WalletListV2ViewControllerDelegate {
  
  func didSelectAddWallet() {
    present(addWalletCoordinator.navigationController, animated: false) {
      self.addWalletCoordinator.start(type: .full)
    }
  }
  
  func didSelectWallet(wallet: KWallet) {
    let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
    guard addresses.isNotEmpty else { return }
    if let matchingChainAddress = addresses.first(where: { $0.addressType == currentChain.addressType }) {
      AppDelegate.shared.coordinator.switchAddress(address: matchingChainAddress)
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

extension BaseWalletOrientedViewController: KNAddNewWalletCoordinatorDelegate {
  
  func addNewWalletCoordinator(didAdd wallet: KWallet, chain: ChainType) {
    AppDelegate.shared.coordinator.tabbarController.selectedIndex = 0
    onChainSelected(chain: chain)
    didSelectWallet(wallet: wallet)
  }
  
  func addNewWalletCoordinator(didAdd watchAddress: KAddress, chain: ChainType) {
    onChainSelected(chain: chain)
    didSelectWatchWallet(address: watchAddress)
  }
  
  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
    service.sendRefCode(address: currentAddress, code.uppercased()) { _, message in
      AppDelegate.shared.coordinator.tabbarController.showTopBannerView(message: message)
    }
  }

  func addNewWalletCoordinator(remove wallet: KWallet) {

  }
}
