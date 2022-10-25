//
//  MixPanelManager.swift
//  KyberNetwork
//
//  Created by Com1 on 05/04/2022.
//
import Mixpanel
import Foundation
import AppTrackingTransparency
import KrystalWallets

let mixPanelProjectToken = KNEnvironment.default == .production ? KNSecret.prodMixPannelKey : KNSecret.devMixPannelKey

class MixPanelManager {
  
  
  static let shared = MixPanelManager()
  
  func configClient() {
    Mixpanel.initialize(token: mixPanelProjectToken)
  }
  
  func setDistintID(_ address: KAddress) {
    guard Mixpanel.getInstance(name: mixPanelProjectToken) != nil else { return }
    Mixpanel.mainInstance().distinctId = address.getDistintID()
    Mixpanel.mainInstance().clearSuperProperties()
    Mixpanel.mainInstance().registerSuperProperties(address.getSuperProperty())
  }

  func updateWalletAddress(address: String) {
    guard Mixpanel.getInstance(name: mixPanelProjectToken) != nil else { return }
    Mixpanel.mainInstance().track(event: "wallet_address", properties: [
      "user-id": address
    ])
  }
  
  static func track(_ event: String, properties: Properties? = nil) {
    guard Mixpanel.getInstance(name: mixPanelProjectToken) != nil else { return }
    Mixpanel.mainInstance().track(event: event, properties: properties)
  }
}


extension KAddress {
  func getDistintID() -> String {
    if let wallet = WalletManager.shared.getWalletWithLocalRealm(forAddress: self), wallet.importType == .mnemonic {
      if self.addressString.has0xPrefix {
        return "multi-\(self.addressString)"
      } else if let address = WalletManager.shared.getAllAddresses(walletID: wallet.id).first {
        return "multi-\(address.addressString)"
      } else {
        return "multi-\(self.addressString)"
      }
    } else {
      if self.addressString.has0xPrefix {
        return self.addressString.lowercased()
      } else {
        return self.addressString
      }
    }
  }
  
  func getSuperProperty() -> [String: String] {
    var result: [String: String] = [:]
    if let wallet = WalletManager.shared.getWalletWithLocalRealm(forAddress: self), wallet.importType == .mnemonic {
      if let evmAddress = WalletManager.shared.getAllAddressesWithLocalRealm(walletID: wallet.id, addressType: .evm).first {
        result["ethereum_address"] = evmAddress.addressString.lowercased()
      }
      
      if let solAddress = WalletManager.shared.getAllAddressesWithLocalRealm(walletID: wallet.id, addressType: .solana).first {
        result["solana_address"] = solAddress.addressString
      }
    } else {
      if self.addressString.has0xPrefix {
        result["ethereum_address"] = self.addressString.lowercased()
      } else {
        result["solana_address"] = self.addressString
      }
    }
    
    return result
  }
}
