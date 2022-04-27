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
      config.schemaVersion = 18
      config.migrationBlock = { migration, oldVersion in
        switch oldVersion {
        case 0:
            migration.enumerateObjects(ofType: "Transaction") { (_, new) in
              new?["internalType"] = TransactionType.normal.rawValue
            }
            migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
              new?["internalType"] = TransactionType.normal.rawValue
            }
        case 1:
          migration.enumerateObjects(ofType: "KNOrderObject") { (_, new) in
            new?["side_trade"] = nil
          }
        case 14:
          break //NOTE: migrate data here
        default: break
        }
      }
      return config
    }

    static func globalConfiguration(for chainID: Int = 1) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-global-\(chainID).realm")
      config.schemaVersion = 18
      config.migrationBlock = { migration, oldVersion in
        switch oldVersion {
        case 0:
            migration.enumerateObjects(ofType: "Transaction") { (_, new) in
              new?["internalType"] = TransactionType.normal.rawValue
            }
            migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
              new?["internalType"] = TransactionType.normal.rawValue
            }
        case 1:
          migration.enumerateObjects(ofType: "KNOrderObject") { (_, new) in
            new?["side_trade"] = nil
          }
        default: break
        }
      }
      return config
    }

}
