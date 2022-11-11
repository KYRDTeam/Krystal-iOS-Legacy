//
//  ApprovePendingTxInfo.swift
//  TransactionModule
//
//  Created by Com1 on 11/11/2022.
//

import UIKit
import BaseWallet

class ApprovePendingTxInfo: PendingTxInfo {
  
  var walletAddress: String
  var contractAddress: String
  
  public init(legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String, nonce: Int, walletAddress: String, contractAddress: String) {
    self.walletAddress = walletAddress
    self.contractAddress = contractAddress
    super.init(type: .approval, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash, nonce: nonce)
  }
  
  
  override public var destSymbol: String? {
      return contractAddress
  }
   
  override public var sourceSymbol: String? {
      return walletAddress
  }
  
  override public var sourceIcon: String? {
      return nil
  }
  
  override public var destIcon: String? {
      return nil
  }
  
  override public var description: String {
      return ""
  }
      
  override public var detail: String {
      return ""
  }
}
