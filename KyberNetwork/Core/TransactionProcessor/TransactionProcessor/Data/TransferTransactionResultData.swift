//
//  SignedTransactionData.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/06/2022.
//

import Foundation

struct TransferTransactionResultData {
  var hash: String
  var nonce: Int?
  var eip1559Transaction: EIP1559Transaction?
  var transaction: SignTransactionObject?
  var signature: String?
}
