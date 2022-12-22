//
//  EtherumTransactionSigner.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/06/2022.
//

import Foundation
import KrystalWallets
import Result
import BigInt
import CryptoSwift
import TrustCore
import AppState
import Services

class EthereumTransactionProcessor: TransactionProcessor {
  
  let generalProvider = KNGeneralProvider.shared
  var web3Service: EthereumWeb3Service
  let nonceCache = NonceCache.shared
  let chain: ChainType
  let transactionSigner = EthereumTransactionSigner()
  
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
    guard let signTransaction = transaction.transactionObject?
      .toCancelTransaction(gasPrice: maxGasFee, gasLimit: gasLimit)
      .toSignTransaction(address: address)
    else {
      completion(.failure(AnyError(TransactionError.failedToCancelTransaction)))
      return
    }
    let signResult = self.transactionSigner.signTransaction(address: address, transaction: signTransaction)
    switch signResult {
    case .success(let data):
      self.generalProvider.sendSignedTransactionData(data, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
          completion(.success(hash))
        case .failure(let error):
          completion(.failure(error))
        }
      })
    case .failure(let error):
      completion(.failure(error))
    }
  }
  
  func speedUp(address: KAddress, transaction: InternalHistoryTransaction, gasLimit: String, maxPriorityFee: String, maxGasFee: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    guard let signTransaction = transaction.transactionObject?
      .toSpeedupTransaction(gasPrice: maxGasFee, gasLimit: gasLimit)
      .toSignTransaction(address: address)
    else {
      completion(.failure(AnyError(TransactionError.failedToCancelTransaction)))
      return
    }
    let signResult = self.transactionSigner.signTransaction(address: address, transaction: signTransaction)
    switch signResult {
    case .success(let data):
      self.generalProvider.sendSignedTransactionData(data, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
          completion(.success(hash))
        case .failure(let error):
          completion(.failure(error))
        }
      })
    case .failure(let error):
      completion(.failure(error))
    }
  }
    
    func getL1FeeForTxIfHave(data: String, completion: @escaping (BigInt) -> Void) {
        if AppState.shared.currentChain == .optimism {
            let service = EthereumNodeService(chain: AppState.shared.currentChain)
            service.getOPL1FeeEncodeData(for: data) { result in
                switch result {
                case .success(let encodeString):
                    service.getOptimismL1Fee(for: encodeString) { feeResult in
                        switch feeResult {
                        case .success(let fee):
                            completion(fee)
                        case .failure(let error):
                            self.showError(errorMsg: error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    self.showError(errorMsg: error.localizedDescription)
                }
            }
        } else {
            completion(BigInt(0))
        }
    }

    func showError(errorMsg: String) {
      UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.showErrorTopBannerMessage(message: errorMsg)
    }
//
    func getTransferTokenData(amount: BigInt, address: String, isQuoteToken: Bool, completion: @escaping (Data) -> ()) {
        self.web3Service.getTransferTokenData(
            transferQuoteToken: isQuoteToken,
            amount: amount,
            address: address
        ) { transferTxResult in
            switch transferTxResult {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    self.showError(errorMsg: error.localizedDescription)
            }
        }
    }
  
  func transfer(address: KAddress, transaction: UnconfirmedTransaction, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ()) {
      web3Service.getTransactionCount(for: address.addressString) { result in
          switch result {
              case .success(let txCount):
                  self.nonceCache.updateNonce(address: address.addressString, chain: self.chain, nonce: txCount)
                  self.getTransferTokenData(amount: transaction.value, address: transaction.to ?? "", isQuoteToken: self.isTransferQuoteToken(transaction: transaction)) { data in
                      let nonce = self.nonceCache.getCachingNonce(address: address.addressString, chain: self.chain)
                      let signResult = self.transactionSigner.signTransactionData(address: address, transaction: transaction, nonce: nonce, data: data, chainID: self.chain.getChainId())
                      switch signResult {
                          case .success(let result):
                              self.generalProvider.sendSignedTransactionData(result.data, completion: { sendResult in
                                  switch sendResult {
                                      case .success(let hash):
                                          self.nonceCache.updateNonce(address: address.addressString, chain: self.chain, nonce: txCount + 1)
                                          completion(.success(TransferTransactionResultData(hash: hash, nonce: txCount, eip1559Transaction: nil, transaction: result.tx.toSignTransactionObject())))
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
    let nonce = self.nonceCache.getCachingNonce(address: address.addressString, chain: self.chain)
    let signTx = SignTransaction(value: BigInt(0), address: address.addressString, to: collectibleAddress, nonce: nonce, data: transferData, gasPrice: gasPrice, gasLimit: gasLimit, chainID: KNGeneralProvider.shared.customRPC.chainID)
    let signResult = transactionSigner.signTransaction(address: address, transaction: signTx)
    switch signResult {
    case .success(let signData):
      KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { result in
        switch result {
        case .success(let hash):
          self.nonceCache.increaseNonce(address: address.addressString, chain: self.chain)
          completion(.success(.init(hash: hash, nonce: nonce, eip1559Transaction: nil, transaction: signTx.toSignTransactionObject(), signature: nil)))
        case .failure(let error):
          completion(.failure(error))
        }
      })
    case .failure(let error):
      completion(.failure(error))
    }
  }
  
  func sendApproveERCTokenAddress(owner: KAddress, tokenAddress: String, value: BigInt, gasPrice: BigInt, gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault, toAddress: String? = nil, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    let nonce = NonceCache.shared.getCachingNonce(address: owner.addressString, chain: self.chain)
    self.approve(owner: owner, tokenAddress: tokenAddress, currentNonce: nonce, networkAddress: toAddress ?? self.chain.proxyAddress(), gasPrice: gasPrice, gasLimit: gasLimit) { result in
      switch result {
      case .success(let txCount):
        NonceCache.shared.updateNonce(address: owner.addressString, chain: self.chain, nonce: txCount)
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func approve(owner: KAddress, tokenAddress: String, value: BigInt = Constants.maxValueBigInt, currentNonce: Int, networkAddress: String, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    web3Service.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, value: value, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    web3Service.getTransactionCount(for: owner.addressString) { result in
      switch result {
      case .success(let resp):
        txCount = max(resp, currentNonce)
      case .failure(let err):
        error = err
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }
      self.signTransactionData(forApproving: tokenAddress, owner: owner, nonce: txCount, data: encodeData, gasPrice: gasPrice, gasLimit: gasLimit) { result in
        switch result {
        case .success(let signData):
          KNGeneralProvider.shared.sendSignedTransactionData(signData.0, completion: { sendResult in
            switch sendResult {
            case .success(let hash):
              var symbol = KNSupportedTokenStorage.shared.getTokenWith(address: tokenAddress.description.lowercased())?.name ?? "Token"
              if tokenAddress.description.lowercased() == Constants.gasTokenAddress {
                symbol = "CHI"
              }
              let historyTransaction = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: symbol, transactionDetailDescription: tokenAddress.description, transactionObj: signData.1.toSignTransactionObject(), eip1559Tx: nil) //TODO: add case eip1559
              historyTransaction.hash = hash
              historyTransaction.time = Date()
              historyTransaction.nonce = txCount
              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
              completion(.success(txCount + 1))
            case .failure(let error):
              completion(.failure(error))
            }
          })
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }
  
  func signTransactionData(forApproving tokenAddress: String, owner: KAddress, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {

    let signTransaction = SignTransaction(
      value: BigInt(0),
      address: owner.addressString,
      to: tokenAddress,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    
    let signResult = transactionSigner.signTransaction(address: owner, transaction: signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success((data, signTransaction)))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }
  
}
