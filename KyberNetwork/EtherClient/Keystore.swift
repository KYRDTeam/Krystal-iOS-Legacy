// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import TrustKeystore
import TrustCore

protocol Keystore {
  var solanaUtil: SolanaUtil { get }
    var hasWallets: Bool { get }
    var wallets: [Wallet] { get }
    var keysDirectory: URL { get }
    var recentlyUsedWallet: Wallet? { get set }
    static var current: Wallet? { get }
    @available(iOS 10.0, *)
    func createAccount(with password: String, completion: @escaping (Result<Account, KeystoreError>) -> Void)
    func create12wordsAccount(with password: String) -> Account
    func importWallet(type: ImportType, importType: ImportWalletChainType, completion: @escaping (Result<Wallet, KeystoreError>) -> Void)
    func keystore(for privateKey: String, password: String, completion: @escaping (Result<String, KeystoreError>) -> Void)
    func importKeystore(value: String, password: String, newPassword: String, completion: @escaping (Result<Account, KeystoreError>) -> Void)
    func createAccout(password: String) -> Account
    func importKeystore(value: String, password: String, newPassword: String) -> Result<Account, KeystoreError>
    func export(account: Account, password: String, newPassword: String, importType: ImportWalletChainType) -> Result<String, KeystoreError>
    func export(account: Account, password: String, newPassword: String, importType: ImportWalletChainType, completion: @escaping (Result<String, KeystoreError>) -> Void)
    func exportData(account: Account, password: String, newPassword: String, importType: ImportWalletChainType) -> Result<Data, KeystoreError>
    func exportPrivateKey(account: Account) -> Result<Data, KeystoreError>
    func exportMnemonics(account: Account) -> Result<String, KeystoreError>
    func delete(wallet: Wallet) -> Result<Void, KeystoreError>
    func delete(wallet: Wallet, completion: @escaping (Result<Void, KeystoreError>) -> Void)
    func updateAccount(account: Account, password: String, newPassword: String) -> Result<Void, KeystoreError>
    func signPersonalMessage(_ data: Data, for account: Account) -> Result<Data, KeystoreError>
    func signMessage(_ data: Data, for account: Account) -> Result<Data, KeystoreError>
    func signHash(_ hash: Data, for account: Account) -> Result<Data, KeystoreError>
    func signTransaction(_ signTransaction: SignTransaction) -> Result<Data, KeystoreError>
    func getPassword(for account: Account) -> String?
    func convertPrivateKeyToKeystoreFile(privateKey: String, passphrase: String) -> Result<[String: Any], KeystoreError>
    func signTypedMessage(_ datas: [EthTypedData], for account: Account) -> Result<Data, KeystoreError>
    func signEip712TypedData(_ data: EIP712TypedData, for account: Account) -> Result<Data, KeystoreError>
}

extension Keystore {
  func matchWithWalletObject(_ object: KNWalletObject) -> Wallet? {
    let chainType = ImportWalletChainType(rawValue: object.chainType) ?? .multiChain
    if chainType == .solana {
      return Wallet(type: .solana(object.address, object.evmAddress, object.walletID))
    } else {
      let wal = self.wallets.first(where: { $0.addressString == object.address })
      return wal
    }
  }

  func matchWithEvmAccount(address: String) -> Account? {
    let wal = self.wallets.first(where: { $0.addressString == address.lowercased() })
    if case .real(let account) = wal?.type {
      return account
    } else {
      return nil
    }
  }
}
