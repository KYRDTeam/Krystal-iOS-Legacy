// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import Foundation
import Result
import KeychainSwift
import CryptoSwift
import TrustKeystore
import TrustCore

enum EtherKeystoreError: LocalizedError {
    case protectionDisabled
}

open class EtherKeystore: Keystore {
  
    struct Keys {
        static let recentlyUsedAddress: String = "recentlyUsedAddress"
        static let watchAddresses = "watchAddresses"
    }

    private let keychain: KeychainSwift
    private let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let keyStore: KeyStore
    private let defaultKeychainAccess: KeychainSwiftAccessOptions = .accessibleWhenUnlockedThisDeviceOnly
    let keysDirectory: URL
    let userDefaults: UserDefaults
  
  let solanaUtil = SolanaUtil()

    public init(
        keychain: KeychainSwift = KeychainSwift(keyPrefix: Constants.keychainKeyPrefix),
        keysSubfolder: String = "/keystore",
        userDefaults: UserDefaults = UserDefaults.standard
    ) throws {
        if !UIApplication.shared.isProtectedDataAvailable {
            throw EtherKeystoreError.protectionDisabled
        }
        self.keysDirectory = URL(fileURLWithPath: datadir + keysSubfolder)
        self.keychain = keychain
        self.keychain.synchronizable = false
        self.keyStore = try KeyStore(keyDirectory: keysDirectory)
        self.userDefaults = userDefaults
    }

    var hasWallets: Bool {
        return !wallets.isEmpty
    }

    private var watchAddresses: [String] {
        set {
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            return userDefaults.set(data, forKey: Keys.watchAddresses)
        }
        get {
            guard let data = userDefaults.data(forKey: Keys.watchAddresses) else { return [] }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [String] ?? []
        }
     }

    var recentlyUsedWallet: Wallet? {
        set {
          keychain.set(newValue?.addressString ?? "", forKey: Keys.recentlyUsedAddress, withAccess: defaultKeychainAccess)
        }
        get {
            let address = keychain.get(Keys.recentlyUsedAddress)
            return wallets.filter {
                $0.address?.description == address || $0.address?.description.lowercased() == address?.lowercased()
            }.first
        }
    }

    static var current: Wallet? {
        do {
            return try EtherKeystore().recentlyUsedWallet
        } catch {
            return .none
        }
    }

    // Async
    @available(iOS 10.0, *)
    func createAccount(with password: String, completion: @escaping (Result<Account, KeystoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
          let account = self.createAccout(password: password)
          DispatchQueue.main.async {
            completion(.success(account))
          }
        }
    }

    func create12wordsAccount(with password: String) -> Account {
        let mnemonic = Mnemonic.generate(strength: 128)
        let newPassword = PasswordGenerator.generateRandom()
        let account = try! self.keyStore.import(mnemonic: mnemonic, encryptPassword: newPassword)
        let _ = self.setPassword(newPassword, for: account)
        return account
    }

  func importWallet(type: ImportType, importType: ImportWalletChainType, completion: @escaping (Result<Wallet, KeystoreError>) -> Void) {
        let newPassword = PasswordGenerator.generateRandom()
        switch type {
        case .keystore(let string, let password):
            importKeystore(
                value: string,
                password: password,
                newPassword: newPassword
            ) { result in
                switch result {
                case .success(let account):
                    completion(.success(Wallet(type: .real(account))))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .privateKey(let privateKey):
          if importType == .solana {
            let result = self.solanaUtil.importKeyPair(privateKey)
            if let address = result.0, let walletIdentity = result.2 {
              completion(.success(Wallet(type: .solana(address, "", walletIdentity))))
            } else {
              completion(.failure(.failedToCreateWallet))
            }
          } else {
            keystore(for: privateKey, password: newPassword) { result in
                switch result {
                case .success(let value):
                    self.importKeystore(
                        value: value,
                        password: newPassword,
                        newPassword: newPassword
                    ) { result in
                        switch result {
                        case .success(let account):
                            completion(.success(Wallet(type: .real(account))))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
          }
        case .mnemonic(let words, let password):
          let key = words.joined(separator: " ")
          do {
            let account = try self.keyStore.import(mnemonic: key, passphrase: password, encryptPassword: newPassword)
            _ = setPassword(newPassword, for: account)
            if importType == .solana {
              let publicKey = SolanaUtil.seedsToPublicKey(key)
              completion(.success(Wallet(type: .solana(publicKey, account.address.description, ""))))
            } else {
              completion(.success(Wallet(type: .real(account))))
            }
          } catch let error {
            if case KeyStore.Error.accountAlreadyExists = error {
              completion(.failure(.duplicateAccount))
            } else {
              completion(.failure(.failedToImport(error)))
            }
          }
        case .watch(let address):
            let addressString = address.description
            guard !watchAddresses.contains(addressString) else {
                return completion(.failure(.duplicateAccount))
            }
            self.watchAddresses = [watchAddresses, [addressString]].flatMap { $0 }
            completion(.success(Wallet(type: .watch(address))))
        }
    }

    func keystore(for privateKey: String, password: String, completion: @escaping (Result<String, KeystoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keystore = self.convertPrivateKeyToKeystoreFile(
                privateKey: privateKey,
                passphrase: password
            )
            DispatchQueue.main.async {
                switch keystore {
                case .success(let result):
                    completion(.success(result.jsonString ?? ""))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func importKeystore(value: String, password: String, newPassword: String, completion: @escaping (Result<Account, KeystoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.importKeystore(value: value, password: password, newPassword: newPassword)
            DispatchQueue.main.async {
                switch result {
                case .success(let account):
                    completion(.success(account))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func createAccout(password: String) -> Account {
        let account = try! keyStore.createAccount(password: password, type: .encryptedKey)
        let _ = setPassword(password, for: account)
        return account
    }

    func importKeystore(value: String, password: String, newPassword: String) -> Result<Account, KeystoreError> {
        guard let data = value.data(using: .utf8) else {
            return (.failure(.failedToParseJSON))
        }
        do {
            let account = try keyStore.import(json: data, password: password, newPassword: newPassword)
            let _ = setPassword(newPassword, for: account)
            return .success(account)
        } catch {
            if case KeyStore.Error.accountAlreadyExists = error {
                return .failure(.duplicateAccount)
            } else {
                return .failure(.failedToImport(error))
            }
        }
    }

    var wallets: [Wallet] {
      let addresses = watchAddresses.compactMap { Address(string: $0) }
        return [
            keyStore.accounts.map { Wallet(type: .real($0)) },
            addresses.map { Wallet(type: .watch($0)) },
        ].flatMap { $0 }
    }

  func export(account: Account, password: String, newPassword: String, importType: ImportWalletChainType = .multiChain) -> Result<String, KeystoreError> {
        let result = self.exportData(account: account, password: password, newPassword: newPassword)
        switch result {
        case .success(let data):
            let string = String(data: data, encoding: .utf8) ?? ""
             return .success(string)
        case .failure(let error):
             return .failure(error)
        }
    }

  func export(account: Account, password: String, newPassword: String, importType: ImportWalletChainType = .multiChain, completion: @escaping (Result<String, KeystoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.export(account: account, password: password, newPassword: newPassword, importType: importType)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

  func exportData(account: Account, password: String, newPassword: String, importType: ImportWalletChainType = .multiChain) -> Result<Data, KeystoreError> {
        guard let account = getAccount(for: account.address) else {
            return .failure(.accountNotFound)
        }
      // TODO: Keystore is exported wrongly for this type wallet
      if account.type == .hierarchicalDeterministicWallet {
        let privateKey = self.exportPrivateKey(account: account)
        if case .success(let key) = privateKey {
          let keystore = self.convertPrivateKeyToKeystoreFile(privateKey: key.hexString, passphrase: newPassword)
          switch keystore {
          case .success(let data):
            let keystoreString = data.jsonString ?? ""
            if let data = keystoreString.data(using: .utf8) {
              return .success(data)
            }
          default:
            break
          }
        }
        return (.failure(.failedToDecryptKey))
      }
        do {
            let data = try keyStore.export(account: account, password: password, newPassword: newPassword)
            return (.success(data))
        } catch {
            return (.failure(.failedToDecryptKey))
        }

    }

    func exportPrivateKey(account: Account) -> Result<Data, KeystoreError> {
        guard let password = getPassword(for: account) else {
            return .failure(KeystoreError.accountNotFound)
        }
        do {
            let privateKey = try keyStore.exportPrivateKey(account: account, password: password)
            return .success(privateKey)
        } catch {
            return .failure(KeystoreError.failedToExportPrivateKey)
        }

    }

    func exportMnemonics(account: Account) -> Result<String, KeystoreError> {
      guard let password = getPassword(for: account) else {
        return .failure(KeystoreError.accountNotFound)
      }
      do {
        let mnemonic = try self.keyStore.exportMnemonic(account: account, password: password)
        return .success(mnemonic)
      } catch {
        return .failure(KeystoreError.failedToExportMnemonics)
      }
    }

    func delete(wallet: Wallet) -> Result<Void, KeystoreError> {
        switch wallet.type {
        case .real(let acc):
            guard let account = getAccount(for: acc.address) else {
                return .failure(.failedMissingAccountOrPassword)
            }

            guard let password = getPassword(for: account) else {
                return .failure(.failedMissingAccountOrPassword)
            }

            do {
                try keyStore.delete(account: account, password: password)
                return .success(())
            } catch {
                return .failure(.failedToDeleteAccount)
            }
        case .watch(let address):
            watchAddresses = watchAddresses.filter { $0 != address.description }
            return .success(())
        case .solana(let address):
          //Note: implement delete
          return .failure(.failedToDeleteAccount)
        }
    }

    func delete(wallet: Wallet, completion: @escaping (Result<Void, KeystoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.delete(wallet: wallet)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func updateAccount(account: Account, password: String, newPassword: String) -> Result<Void, KeystoreError> {
        guard let account = getAccount(for: account.address) else {
            return .failure(.accountNotFound)
        }

        do {
            try keyStore.update(account: account, password: password, newPassword: newPassword)
            return .success(())
        } catch {
            return .failure(.failedToUpdatePassword)
        }
    }

    func signPersonalMessage(_ data: Data, for account: Account) -> Result<Data, KeystoreError> {
      let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
      return signMessage(prefix + data, for: account)
    }

  func signTypedMessage(_ datas: [EthTypedData], for account: Account) -> Result<Data, KeystoreError> {
    let schemas = datas.map { $0.schemaData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
    let values = datas.map { $0.typedData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
    let combined = (schemas + values).sha3(.keccak256)
    return signHash(combined, for: account)
  }
  
  func signEip712TypedData(_ data: EIP712TypedData, for account: Account) -> Result<Data, KeystoreError> {
      signHash(data.digest, for: account)
  }

    func signMessage(_ message: Data, for account: Account) -> Result<Data, KeystoreError> {
        return signHash(message.sha3(.keccak256), for: account)
    }

    func signHash(_ hash: Data, for account: Account) -> Result<Data, KeystoreError> {
        guard
            let password = getPassword(for: account) else {
                return .failure(KeystoreError.failedToSignMessage)
        }
        do {
            var data = try keyStore.signHash(hash, account: account, password: password)
            // TODO: Make it configurable, instead of overriding last byte.
            data[64] += 27
            return .success(data)
        } catch {
            return .failure(KeystoreError.failedToSignMessage)
        }
    }

    func signTransaction(_ transaction: SignTransaction) -> Result<Data, KeystoreError> {
        guard let account = keyStore.account(for: transaction.account.address) else {
            return .failure(.failedMissingAccountOrPassword)
        }
        guard let password = getPassword(for: account) else {
            return .failure(.failedMissingAccountOrPassword)
        }

        let signer: Signer
        if transaction.chainID == 0 {
            signer = HomesteadSigner()
        } else {
            signer = EIP155Signer(chainId: BigInt(transaction.chainID))
        }

        do {
            let hash = signer.hash(transaction: transaction)
            let signature = try keyStore.signHash(hash, account: account, password: password)
            let (r, s, v) = signer.values(transaction: transaction, signature: signature)
            let data = RLP.encode([
                transaction.nonce,
                transaction.gasPrice,
                transaction.gasLimit,
                transaction.to?.data ?? Data(),
                transaction.value,
                transaction.data,
                v, r, s,
            ])!
            return .success(data)
        } catch {
            return .failure(.failedToSignTransaction)
        }
    }

    func getPassword(for account: Account) -> String? {
        return keychain.get(account.address.description.lowercased())
    }

    @discardableResult
    func setPassword(_ password: String, for account: Account) -> Bool {
        return keychain.set(password, forKey: account.address.description.lowercased(), withAccess: defaultKeychainAccess)
    }

    func getAccount(for address: Address) -> Account? {
        return keyStore.account(for: address)
    }

    func convertPrivateKeyToKeystoreFile(privateKey: String, passphrase: String) -> Result<[String: Any], KeystoreError> {
        guard let data = Data(hexString: privateKey) else {
            return .failure(KeystoreError.failedToImportPrivateKey)
        }
        do {
            let key = try KeystoreKey(password: passphrase, key: data)
            let data = try JSONEncoder().encode(key)
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            return .success(dict)
        } catch {
            return .failure(KeystoreError.failedToImportPrivateKey)
        }
    }
}
