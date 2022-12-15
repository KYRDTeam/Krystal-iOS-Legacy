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
  
  public var currentAddress: KAddress {
    get {
      guard let data = UserDefaults.standard.data(forKey: Constants.UserDefaultKeys.kLastUsedAddress) else {
        return WalletManager.shared.createEmptyAddress()
      }
      return (try? decoder.decode(KAddress.self, from: data)) ?? WalletManager.shared.createEmptyAddress()
    }
    set {
      guard let data = try? encoder.encode(newValue) else {
        return
      }
      UserDefaults.standard.set(data, forKey: Constants.UserDefaultKeys.kLastUsedAddress)
    }
  }
  
  public func updateChain(chain: ChainType) {
    currentChain = chain
    AppEventManager.shared.postSwitchChainEvent(chain: chain)
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
    return UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
  }
  
  public func markWalletBackedUp(walletID: String) {
    UserDefaults.standard.set(true, forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
  }
  
  public func unmarkWalletBackedUp(walletID: String) {
    UserDefaults.standard.removeObject(forKey: Constants.UserDefaultKeys.kIsWalletBackedUp + walletID)
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
