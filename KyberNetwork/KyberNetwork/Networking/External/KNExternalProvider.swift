// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit
import KrystalWallets

class KNExternalProvider {
  
  var networkAddress: String {
    return KNGeneralProvider.shared.proxyAddress
  }

  var minTxCount: Int {
    didSet {
      KNAppTracker.updateTransactionNonce(self.minTxCount, address: self.address.addressString)
    }
  }
  
  var address: KAddress
  let web3Swift: Web3Swift
  
  init(address: KAddress, web3: Web3Swift) {
    self.address = address
    self.web3Swift = web3
    self.minTxCount = 0
  }
  
  var customRPC: CustomRPC {
    return KNGeneralProvider.shared.customRPC
  }

  func updateNonceWithLastRecordedTxNonce(_ nonce: Int) {
    KNGeneralProvider.shared.getTransactionCount(
      for: address.addressString,
      state: "pending") { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let txCount) = result {
        self.minTxCount = max(self.minTxCount, min(txCount, nonce + 1))
      }
    }
  }
  
  func updateAddress(address: KAddress) {
    self.address = address
    self.minTxCount = 0
  }

  // MARK: Balance
  public func getETHBalance(completion: @escaping (Result<Balance, AnyError>) -> Void) {
    KNGeneralProvider.shared.getETHBalanace(
      for: address.addressString,
      completion: completion
    )
  }

  public func getTokenBalance(for contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTokenBalance(
      for: address.addressString,
      contract: contract,
      completion: completion
    )
  }
  
  public func getNFTBalance(for contract: String, id: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getNFTBalance(
      address: address.addressString,
      id: id,
      contract: contract,
      completion: completion
    )
  }

  // MARK: Transaction
  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTransactionCount(for: address.addressString) { [weak self] result in
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
  
  func speedUpTransferTransaction(address: KAddress, transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        self.signTransactionData(address: address, from: transaction, nonce: Int(transaction.nonce!), data: data, completion: { signResult in
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
    address: KAddress,
    for token: TokenObject,
    amount: BigInt,
    nonce: Int,
    data: Data,
    gasPrice: BigInt,
    gasLimit: BigInt,
    completion: @escaping (Result<String, AnyError>) -> Void) {
    self.signTransactionData(
      address: address,
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

  func exchange(address: KAddress, exchange: KNDraftExchangeTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenExchange(address: address, exchange, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(address: address, from: exchange, nonce: self.minTxCount, data: data, completion: { signResult in
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

  func sendTxWalletConnect(address: KAddress, txData: JSONDictionary, completion: @escaping (Result<String?, AnyError>) -> Void) {
    guard let value = (txData["value"] as? String ?? "").fullBigInt(decimals: 0),
      let from = txData["from"] as? String, let to = txData["to"] as? String,
      let gasPrice = (txData["gasPrice"] as? String ?? "").fullBigInt(decimals: 0),
      let gasLimit = (txData["gasLimit"] as? String ?? "").fullBigInt(decimals: 0),
          from.lowercased() == self.address.addressString.lowercased(),
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
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else {
        completion(.success(nil))
        return
      }
      switch txCountResult {
      case .success:
        let signTx = SignTransaction(
          value: value,
          address: address.addressString,
          to: to,
          nonce: self.minTxCount,
          data: data,
          gasPrice: gasPrice,
          gasLimit: gasLimit,
          chainID: KNGeneralProvider.shared.customRPC.chainID
        )
        self.signTransactionData(address: address, from: signTx) { [weak self] signResult in
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
      address: address.addressString,
      networkAddress: networkAddress,
      completion: completion
    )
  }

  func getAllowance(tokenAddress: String, toAddress: String? = nil, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: address.addressString,
      networkAddress: toAddress ?? networkAddress,
      tokenAddress: tokenAddress,
      completion: completion
    )
  }

  // Encode function, get transaction count, sign transaction, send signed data
  func sendApproveERC20Token(address: KAddress, exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendApproveERCToken(
      address: address,
      for: exchangeTransaction.from,
      value: Constants.maxValueBigInt,
      gasPrice: exchangeTransaction.gasPrice ?? KNGasCoordinator.shared.defaultKNGas,
      gasLimit: KNGasConfiguration.approveTokenGasLimitDefault,
      completion: completion
    )
  }

  func sendApproveERCToken(address: KAddress, for token: TokenObject, value: BigInt, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      address: address,
      token: token,
      value: value,
      currentNonce: self.minTxCount,
      networkAddress: self.networkAddress,
      gasPrice: gasPrice,
      gasLimit: gasLimit
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
  
  func sendApproveERCTokenAddress(address: KAddress, for tokenAddress: String, value: BigInt, gasPrice: BigInt, gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault, toAddress: String? = nil, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      address: address,
      tokenAddress: tokenAddress,
      value: value,
      currentNonce: self.minTxCount,
      networkAddress: toAddress ?? self.networkAddress,
      gasPrice: gasPrice,
      gasLimit: gasLimit
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
          from: self.address.addressString,
          to: self.addressToSend(transferTransaction),
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

  func getEstimateGasLimitForTransferNFT(address: KAddress, to: String, categoryAddress: String, tokenID: String, gasPrice: BigInt, gasLimit: BigInt, amount: Int, isERC721: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.requestDataForNFTTransfer(from: address.addressString, to: to, tokenID: tokenID, amount: amount, isERC721: isERC721) { result in
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: address.addressString,
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

  func getEstimateGasLimit(address: KAddress, for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let value: BigInt = exchangeTransaction.from.isETH ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.calculateDefaultGasLimit(from: exchangeTransaction.from, to: exchangeTransaction.to)
    }()

    self.requestDataForTokenExchange(address: address, exchangeTransaction) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: address.addressString,
          to: self.networkAddress,
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

  func getMultipleERC20Balances(address: KAddress, _ tokens: [String], completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    KNGeneralProvider.shared.getMutipleERC20Balances(for: address.addressString, tokens: tokens, completion: completion)
  }

  // MARK: Sign transaction
  private func signTransactionData(address: KAddress, from transaction: UnconfirmedTransaction, nonce: Int, data: Data?, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let defaultGasLimit: BigInt = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transaction.transferType.tokenObject())
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      address: address.addressString,
      to: self.addressToSend(transaction),
      nonce: nonce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )

    self.signTransactionData(address: address, from: signTransaction, completion: completion)
  }

  private func signTransactionData(address: KAddress, from exchange: KNDraftExchangeTransaction, nonce: Int, data: Data, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isETH ? exchange.amount : BigInt(0),
      address: address.addressString,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: exchange.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: exchange.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    self.signTransactionData(address: address, from: signTransaction, completion: completion)
  }

  private func signTransactionData(address: KAddress, for token: TokenObject, amount: BigInt, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: token.isETH ? amount : BigInt(0),
      address: address.addressString,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    self.signTransactionData(address: address, from: signTransaction, completion: completion)
  }

  func signTransactionData(address: KAddress, from signTransaction: SignTransaction, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let signResult = EthereumTransactionSigner().signTransaction(address: address, transaction: signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success((data, signTransaction)))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
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

  func requestDataForTokenExchange(address: KAddress, _ exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: address.addressString)
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

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> String? {
    switch transaction.transferType {
    case .ether:
      return transaction.to
    case .token(let token):
      return token.contract
    }
  }
}
