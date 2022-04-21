// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustCore
import TrustKeystore

enum WalletType {
    case real(Account)
    case watch(Address)
    case solana(String, String)
}

extension WalletType: Equatable {
    static func == (lhs: WalletType, rhs: WalletType) -> Bool {
        switch (lhs, rhs) {
        case (let .real(lhs), let .real(rhs)):
            return lhs == rhs
        case (let .watch(lhs), let .watch(rhs)):
            return lhs == rhs
        case (let .solana(lhs, _), let .solana(rhs, _)):
            return lhs == rhs
        default:
            return false
        }
    }
}

struct Wallet {
    let type: WalletType

    var address: Address? {
        switch type {
        case .real(let account):
            return account.address
        case .watch(let address):
            return address
        case .solana(_):
          return nil
        }
    }

  var addressString: String {
    switch type {
    case .real(let account):
      return account.address.description.lowercased()
    case .watch(let address):
      return address.description.lowercased()
    case .solana(let address, _):
      return address
    }
  }

  var isSolanaWallet: Bool {
    if case .solana(_, _) = self.type {
      return true
    } else {
      return false
    }
  }
  
  var evmAddressString: String {
    switch type {
    case .real(let account):
      return account.address.description.lowercased()
    case .watch(let address):
      return address.description.lowercased()
    case .solana(_, let evm):
      return evm
    }
  }
}

extension Wallet: Equatable {
    static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        return lhs.type == rhs.type
    }

  func getWalletObject() -> KNWalletObject? {
    let walletObject = KNWalletStorage.shared.wallets.first { obj in
      let address = self.addressString
      let objAddress = obj.address

      return address == objAddress
    }

    return walletObject
  }
}
