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
  @IBOutlet weak var walletButton: UIButton!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainButton: UIButton!
  var walletConnectQRReaderDelegate: KQRCodeReaderDelegate?
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    observeNotifications()
    reloadWalletName()
    reloadChain()
    setupDelegates()
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
      selector: #selector(onSwitchChain),
      name: AppEventCenter.shared.kAppDidSwitchChain,
      object: nil
    )
  }
  
  func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidSwitchChain, object: nil)
  }
  
  func reloadWalletName() {
    walletButton.setTitle(currentAddress.name, for: .normal)
  }
  
  func reloadChain() {
    chainIcon.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainButton.setTitle(KNGeneralProvider.shared.currentChain.chainName(), for: .normal)
  }
  
  @IBAction func onWalletButtonTapped(_ sender: UIButton) {
    openWalletList()
  }
  
  @IBAction func onChainButtonTapped(_ sender: UIButton) {
    openSwitchChain()
  }
  
  @objc func onSwitchChain() {
    reloadChain()
  }
  
  func openWalletConnect() {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = walletConnectQRReaderDelegate
    present(qrcode, animated: true, completion: nil)
  }
  
  func openWalletList() {
    let viewModel = WalletsListViewModel()
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    present(walletsList, animated: true, completion: nil)
  }
  
  func openSwitchChain() {
    let popup = SwitchChainViewController()
    popup.dataSource = WalletManager.shared.getAllAddresses(walletID: currentAddress.walletID).flatMap { address in
      return ChainType.allCases.filter { chain in
        return chain != .all && chain.addressType == address.addressType
      }
    }
    popup.completionHandler = { selectedChain in
      KNGeneralProvider.shared.currentChain = selectedChain
      AppEventCenter.shared.switchChain(chain: selectedChain)
    }
    present(popup, animated: true, completion: nil)
  }

}

extension BaseWalletOrientedViewController: WalletsListViewControllerDelegate {
  
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      self.openWalletConnect()
    case .manageWallet:
      return
    case .didSelect:
      self.reloadWalletName()
      return
    case .addWallet:
      //      self.delegate?.swapV2CoordinatorDidSelectAddWallet()
      return
    }
  }
  
}
