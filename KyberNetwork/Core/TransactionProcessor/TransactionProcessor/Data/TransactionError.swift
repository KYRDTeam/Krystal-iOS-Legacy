//
//  TransactionSigningError.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/06/2022.
//

import Foundation

enum TransactionError: Error {
  case failedToTransfer
  case failedToSignTransaction
  case failedToCancelTransaction
  case methodNotSupported
  case failToGetRecentBlockHash
  case failToGetSenderWalletData
  case failToGetReceiverWalletData
}
