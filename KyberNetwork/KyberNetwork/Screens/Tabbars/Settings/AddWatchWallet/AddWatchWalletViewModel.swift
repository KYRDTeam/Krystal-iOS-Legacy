//
//  AddWatchWalletViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 12/05/2022.
//

import Foundation
import UIKit
import TrustCore
import KrystalWallets

class AddWatchWalletViewModel {
  var inputAddress: String = ""
  var ensAddress: String?
  
  var address: KAddress? {
    didSet {
      guard let address = address else { return }
      inputAddress = address.addressString
    }
  }
  
  var isNameServiceSupported: Bool {
    switch KNGeneralProvider.shared.currentChain {
    case .solana:
      return false
    default:
      return true
    }
  }
  
  var addressString: String {
    if let ensAddress = ensAddress {
      return ensAddress.description
    } else {
      return inputAddress
    }
  }

  var isAddressValid: Bool {
    guard !self.addressString.isEmpty else { return false }
    let addressType = KNGeneralProvider.shared.currentChain.addressType
    return WalletManager.shared.validateAddress(address: addressString, forAddressType: addressType)
  }
  
  var displayAddress: String? {
    if let contact = KNContactStorage.shared.contacts.first(where: { self.inputAddress.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.inputAddress)"
    }
    return self.inputAddress
  }
  
  var displayTitle: String {
    if self.address == nil {
      return Strings.addWatchWallet
    } else {
      return Strings.editWatchWallet
    }
  }
  
  var displayAddButtonTitle: String {
    if self.address == nil {
      return Strings.add
    } else {
      return Strings.edit
    }
  }
  
  func onEnsAddressUpdated(address: String?) {
    self.ensAddress = address
  }
  
  func getENSAddress(forDomain domain: String, completion: @escaping (Bool) -> ()) {
    KNGeneralProvider.shared.getAddressByEnsName(domain.lowercased()) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let address):
        guard let address = address, address != "0x0000000000000000000000000000000000000000" else {
          completion(false)
          return
        }
        self.onEnsAddressUpdated(address: address)
        completion(true)
      case .failure:
        self.onEnsAddressUpdated(address: nil)
        completion(false)
      }
    }
  }
  
}
