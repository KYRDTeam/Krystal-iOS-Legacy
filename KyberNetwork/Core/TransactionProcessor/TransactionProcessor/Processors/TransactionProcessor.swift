//
//  TransactionProcessor.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/06/2022.
//

import Foundation
import KrystalWallets
import Result
import BigInt

protocol TransactionProcessor {
  func transferNFT(transferData: Data, from: KAddress, to: String, gasLimit: BigInt, gasPrice: BigInt, amount: Int, isERC721: Bool, collectibleAddress: String, advancedPriorityFee: String?, advancedMaxfee: String?, advancedNonce: String?, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> Void)
  func transfer(address: KAddress, transaction: UnconfirmedTransaction, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ())
  func cancel(address: KAddress, transaction: InternalHistoryTransaction, gasLimit: String, maxPriorityFee: String, maxGasFee: String, completion: @escaping (Result<String, AnyError>) -> Void)
  func speedUp(address: KAddress, transaction: InternalHistoryTransaction, gasLimit: String, maxPriorityFee: String, maxGasFee: String, completion: @escaping (Result<String, AnyError>) -> Void)
}
