// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

class KNExternalProvider {

  let keystore: Keystore
  fileprivate var account: Account
  let web3Swift: Web3Swift
  var networkAddress: Address {
    let address = KNGeneralProvider.shared.proxyAddress
    return Address(string: address)!
  }

  var minTxCount: Int {
    didSet {
      KNAppTracker.updateTransactionNonce(self.minTxCount, address: self.account.address)
    }
  }

  init(web3: Web3Swift, keystore: Keystore, account: Account) {
    self.keystore = keystore
    self.account = account
    self.web3Swift = web3
    
    self.minTxCount = 0
  }
  
  var customRPC: CustomRPC {
    return KNGeneralProvider.shared.customRPC
  }

  func updateNonceWithLastRecordedTxNonce(_ nonce: Int) {
    KNGeneralProvider.shared.getTransactionCount(
      for: self.account.address.description,
      state: "pending") { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let txCount) = result {
        self.minTxCount = max(self.minTxCount, min(txCount, nonce + 1))
      }
    }
  }

  func updateNewAccount(_ account: Account) {
    self.account = account
    self.minTxCount = 0
  }

  // MARK: Balance
  public func getETHBalance(completion: @escaping (Result<Balance, AnyError>) -> Void) {
    KNGeneralProvider.shared.getETHBalanace(
      for: self.account.address.description,
      completion: completion
    )
  }

  public func getTokenBalance(for contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTokenBalance(
      for: self.account.address,
      contract: contract,
      completion: completion
    )
  }
  
  public func getNFTBalance(for contract: String, id: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getNFTBalance(
      for: self.account.address.description,
      id: id,
      contract: contract,
      completion: completion
    )
  }

  // MARK: Transaction
  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTransactionCount(
    for: self.account.address.description) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let txCount):
        self.minTxCount = max(self.minTxCount, txCount)
        completion(.success(self.minTxCount))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func transfer(transaction: UnconfirmedTransaction, completion: @escaping (Result<(String, SignTransaction?, EIP1559Transaction?), AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            if transaction.maxInclusionFeePerGas != nil,
                transaction.maxGasFee != nil {
              if let eip1559Tx = transaction.toEIP1559Transaction(nonceInt: self.minTxCount, data: data, fromAddress: self.account.address.description),
                  let data = self.signContractGenericEIP1559Transaction(eip1559Tx) {
                print("[EIP1559] send tx \(eip1559Tx)")
                print("[EIP1559] hex tx \(data.hexString)")
                KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                  switch sendResult {
                  case .success(let hash):
                    self.minTxCount += 1
                    completion(.success((hash, nil, eip1559Tx)))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              }
            } else {
              var txNonce = self.minTxCount
              if let unwrap = transaction.nonce {
                txNonce = Int(unwrap)
              }
              self.signTransactionData(from: transaction, nonce: txNonce, data: data, completion: { signResult in
                switch signResult {
                case .success(let signData):
                  KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { [weak self] result in
                    guard let `self` = self else { return }
                    if case .success(let hash) = result {
                      self.minTxCount += 1
                      completion(.success((hash, signData.1, nil)))
                    }
                    if case .failure(let error) = result {
                      completion(.failure(error))
                    }
                  })
                case .failure(let error):
                  completion(.failure(error))
                }
              })
            }
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  //TODO: build signTx param first
  func transferNFT(from: String, to: String, item: NFTItem, category: NFTSection, gasLimit: BigInt, gasPrice: BigInt, amount: Int, isERC721: Bool, advancedPriorityFee: String?, advancedMaxfee: String?, advancedNonce: String?, completion: @escaping (Result<(String, SignTransaction?, EIP1559Transaction?), AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForNFTTransfer(from: from, to: to, tokenID: item.tokenID, amount: amount, isERC721: isERC721) { dataResult in
          switch dataResult {
          case .success(let data):
            if let unwrapPriorityFee = advancedPriorityFee,
               let priorityFeeBigInt = unwrapPriorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit),
               let unwrapMaxFee = advancedMaxfee,
               let maxFeeBigInt = unwrapMaxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
              var nonce = self.minTxCount
              if let customNonce = advancedNonce, let customNonceInt = Int(customNonce) {
                nonce = customNonceInt
              }
              let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
              let eip1559Tx = EIP1559Transaction(
                chainID: chainID.hexSigned2Complement,
                nonce: BigInt(nonce).hexEncoded.hexSigned2Complement,
                gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
                maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
                maxGasFee: maxFeeBigInt.hexEncoded.hexSigned2Complement,
                toAddress: to,
                fromAddress: from,
                data: data.hexEncoded,
                value: "0x"
              )

              if let signedData = self.signContractGenericEIP1559Transaction(eip1559Tx) {
                KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success(let hash) = result {
                    self.minTxCount += 1
                    completion(.success((hash, nil, eip1559Tx)))
                  }
                  if case .failure(let error) = result {
                    completion(.failure(error))
                  }
                })
              }
            } else {
              let signTx = SignTransaction(value: BigInt(0), account: self.account, to: Address(string: category.collectibleAddress), nonce: self.minTxCount, data: data, gasPrice: gasPrice, gasLimit: gasLimit, chainID: KNGeneralProvider.shared.customRPC.chainID)
              self.signTransactionData(from: signTx, completion: { signResult in
                switch signResult {
                case .success(let signData):
                  KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { [weak self] result in
                    guard let `self` = self else { return }
                    if case .success(let hash) = result {
                      self.minTxCount += 1
                      completion(.success((hash, signData.1, nil)))
                    }
                    if case .failure(let error) = result {
                      completion(.failure(error))
                    }
                  })
                case .failure(let error):
                  completion(.failure(error))
                }
              })
            }
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func speedUpTransferTransaction(transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        self.signTransactionData(from: transaction, nonce: Int(transaction.nonce!), data: data, completion: { signResult in
          switch signResult {
          case .success(let signData):
            KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { result in
              completion(result)
            })
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    })
  }

  func speedUpSwapTransaction(
    for token: TokenObject,
    amount: BigInt,
    nonce: Int,
    data: Data,
    gasPrice: BigInt,
    gasLimit: BigInt,
    completion: @escaping (Result<String, AnyError>) -> Void) {
    self.signTransactionData(
      for: token,
      amount: amount,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit) { (signResult) in
        switch signResult {
        case .success(let signData):
          KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { result in
            completion(result)
          })
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  func exchange(exchange: KNDraftExchangeTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenExchange(exchange, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: exchange, nonce: self.minTxCount, data: data, completion: { signResult in
              switch signResult {
              case .success(let signData):
                KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success = result { self.minTxCount += 1 }
                  completion(result)
                })
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func sendTxWalletConnect(txData: JSONDictionary, completion: @escaping (Result<String?, AnyError>) -> Void) {
    guard let value = (txData["value"] as? String ?? "").fullBigInt(decimals: 0),
      let from = txData["from"] as? String, let to = txData["to"] as? String,
      let gasPrice = (txData["gasPrice"] as? String ?? "").fullBigInt(decimals: 0),
      let gasLimit = (txData["gasLimit"] as? String ?? "").fullBigInt(decimals: 0),
      from.lowercased() == self.account.address.description.lowercased(),
      !gasPrice.isZero, !gasLimit.isZero else {
      completion(.success(nil))
      return
    }

    // Parse data from hex string
    let dataParse: Data? = (txData["data"] as? String ?? "").dataFromHex()
    guard let data = dataParse else {
      completion(.success(nil))
      return
    }

    guard let toAddr = Address(string: to) else {
      completion(.success(nil))
      return
    }
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else {
        completion(.success(nil))
        return
      }
      switch txCountResult {
      case .success:
        let signTx = SignTransaction(
          value: value,
          account: self.account,
          to: toAddr,
          nonce: self.minTxCount,
          data: data,
          gasPrice: gasPrice,
          gasLimit: gasLimit,
          chainID: KNGeneralProvider.shared.customRPC.chainID
        )
        self.signTransactionData(from: signTx) { [weak self] signResult in
          switch signResult {
          case .success(let signData):
            KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { [weak self] result in
              guard let `self` = self else { return }
              switch result {
              case .success(let txHash):
                self.minTxCount += 1
                completion(.success(txHash))
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getReceipt(for transaction: KNTransaction, completion: @escaping (Result<KNTransaction, AnyError>) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: transaction.id)
    Session.send(EtherServiceAlchemyRequest(batch: BatchFactory().create(request))) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let receipt):
        self.getExchangeTransactionDecode(receipt.logsData, completion: { decodeResult in
          let dict: JSONDictionary? = {
            if case .success(let json) = decodeResult {
              return json
            }
            return nil
          }()
          let newTransaction = receipt.toTransaction(from: transaction, logsDict: dict)
          completion(.success(newTransaction))
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getReceipt(hash: String, completion: @escaping (Result<KNTransactionReceipt, AnyError>) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: hash)
    Session.send(EtherServiceAlchemyRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let receipt):
        completion(.success(receipt))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTransactionByHash(_ hash: String, completion: @escaping (PendingTransaction?, SessionTaskError?) -> Void) {
    let request = GetTransactionRequest(hash: hash)
    Session.send(EtherServiceAlchemyRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let response):
        completion(response, nil)
      case .failure(let error):
        completion(nil, error)
      }
    }
  }

  func getAllowance(token: TokenObject, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: token,
      address: self.account.address,
      networkAddress: self.networkAddress,
      completion: completion
    )
  }

  func getAllowance(tokenAddress: Address, toAddress: Address? = nil, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: self.account.address,
      networkAddress: toAddress ?? self.networkAddress,
      tokenAddress: tokenAddress,
      completion: completion
    )
  }

  // Encode function, get transaction count, sign transaction, send signed data
  func sendApproveERC20Token(exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendApproveERCToken(
      for: exchangeTransaction.from,
      value: BigInt(2).power(256) - BigInt(1),
      gasPrice: exchangeTransaction.gasPrice ?? KNGasCoordinator.shared.defaultKNGas,
      completion: completion
    )
  }

  func sendApproveERCToken(for token: TokenObject, value: BigInt, gasPrice: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      token: token,
      value: value,
      account: self.account,
      keystore: self.keystore,
      currentNonce: self.minTxCount,
      networkAddress: self.networkAddress,
      gasPrice: gasPrice
    ) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let txCount):
          self.minTxCount = txCount
          completion(.success(true))
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  func sendApproveERCTokenAddress(for tokenAddress: Address, value: BigInt, gasPrice: BigInt, toAddress: String? = nil, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    var address: Address?
    if let unwrap = toAddress {
      address = Address(string: unwrap)
    }
    KNGeneralProvider.shared.approve(
      tokenAddress: tokenAddress,
      value: value,
      account: self.account,
      keystore: self.keystore,
      currentNonce: self.minTxCount,
      networkAddress: address ?? self.networkAddress,
      gasPrice: gasPrice
    ) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let txCount):
          self.minTxCount = txCount
          completion(.success(true))
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  // MARK: Rate
  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", withKyber: Bool = false, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    KNGeneralProvider.shared.getExpectedRate(
      from: from,
      to: to,
      amount: amount,
      hint: hint,
      withKyber: withKyber,
      completion: completion
    )
  }

  // MARK: Estimate Gas
  func getEstimateGasLimit(for transferTransaction: UnconfirmedTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {

    let defaultGasLimit: BigInt = {
      KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transferTransaction.transferType.tokenObject())
    }()
    self.requestDataForTokenTransfer(transferTransaction) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.addressToSend(transferTransaction)?.description,
          gasPrice: transferTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: self.valueToSend(transferTransaction),
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: false,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getEstimateGasLimitForTransferNFT(to: String, categoryAddress: String, tokenID: String, gasPrice: BigInt, gasLimit: BigInt, amount: Int, isERC721: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.requestDataForNFTTransfer(from: self.account.address.description, to: to, tokenID: tokenID, amount: amount, isERC721: isERC721) { result in
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: categoryAddress,
          gasPrice: gasPrice,
          value: BigInt(0),
          data: data,
          defaultGasLimit: KNGasConfiguration.transferTokenGasLimitDefault,
          isSwap: false,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getEstimateGasLimit(for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let value: BigInt = exchangeTransaction.from.isETH ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.calculateDefaultGasLimit(from: exchangeTransaction.from, to: exchangeTransaction.to)
    }()

    self.requestDataForTokenExchange(exchangeTransaction) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.networkAddress.description,
          gasPrice: exchangeTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: value,
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: true,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  static func estimateGasLimit(from: String, to: String?, gasPrice: BigInt, value: BigInt, data: Data, defaultGasLimit: BigInt, isSwap: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: from,
      to: to,
      value: value,
      data: data,
      gasPrice: gasPrice
    )
    NSLog("------ Estimate gas used ------")
    Session.send(EtherServiceAlchemyRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let value):
        let gasLimit: BigInt = {
          var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
          // Used  120% of estimated gas for safer
          limit += (limit * 20 / 100)
          if !isSwap && !data.isEmpty { // Add buffer for transfer token only
            limit += 20000
          }
          return limit
        }()
        NSLog("------ Estimate gas used: \(gasLimit.fullString(units: .wei)) ------")
        completion(.success(gasLimit))
      case .failure(let error):
        NSLog("------ Estimate gas used failed: \(error.localizedDescription) ------")
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getMultipleERC20Balances(_ tokens: [Address], completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    KNGeneralProvider.shared.getMutipleERC20Balances(for: self.account.address, tokens: tokens, completion: completion)
  }

  // MARK: Sign transaction
  private func signTransactionData(from transaction: UnconfirmedTransaction, nonce: Int, data: Data?, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let defaultGasLimit: BigInt = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transaction.transferType.tokenObject())
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      account: self.account,
      to: self.addressToSend(transaction),
      nonce: nonce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )

    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from exchange: KNDraftExchangeTransaction, nonce: Int, data: Data, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isETH ? exchange.amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: exchange.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: exchange.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(for token: TokenObject, amount: BigInt, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: token.isETH ? amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  func signTransactionData(from signTransaction: SignTransaction, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signResult = self.keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success((data, signTransaction)))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  func signContractGenericEIP1559Transaction(_ transaction: EIP1559Transaction) -> Data? {
    let result = self.keystore.exportPrivateKey(account: self.account)
    guard case .success(let data) = result else { return nil }
    return transaction.signContractGenericWithPK(data)
  }

  func signTransferEIP1559Transaction(_ transaction: EIP1559Transaction) -> Data? {
    let result = self.keystore.exportPrivateKey(account: self.account)
    guard case .success(let data) = result else { return nil }
    return transaction.signTransferWithPK(data)
  }

  // MARK: Web3Swift Encode/Decode data
  func getExchangeTransactionDecode(_ data: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = KNExchangeEventDataDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let json):
        completion(.success(json))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            completion(.success(json))
            return
          }
        }
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenTransfer(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if transaction.transferType.isETHTransfer() {
      completion(.success(Data()))
      return
    }
    self.web3Swift.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to?.description ?? "")) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForNFTTransfer(from: String, to: String, tokenID: String, amount: Int, isERC721: Bool, completion: @escaping (Result<Data, AnyError>) -> Void) {
    self.web3Swift.request(request: ContractNFTTransfer(from: from, to: to, tokenID: tokenID, amount: amount, isERC721Format: isERC721)) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenExchange(_ exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: self.account.address)
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Helper
  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    return transaction.transferType.isETHTransfer() ? transaction.value : BigInt(0)
  }

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> Address? {
    let address: Address? = {
      switch transaction.transferType {
      case .ether: return transaction.to
      case .token(let token):
        return token.addressObj
      }
    }()
    return address
  }
}
