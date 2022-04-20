// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustCore
import TrustKeystore

enum WalletType {
    case real(Account)
    case watch(Address)
    case solana(String)
}

extension WalletType: Equatable {
    static func == (lhs: WalletType, rhs: WalletType) -> Bool {
        switch (lhs, rhs) {
        case (let .real(lhs), let .real(rhs)):
            return lhs == rhs
        case (let .watch(lhs), let .watch(rhs)):
            return lhs == rhs
        case (let .solana(lhs), let .solana(rhs)):
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
    case .solana(let address):
      return address
    }
  }
}

extension Wallet: Equatable {
    static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        return lhs.type == rhs.type
    }
  
  func getWalletObject() -> KNWalletObject? {
    return KNWalletStorage.shared.wallets.first { obj in
      let address = self.address?.description.lowercased() ?? ""
      let objAddress = obj.address.lowercased()

      return address == objAddress
    }
  }
}
