//
//  AppState.swift
//  AppState
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import BaseWallet
import Utilities
import KrystalWallets

public class AppState {
  
  public static let shared = AppState()
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  
  public private(set) var currentChain: ChainType = Storage.retrieve(Constants.StorageKeys.currentChain, as: ChainType.self) ?? Constants.defaultChain {
    didSet {
      Storage.store(self.currentChain, as: Constants.StorageKeys.currentChain)
    }
  }
  
    public var currentAddress: KAddress = WalletManager.shared.createEmptyAddress() {
        didSet {
            Storage.store(self.currentAddress, as: Constants.StorageKeys.currentAddress)
        }
    }
    
    var lastUserDefaultAddress: KAddress? {
        guard let data = UserDefaults.standard.data(forKey: Constants.UserDefaultKeys.kLastUsedAddress) else {
          return nil
        }
        return (try? decoder.decode(KAddress.self, from: data))
    }
    
    var lastStorageAddress: KAddress? {
        return Storage.retrieve(Constants.StorageKeys.currentAddress, as: KAddress.self)
    }
    
    private init() {
        if let lastUsedAddress = lastStorageAddress ?? lastUserDefaultAddress {
            currentAddress = lastUsedAddress
        } else {
            let allAddresses = WalletManager.shared.getAllAddresses()
            currentAddress = allAddresses.first { !$0.isWatchWallet }
                                ?? allAddresses.first { $0.isWatchWallet }
                                ?? WalletManager.shared.createEmptyAddress()
        }
    }
  
  public func updateChain(chain: ChainType) {
      if chain == .all {
          currentChain = Constants.defaultChain
          AppEventManager.shared.postSwitchChainEvent(chain: Constants.defaultChain)
          AppEventManager.shared.postSelectAllChain()
      } else {
          currentChain = chain
          AppEventManager.shared.postSwitchChainEvent(chain: chain)
      }
    
  }
  
  public func updateAddress(address: KAddress, targetChain: ChainType) {
    currentAddress = address
    if targetChain != currentChain {
        updateChain(chain: targetChain)
    }
    AppEventManager.shared.postSwitchAddressEvent(address: address, switchChain: false)
  }
  
  public var isBrowsingMode: Bool {
    return currentAddress.addressString.isEmpty
  }
  
  public var isSelectedAllChain: Bool = false
  
  public func isWalletBackedUp(walletID: String) -> Bool {
    if let wallet = WalletManager.shared.getWallet(id: walletID), wallet.importType != .mnemonic {
      return true
    }
      return isWalletBackedUpMarkedByStorage(walletID: walletID) ?? isWalletBackedUpMarkedByUserDefaults(walletID: walletID)
  }
  
  public func markWalletBackedUp(walletID: String) {
      Storage.store(true, as: Constants.StorageKeys.isWalletBackedUp + walletID)
  }
  
  public func unmarkWalletBackedUp(walletID: String) {
      Storage.store(false, as: Constants.StorageKeys.isWalletBackedUp + walletID)
  }
    
    func isWalletBackedUpMarkedByStorage(walletID: String) -> Bool? {
        return Storage.retrieve(Constants.StorageKeys.isWalletBackedUp + walletID, as: Bool.self)
    }
    
    func isWalletBackedUpMarkedByUserDefaults(walletID: String) -> Bool {
        return UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
    }
  
  private func getAddresses(wallet: KWallet, chain: ChainType) -> [KAddress] {
    let addressType = getAddressType(forChain: chain)
    return WalletManager.shared.getAllAddresses(walletID: wallet.id, addressType: addressType)
  }
  
  private func getAddressType(forChain chain: ChainType) -> KAddressType {
    switch chain {
    case .solana:
      return .solana
    default:
      return .evm
    }
  }
  
}
