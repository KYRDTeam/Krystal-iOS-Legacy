//
//  AddWatchWalletViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 12/05/2022.
//

import Foundation
import UIKit
import TrustCore

class AddWatchWalletViewModel {
  var inputAddress: String = ""
  var ensAddress: Address?
  
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

  var wallet: KNWalletObject? {
    didSet {
      if let wallet = self.wallet {
        self.inputAddress = KNGeneralProvider.shared.currentChain == .solana ? wallet.address : wallet.address.lowercased()
      }
    }
  }
  
  var isAddressValid: Bool {
    guard !self.addressString.isEmpty else { return false }
    if KNGeneralProvider.shared.currentChain == .solana {
      return SolanaUtil.isVaildSolanaAddress(self.addressString)
    } else {
      return Address.isAddressValid(self.addressString)
    }
  }
  
  var displayAddress: String? {
    if let contact = KNContactStorage.shared.contacts.first(where: { self.inputAddress.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.inputAddress)"
    }
    return self.inputAddress
  }
  
  var displayTitle: String {
    if self.wallet == nil {
      return Strings.addWatchWallet
    } else {
      return Strings.editWatchWallet
    }
  }
  
  var displayAddButtonTitle: String {
    if self.wallet == nil {
      return Strings.add
    } else {
      return Strings.edit
    }
  }
  
  func onEnsAddressUpdated(address: Address?) {
    self.ensAddress = address
  }
  
  func getENSAddress(forDomain domain: String, completion: @escaping (Bool) -> ()) {
    KNGeneralProvider.shared.getAddressByEnsName(domain.lowercased()) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let address):
        guard let address = address, address != Address(string: "0x0000000000000000000000000000000000000000") else {
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
