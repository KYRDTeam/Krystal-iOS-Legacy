//
//  BaseWalletOrientedViewController.swift
//  BaseModule
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit
import BaseWallet
import AppState
import KrystalWallets
import Dependencies

open class BaseWalletOrientedViewController: KNBaseViewController {
  @IBOutlet public weak var walletButton: UIButton?
  @IBOutlet public weak var backupIcon: UIImageView?
  @IBOutlet public weak var chainIcon: UIImageView?
  @IBOutlet public weak var chainButton: UIButton?
  @IBOutlet public weak var walletView: UIView?
  
  var currentAddress: KAddress {
    return AppState.shared.currentAddress
  }
  
  open var currentChain: ChainType {
    return AppState.shared.currentChain
  }
  
  open var supportAllChainOption: Bool {
    return false
  }
    
    open var allowSwitchChain: Bool {
        return true
    }
    
    open var supportSolana: Bool {
        return true
    }
  
  override open func viewDidLoad() {
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
  
  open func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppSelectAllChain),
      name: .appSelectAllChain,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAppSwitchChain),
      name: .appChainChanged,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppSwitchAddressNotification),
      name: .appAddressChanged,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onWalletListUpdated),
      name: .appWalletsListHasUpdate,
      object: nil
    )
  }
  
  open func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: .appAddressChanged, object: nil)
    NotificationCenter.default.removeObserver(self, name: .appChainChanged, object: nil)
    NotificationCenter.default.removeObserver(self, name: .appSelectAllChain, object: nil)
    NotificationCenter.default.removeObserver(self, name: .appWalletsListHasUpdate, object: nil)
  }
  
  open func reloadWallet() {
      walletButton?.setTitle(currentAddress.name, for: .normal)
      backupIcon?.isHidden = currentAddress.walletID.isEmpty || AppDependencies.walletManager.isWalletBackedUp(walletID: currentAddress.walletID)
  }
  
  open func reloadChain() {
      chainIcon?.image = currentChain.squareIcon()
      chainButton?.setTitle(currentChain.chainName(), for: .normal)
      chainButton?.setImage(allowSwitchChain ? .dropdown : nil, for: .normal)
      chainButton?.isEnabled = allowSwitchChain
  }
  
  open func reloadAllNetworksChain() {
    chainIcon?.image = ChainType.all.squareIcon()
    chainButton?.setTitle(ChainType.all.chainName(), for: .normal)
  }
  
  @objc open func onWalletListUpdated() {
    reloadWallet()
  }
  
  @objc open func onWalletButtonTapped() {
    handleWalletButtonTapped()
  }
  
  @IBAction open func onChainButtonTapped(_ sender: Any) {
    handleChainButtonTapped()
  }
  
  @objc open func onAppSwitchChain() {
    reloadChain()
  }
  
  @objc open func onAppSelectAllChain() {
    if supportAllChainOption {
      reloadAllNetworksChain()
    }
  }
    
    @objc open func onAppSwitchAddress(switchChain: Bool) {
        reloadWallet()
    }
    
    @objc open func onAppSwitchAddress() {
        self.onAppSwitchAddress(switchChain: false)
    }
    
  open func onChainSelected(chain: ChainType) {

  }
    
    @objc func handleAppSwitchAddressNotification(notification: Notification) {
        let switchChain = notification.userInfo?["switch_chain"] as? Bool ?? false
        self.onAppSwitchAddress(switchChain: switchChain)
    }
  
  @objc open func handleWalletButtonTapped() {
    let selectWalletHandler: (KWallet) -> () = { [weak self] wallet in
        guard let self = self else { return }
        let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
        if addresses.isEmpty { return }
        if let matchingChainAddress = addresses.first(where: { $0.addressType == AppState.shared.currentChain.addressType }) {
          AppState.shared.updateAddress(address: matchingChainAddress, targetChain: AppState.shared.currentChain)
        } else {
          let address = addresses.first!
          guard let chain = ChainType.allCases.first(where: {
            return $0 != .all && $0.addressType == address.addressType
          }) else { return }
          AppState.shared.updateAddress(address: address, targetChain: chain)
          self.onChainSelected(chain: chain)
        }
      }
    let selectWatchAddressHandler: (KAddress) -> () = { [weak self] address in
      let currentChain = AppState.shared.currentChain
      if address.addressType == AppState.shared.currentChain.addressType {
        if currentChain == .all {
          AppState.shared.updateAddress(address: address, targetChain: AppState.shared.currentChain)
          self?.onChainSelected(chain: .all)
        } else {
          AppState.shared.updateAddress(address: address, targetChain: AppState.shared.currentChain)
        }
      } else {
        guard let chain = ChainType.allCases.first(where: { $0 != .all && $0.addressType == address.addressType }) else { return }
        AppState.shared.updateAddress(address: address, targetChain: chain)
      }
    }
    AppDependencies.router.openWalletList(
      currentChain: AppState.shared.currentChain,
      allowAllChainOption: supportAllChainOption,
      onSelectWallet: selectWalletHandler,
      onSelectWatchAddress: selectWatchAddressHandler
    )
  }
  
  @objc open func handleChainButtonTapped() {
      AppDependencies.router.openChainList(currentChain, allowAllChainOption: supportAllChainOption, showSolanaOption: supportSolana) { [weak self] chain in
      self?.onChainSelected(chain: chain)
    }
  }
  
}
