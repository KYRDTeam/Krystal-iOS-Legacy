//
//  TransactionHistory.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/8/21.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore


class TransactionFactory {
  static func buildEIP1559Transaction(from: String, to: String, nonce: Int, data: Data, value: BigInt = BigInt.zero, setting: ConfirmAdvancedSetting) -> EIP1559Transaction {
    var gasLimitBigInt = BigInt(setting.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }

    var maxGasBigInt = BigInt(setting.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }

    var priorityFeeBigInt = (maxGasBigInt ?? BigInt.zero) - (KNGasCoordinator.shared.baseFee ?? BigInt.zero)
    if let unwrap = setting.advancedPriorityFee {
      priorityFeeBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt.zero
    }

    return EIP1559Transaction(
      chainID: BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded.hexSigned2Complement,
      nonce: BigInt(nonce).hexEncoded.hexSigned2Complement,
      gasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      toAddress: to,
      fromAddress: from,
      data: data.hexString.add0x,
      value: value.hexEncoded.hexSigned2Complement,
      reservedGasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x")
  }
  
  static func buildLegacyTransaction(account: Account, to: String, nonce: Int, data: Data, value: BigInt = BigInt.zero, setting: ConfirmAdvancedSetting) -> SignTransaction {
    var gasLimitBigInt = BigInt(setting.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }

    var maxGasBigInt = BigInt(setting.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }

    return SignTransaction(
      value: value,
      account: account,
      to: Address(string: to),
      nonce: nonce,
      data: data,
      gasPrice: maxGasBigInt ?? BigInt.zero,
      gasLimit: gasLimitBigInt ?? BigInt.zero,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
}

struct TransactionResponse: Codable {
    let timestamp: Int?
    let error: String?
    let txObject: TxObject
}

struct TxObject: Codable {
    let from, to, data, value: String
    let gasPrice, nonce, gasLimit: String
}

struct SignTransactionObject: Codable {
  let value: String
  let from: String
  let to: String?
  var nonce: Int
  let data: Data
  let gasPrice: String
  let gasLimit: String
  let chainID: Int
  let reservedGasLimit: String
  
  mutating func updateNonce(nonce: Int) {
    self.nonce = nonce
  }
}

extension SignTransactionObject {
  func toSignTransaction(account: Account, setting: ConfirmAdvancedSetting? = nil) -> SignTransaction {
    if let unwrap = setting {
      var nonceInt = self.nonce
      if let unwrapSetting = unwrap.advancedNonce {
        nonceInt = unwrapSetting
      }
      
      var gasLimitBigInt = BigInt(self.gasLimit)
      if let unwrapSetting = unwrap.advancedGasLimit {
        gasLimitBigInt = BigInt(unwrapSetting)
      }
      
      var gasPriceBigInt = BigInt(self.gasPrice)
      if let unwrapSetting = unwrap.avancedMaxFee {
        gasPriceBigInt = unwrapSetting.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      }
      
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        account: account,
        to: Address(string: self.to ?? ""),
        nonce: nonceInt,
        data: self.data,
        gasPrice: gasPriceBigInt ?? BigInt.zero,
        gasLimit: gasLimitBigInt ?? BigInt.zero,
        chainID: self.chainID
      )
      
    } else {
      return SignTransaction(
        value: BigInt(self.value) ?? BigInt(0),
        account: account,
        to: Address(string: self.to ?? ""),
        nonce: self.nonce,
        data: self.data,
        gasPrice: BigInt(gasPrice) ?? BigInt(0),
        gasLimit: BigInt(gasLimit) ?? BigInt(0),
        chainID: self.chainID
      )
    }
  }
  
  func toEIP1559Transaction(setting: ConfirmAdvancedSetting) -> EIP1559Transaction {
    var nonceInt = self.nonce
    if let unwrap = setting.advancedNonce {
      nonceInt = unwrap
    }
    
    var gasLimitBigInt = BigInt(self.gasLimit)
    if let unwrap = setting.advancedGasLimit {
      gasLimitBigInt = BigInt(unwrap)
    }
    
    var maxGasBigInt = BigInt(self.gasPrice)
    if let unwrap = setting.avancedMaxFee {
      maxGasBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    }
    
    var priorityFeeBigInt = (maxGasBigInt ?? BigInt.zero) - (KNGasCoordinator.shared.baseFee ?? BigInt.zero)
    if let unwrap = setting.advancedPriorityFee {
      priorityFeeBigInt = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt.zero
    }

    return EIP1559Transaction(
      chainID: BigInt(self.chainID).hexEncoded.hexSigned2Complement,
      nonce: BigInt(nonceInt).hexEncoded.hexSigned2Complement,
      gasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      maxInclusionFeePerGas: priorityFeeBigInt.hexEncoded.hexSigned2Complement,
      maxGasFee: maxGasBigInt?.hexEncoded.hexSigned2Complement ?? "0x",
      toAddress: self.to ?? "",
      fromAddress: self.from,
      data: self.data.hexString.add0x,
      value: BigInt(self.value)?.hexEncoded.drop0x.hexSigned2Complement ?? "0x",
      reservedGasLimit: gasLimitBigInt?.hexEncoded.hexSigned2Complement ?? "0x")
  }

  func gasPriceForCancelTransaction() -> BigInt {
    guard
      let currentGasPrice = BigInt(self.gasPrice)
    else
    {
      return KNGasConfiguration.gasPriceMax
    }
    let gasPrice = max(currentGasPrice * BigInt(1.2 * pow(10.0, 18.0)) / BigInt(10).power(18), KNGasConfiguration.gasPriceMax)
    return gasPrice
  }

  func toSpeedupTransaction(gasPrice: String, gasLimit: String) -> SignTransactionObject {
    return SignTransactionObject(value: self.value, from: self.from, to: self.to, nonce: self.nonce, data: self.data, gasPrice: gasPrice, gasLimit: gasLimit, chainID: self.chainID, reservedGasLimit: gasLimit)
  }

  func toCancelTransaction(gasPrice: String, gasLimit: String) -> SignTransactionObject {
    return SignTransactionObject(value: "0", from: self.from, to: self.from, nonce: self.nonce, data: Data(), gasPrice: gasPrice, gasLimit: gasLimit, chainID: self.chainID, reservedGasLimit: gasLimit)
  }

  func toSpeedupTransaction(account: Account, gasPrice: BigInt) -> SignTransaction {
    return SignTransaction(
      value: BigInt(self.value) ?? BigInt(0),
      account: account,
      to: Address(string: self.to ?? ""),
      nonce: self.nonce,
      data: self.data,
      gasPrice: gasPrice,
      gasLimit: BigInt(gasLimit) ?? BigInt(0),
      chainID: self.chainID
    )
  }
  
  func toCancelTransaction(account: Account) -> SignTransaction {
    return SignTransaction(
      value: BigInt(0),
      account: account,
      to: account.address,
      nonce: self.nonce,
      data: Data(),
      gasPrice: self.gasPriceForCancelTransaction(),
      gasLimit: KNGasConfiguration.transferETHGasLimitDefault,
      chainID: self.chainID
    )
  }
  
  func transactionGasPrice() -> BigInt? {
    return BigInt(self.gasPrice)
  }
}

extension TxObject {
  func convertToSignTransaction(wallet: Wallet, advancedGasPrice: String? = nil, advancedGasLimit: String? = nil, advancedNonce: String? = nil) -> SignTransaction? {
    guard
      let value = BigInt(self.value.drop0x, radix: 16),
      var gasPrice = BigInt(self.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(self.gasLimit.drop0x, radix: 16),
      var nonce = Int(self.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    if let unwrap = advancedGasPrice, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      gasPrice = value
    }
    
    if let unwrap = advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let unwrap = advancedNonce, let value = Int(unwrap) {
      nonce = value
    }
    if case let .real(account) = wallet.type {
      return SignTransaction(
        value: value,
        account: account,
        to: Address(string: self.to),
        nonce: nonce,
        data: Data(hex: self.data.drop0x),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        chainID: KNGeneralProvider.shared.customRPC.chainID
      )
    } else {
      //TODO: handle watch wallet type
      return nil
    }
  }
  
  func newTxObjectWithNonce(nonce: Int) -> TxObject {
    let nonceString = BigInt(nonce).hexEncoded
    return TxObject(from: self.from, to: self.to, data: self.data, value: self.value, gasPrice: self.gasPrice, nonce: nonceString, gasLimit: self.gasLimit)
  }
  
  func newTxObjectWithGasPrice(gasPrice: BigInt) -> TxObject {
    let gasPriceString = gasPrice.hexEncoded
    return TxObject(from: self.from, to: self.to, data: self.data, value: self.value, gasPrice: gasPriceString, nonce: self.nonce, gasLimit: self.gasLimit)
  }

  func convertToEIP1559Transaction(advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxGas: String?, advancedNonce: String?) -> EIP1559Transaction? {
    guard let baseFeeBigInt = KNGasCoordinator.shared.baseFee else { return nil }
    let gasLimitDefault = BigInt(self.gasLimit.drop0x, radix: 16) ?? BigInt(0)
    let gasPrice = BigInt(self.gasPrice.drop0x, radix: 16) ?? BigInt(0)
    let priorityFeeBigIntDefault = gasPrice - baseFeeBigInt
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = self.nonce.hexSigned2Complement
    if let customNonceString = advancedNonce, let nonceInt = Int(customNonceString) {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    if let advancedGasStr = advancedGasLimit,
       let gasLimit = BigInt(advancedGasStr),
       let priorityFeeString = advancedPriorityFee,
       let priorityFee = BigInt(priorityFeeString),
       let maxGasFeeString = advancedMaxGas,
       let maxGasFee = BigInt(maxGasFeeString) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: self.to,
        fromAddress: self.from,
        data: self.data,
        value: self.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
        )
    } else {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: self.to,
        fromAddress: self.from,
        data: self.data,
        value: self.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    }
  }
}

enum InternalTransactionState: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .pending
    case 1:
      self = .speedup
    case 2:
      self = .cancel
    case 3:
      self = .done
    case 4:
      self = .drop
    case 5:
      self = .error
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .pending:
      try container.encode(0, forKey: .rawValue)
    case .speedup:
      try container.encode(1, forKey: .rawValue)
    case .cancel:
      try container.encode(2, forKey: .rawValue)
    case .done:
      try container.encode(3, forKey: .rawValue)
    case .drop:
      try container.encode(4, forKey: .rawValue)
    case .error:
      try container.encode(5, forKey: .rawValue)
    }
  }
  
  case pending
  case speedup
  case cancel
  case done
  case drop
  case error
}

enum HistoryModelType: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .swap
    case 1:
      self = .withdraw
    case 2:
      self = .transferETH
    case 3:
      self = .receiveETH
    case 4:
      self = .transferToken
    case 5:
      self = .receiveToken
    case 6:
      self = .allowance
    case 7:
      self = .earn
    case 8:
      self = .contractInteraction
    case 9:
      self = .selfTransfer
    case 10:
      self = .createNFT
    case 11:
      self = .transferNFT
    case 12:
      self = .receiveNFT
    case 13:
      self = .claimReward
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .swap:
      try container.encode(0, forKey: .rawValue)
    case .withdraw:
      try container.encode(1, forKey: .rawValue)
    case .transferETH:
      try container.encode(2, forKey: .rawValue)
    case .receiveETH:
      try container.encode(3, forKey: .rawValue)
    case .transferToken:
      try container.encode(4, forKey: .rawValue)
    case .receiveToken:
      try container.encode(5, forKey: .rawValue)
    case .allowance:
      try container.encode(6, forKey: .rawValue)
    case .earn:
      try container.encode(7, forKey: .rawValue)
    case .contractInteraction:
      try container.encode(8, forKey: .rawValue)
    case .selfTransfer:
      try container.encode(9, forKey: .rawValue)
    case .createNFT:
      try container.encode(10, forKey: .rawValue)
    case .transferNFT:
      try container.encode(11, forKey: .rawValue)
    case .receiveNFT:
      try container.encode(12, forKey: .rawValue)
    case .claimReward:
      try container.encode(13, forKey: .rawValue)
    }
  }

  case swap
  case withdraw
  case transferETH
  case receiveETH
  case transferToken
  case receiveToken
  case allowance
  case earn
  case contractInteraction
  case selfTransfer
  case createNFT
  case transferNFT
  case receiveNFT
  case claimReward

  static func typeFromInput(_ input: String) -> HistoryModelType {
    guard !input.isEmpty, input != "0x"  else {
      return .transferETH
    }

    let prefix = input.prefix(10)
    switch prefix {
    case "0x095ea7b3":
      return .allowance
    case "0x818e80b7", "0xdb006a75":
      return .withdraw
    case "0x30037de5", "0x9059232f", "0x852a12e3":
      return .earn
    case "0xa9059cbb":
      return .transferToken
    case "0xcf512b53", "0x12342114", "0xae591d54", "0x7a6c0dfe", "0x2db897d0":
      return .swap
    case "0x42842e0e", "0xf242432a":
      return .transferNFT
    case "0xd0def521", "0x731133e9":
      return .createNFT
    case "0x70ef85ea":
      return .claimReward
    default:
      return .contractInteraction
    }
  }
}

class InternalHistoryTransaction: Codable {
  var hash: String = ""
  var type: HistoryModelType
  var time: Date = Date()
  var nonce: Int = -1
  var state: InternalTransactionState
  let fromSymbol: String?
  let toSymbol: String?
  var transactionDescription: String
  let transactionDetailDescription: String
  var transactionSuccessDescription: String?
  var earnTransactionSuccessDescription: String?
  var transactionObject: SignTransactionObject?
  var eip1559Transaction: EIP1559Transaction?
  let chain: ChainType

  init(
    type: HistoryModelType,
    state: InternalTransactionState,
    fromSymbol: String?,
    toSymbol: String?,
    transactionDescription: String,
    transactionDetailDescription: String,
    transactionObj: SignTransactionObject?,
    eip1559Tx: EIP1559Transaction?) {
    self.type = type
    self.state = state
    self.fromSymbol = fromSymbol
    self.toSymbol = toSymbol
    self.transactionDescription = transactionDescription
    self.transactionDetailDescription = transactionDetailDescription
    self.transactionObject = transactionObj
    self.eip1559Transaction = eip1559Tx
    self.chain = KNGeneralProvider.shared.currentChain
  }
}

struct HistoryTransaction: Codable {
  let type: HistoryModelType
  let timestamp: String
  let transacton: [EtherscanTransaction]
  let internalTransactions: [EtherscanInternalTransaction]
  let tokenTransactions: [EtherscanTokenTransaction]
  let nftTransaction: [NFTTransaction]
  let wallet: String

  var date: Date {
    return Date(timeIntervalSince1970: Double(self.timestamp) ?? 0)
  }
  
  var hash: String {
    if let tx = transacton.first {
      return tx.hash
    } else if let internalTx = self.internalTransactions.first {
      return internalTx.hash
    } else if let tokenTx = self.tokenTransactions.first {
      return tokenTx.hash
    }
    return ""
  }
}

struct InternalListResponse: Codable {
    let status, message: String
    let result: [EtherscanInternalTransaction]
}

struct EtherscanInternalTransaction: Codable, Equatable {
  static func == (lhs: EtherscanInternalTransaction, rhs: EtherscanInternalTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
    let blockNumber, timeStamp, hash, from: String
    let to, value, contractAddress, input: String
    let type, gas, gasUsed, traceID: String
    let isError, errCode: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, from, to, value, contractAddress, input, type, gas, gasUsed
        case traceID = "traceId"
        case isError, errCode
    }
}

struct TokenTransactionListResponse: Codable {
    let status, message: String
    let result: [EtherscanTokenTransaction]
}

struct EtherscanTokenTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTokenTransaction, rhs: EtherscanTokenTransaction) -> Bool {
    return lhs.blockNumber == rhs.blockNumber
      && lhs.timeStamp == rhs.timeStamp
      && lhs.hash == rhs.hash
      && lhs.nonce == rhs.nonce
      && lhs.blockHash == rhs.blockHash
      && lhs.from == rhs.from
      && lhs.contractAddress == rhs.contractAddress
      && lhs.to == rhs.to
      && lhs.value == rhs.value
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, from, contractAddress, to: String
    let value, tokenName, tokenSymbol, tokenDecimal: String
    let transactionIndex, gas, gasPrice, gasUsed: String
    let cumulativeGasUsed, input, confirmations: String
}

struct TransactionsListResponse: Codable {
    let status, message: String
    let result: [EtherscanTransaction]
}

struct EtherscanTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTransaction, rhs: EtherscanTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, transactionIndex, from, to: String
    let value, gas, gasPrice, isError: String
    let txreceiptStatus, input, contractAddress, cumulativeGasUsed: String
    let gasUsed, confirmations: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, nonce, blockHash, transactionIndex, from, to, value, gas, gasPrice, isError
        case txreceiptStatus = "txreceipt_status"
        case input, contractAddress, cumulativeGasUsed, gasUsed, confirmations
    }
}

// MARK: - NFTHistoryResponse
struct NFTHistoryResponse: Codable {
    let status: String
    let result: [NFTTransaction]
}

// MARK: - Result
struct NFTTransaction: Codable, Equatable {
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, from, contractAddress, to: String
    let tokenID, tokenName, tokenSymbol, tokenDecimal: String
    let transactionIndex, gas, gasPrice, gasUsed: String
    let cumulativeGasUsed, input, confirmations: String
  
  static func == (lhs: NFTTransaction, rhs: NFTTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
}
