//
//  EthereumEIP1559TransactionSigner.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/06/2022.
//

import Foundation
import KrystalWallets
import Result
import BigInt

class EthereumEIP1559TransactionProcessor: TransactionProcessor {
  let generalProvider = KNGeneralProvider.shared
  var web3Service: EthereumWeb3Service
  let nonceCache = NonceCache.shared
  let chain: ChainType
  let transactionSigner = EIP1559TransactionSigner()
  
  init(chain: ChainType) {
    self.chain = chain
    self.web3Service = EthereumWeb3Service(chain: chain)
  }
  
  func isTransferQuoteToken(transaction: UnconfirmedTransaction) -> Bool {
    switch transaction.transferType {
    case .ether:
      return true
    default:
      return false
    }
  }
  
  func cancel(address: KAddress, transaction: InternalHistoryTransaction, gasLimit: String, maxPriorityFee: String, maxGasFee: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    guard let eip1559Tx = transaction.eip1559Transaction?.toCancelTransaction(gasLimit: gasLimit, priorityFee: maxPriorityFee, maxGasFee: maxGasFee) else {
      return
    }
    guard let signedTxData = self.transactionSigner.signTransaction(address: address, eip1559Tx: eip1559Tx) else {
      return
    }
    KNGeneralProvider.shared.sendSignedTransactionData(signedTxData, completion: { sendResult in
      switch sendResult {
      case .success(let hash):
        self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
        completion(.success(hash))
      case .failure(let error):
        completion(.failure(error))
      }
    })
  }
  
  func speedUp(address: KAddress, transaction: InternalHistoryTransaction, gasLimit: String, maxPriorityFee: String, maxGasFee: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    guard let eip1559Tx = transaction.eip1559Transaction?.toSpeedupTransaction(gasLimit: gasLimit, priorityFee: maxPriorityFee, maxGasFee: maxGasFee) else {
      return
    }
    guard let signedTxData = self.transactionSigner.signTransaction(address: address, eip1559Tx: eip1559Tx) else {
      return
    }
    KNGeneralProvider.shared.sendSignedTransactionData(signedTxData, completion: { sendResult in
      switch sendResult {
      case .success(let hash):
        self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
        completion(.success(hash))
      case .failure(let error):
        completion(.failure(error))
      }
    })
  }
  
  func transfer(address: KAddress, transaction: UnconfirmedTransaction, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ()) {
    web3Service.getTransactionCount(for: address.addressString) { result in
      switch result {
      case .success(let txCount):
        self.nonceCache.updateNonce(address: address.addressString, chain: self.chain, nonce: txCount)
        self.web3Service.getTransferTokenData(
          transferQuoteToken: self.isTransferQuoteToken(transaction: transaction),
          amount: transaction.value,
          address: transaction.to ?? ""
        ) { transferTxResult in
          switch transferTxResult {
          case .success(let data):
            guard let eip1559Tx = transaction.toEIP1559Transaction(nonceInt: txCount, data: data, fromAddress: address.addressString) else {
              completion(.failure(.init(TransactionError.failedToTransfer)))
              return
            }
            guard let data = self.transactionSigner.signTransaction(address: address, eip1559Tx: eip1559Tx) else {
              completion(.failure(.init(TransactionError.failedToSignTransaction)))
              return
            }
            self.generalProvider.sendSignedTransactionData(data, completion: { sendResult in
              switch sendResult {
              case .success(let hash):
                self.nonceCache.updateNonce(address: address.addressString, chain: self.chain, nonce: txCount + 1)
                completion(.success(TransferTransactionResultData(hash: hash, nonce: txCount, eip1559Transaction: eip1559Tx, transaction: nil)))
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
  
  func transferNFT(transferData: Data, from address: KAddress, to: String, gasLimit: BigInt, gasPrice: BigInt, amount: Int, isERC721: Bool, collectibleAddress: String, advancedPriorityFee: String?, advancedMaxfee: String?, advancedNonce: String?, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> Void) {
    guard let unwrapPriorityFee = advancedPriorityFee,
          let priorityFeeBigInt = unwrapPriorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit),
          let unwrapMaxFee = advancedMaxfee,
          let maxFeeBigInt = unwrapMaxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) else {
      return
    }
    
    var nonce = self.nonceCache.getCachingNonce(address: address.addressString, chain: self.chain)
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
      fromAddress: address.addressString,
      data: transferData.hexEncoded,
      value: "0x",
      reservedGasLimit: gasLimit.hexEncoded.hexSigned2Complement
    )
    
    guard let signedData = self.transactionSigner.signTransaction(address: address, eip1559Tx: eip1559Tx) else {
      return
    }
    KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { result in
      if case .success(let hash) = result {
        self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
        completion(.success(.init(hash: hash, nonce: nonce, eip1559Transaction: eip1559Tx, transaction: nil, signature: nil)))
      }
      if case .failure(let error) = result {
        completion(.failure(error))
      }
    })
  }
  
}
