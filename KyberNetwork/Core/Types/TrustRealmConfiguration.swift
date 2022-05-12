// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import TrustKeystore
import TrustCore

struct RealmConfiguration {

    static func configuration(for account: Wallet, chainID: Int = KNGeneralProvider.shared.customRPC.chainID) -> Realm.Configuration {
        return RealmConfiguration.configuration(
          for: account.addressString,
          chainID: chainID
        )
    }

    static func configuration(for address: String, chainID: Int = KNGeneralProvider.shared.customRPC.chainID) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(address.lowercased())-\(chainID).realm")
      config.schemaVersion = 15
      config.migrationBlock = { migration, oldVersion in
        if oldVersion < 1 {
          migration.enumerateObjects(ofType: "Transaction") { (_, new) in
            new?["internalType"] = TransactionType.normal.rawValue
          }
          migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
            new?["internalType"] = TransactionType.normal.rawValue
          }
        }
        
        if oldVersion < 2 {
          migration.enumerateObjects(ofType: "KNOrderObject") { (_, new) in
            new?["side_trade"] = nil
          }
        }
        
        if oldVersion < 15 {
          migration.enumerateObjects(ofType: "KNWalletObject") { (_, new) in
            new?["chainType"] = 0
            new?["storateType"] = 0
            new?["evmAddress"] = ""
            new?["walletID"] = ""
          }
          migration.enumerateObjects(ofType: "KNContact") { (_, new) in
            new?["chainType"] = 1
          }
        }
      }
      return config
    }

    static func globalConfiguration(for chainID: Int = 1) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-global-\(chainID).realm")
      config.schemaVersion = 15
      config.migrationBlock = { migration, oldVersion in
        if oldVersion < 1 {
          migration.enumerateObjects(ofType: "Transaction") { (_, new) in
            new?["internalType"] = TransactionType.normal.rawValue
          }
          migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
            new?["internalType"] = TransactionType.normal.rawValue
          }
        }
        
        if oldVersion < 2 {
          migration.enumerateObjects(ofType: "KNOrderObject") { (_, new) in
            new?["side_trade"] = nil
          }
        }
        
        if oldVersion < 15 {
          migration.enumerateObjects(ofType: "KNWalletObject") { (_, new) in
            new?["chainType"] = 0
            new?["storateType"] = 0
            new?["evmAddress"] = ""
            new?["walletID"] = ""
          }
          migration.enumerateObjects(ofType: "KNContact") { (_, new) in
            new?["chainType"] = 1
          }
        }
      }
      return config
    }

}
