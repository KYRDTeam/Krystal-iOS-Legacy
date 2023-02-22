//
//  InternalHistoryTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt
import BaseWallet

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
  var tokenAddress: String?
  var transactionObject: SignTransactionObject?
  var toAddress: String?
  var eip1559Transaction: EIP1559Transaction?
  var chain: ChainType
  var extraData: InternalHistoryExtraData?
    var extraUserInfo: [String: String]?
    var extraMultisendInfo: [[String: String]]?

  init(
    type: HistoryModelType,
    state: InternalTransactionState,
    fromSymbol: String?,
    toSymbol: String?,
    transactionDescription: String,
    transactionDetailDescription: String,
    transactionObj: SignTransactionObject?,
    eip1559Tx: EIP1559Transaction?,
    extraData: InternalHistoryExtraData? = nil,
    chain: ChainType = KNGeneralProvider.shared.currentChain
  ) {
    self.type = type
    self.state = state
    self.fromSymbol = fromSymbol
    self.toSymbol = toSymbol
    self.transactionDescription = transactionDescription
    self.transactionDetailDescription = transactionDetailDescription
    self.transactionObject = transactionObj
    self.eip1559Transaction = eip1559Tx
    self.chain = chain
      self.extraUserInfo = nil
  }
  
  var gasFee: BigInt {
    guard let transactionObject = transactionObject else {
      return BigInt(0)
    }
    let gasPrice = BigInt(transactionObject.gasPrice) ?? BigInt(0)
    let gasLimit = BigInt(transactionObject.gasLimit) ?? BigInt(0)
    return gasPrice * gasLimit
  }
  
  func acceptExtraData(extraData: InternalHistoryExtraData?) {
    if self.extraData == nil {
      self.extraData = extraData
      return
    }
    guard let extraData = extraData else {
      return
    }
    self.extraData?.crosschainStatus = extraData.crosschainStatus
    if let from = extraData.from, ExtraData.terminatedStatuses.contains(from.txStatus.lowercased()) {
      self.extraData?.from = from
    }
    if let to = extraData.to, ExtraData.terminatedStatuses.contains(to.txStatus.lowercased()) {
      self.extraData?.to = extraData.to
    }
  }
  
  var transactionGasPrice: String {
    if let tx = transactionObject {
      return tx.gasPrice
    } else if let tx = eip1559Transaction {
      return tx.maxGasFee
    } else {
      return ""
    }
  }
  
  var transactionGasPriceBigInt: BigInt {
    return BigInt(self.transactionGasPrice) ?? .zero
  }
  
  var speedupGasBigInt: BigInt {
    var speedupGas = self.transactionGasPriceBigInt
    speedupGas += (speedupGas * 20 / 100) //Add 10%
    return speedupGas
  }
    
    var userData: [String: Any] {
        let txType: UserService.TransactionType
        let chainType: UserService.ChainType
        let status: UserService.TransactionState
        
        switch type {
        case .swap:
            txType = .swap
        case .withdraw:
            txType = .claim
        case .transferETH:
            txType = .transfer
        case .receiveETH:
            txType = .undefine
        case .transferToken:
            txType = .transfer
        case .receiveToken:
            txType = .undefine
        case .allowance:
            txType = .undefine
        case .earn:
            txType = .earn
        case .contractInteraction:
            txType = .undefine
        case .selfTransfer:
            txType = .transfer
        case .createNFT:
            txType = .undefine
        case .transferNFT:
            txType = .nft_transfer
        case .receiveNFT:
            txType = .undefine
        case .claimReward:
            txType = .claim
        case .multiSend:
            txType = .multisend
        case .bridge:
            txType = .bridge
        }
        
        switch chain {
        case .solana:
            chainType = .solana
        default:
            chainType = .evm
        }
        
        switch state {
        case .pending:
            status = .pending
        case .speedup:
            status = .pending
        case .cancel:
            status = .pending
        case .done:
            status = .success
        case .drop:
            status = .failed
        case .error:
            status = .failed
        }
        
        return UserService.buildTransactionParam(type: txType, chainType: chainType, txHash: hash, status: status, extra: extraUserInfo ?? [:])
    }
    
}

struct InternalHistoryExtraData: Codable {
  
  var from: ExtraBridgeTransaction?
  var to: ExtraBridgeTransaction?
  var type: String
  var crosschainStatus: String
  
  var isCompleted: Bool {
    return ExtraData.terminatedStatuses.contains(crosschainStatus.lowercased())
  }

}
