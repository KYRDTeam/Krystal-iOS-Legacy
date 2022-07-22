//
//  SolanaTransactionProcessor.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 15/06/2022.
//

import Foundation
import KrystalWallets
import Result
import BigInt

class SolanaTransactionProcessor: TransactionProcessor {
  
  let serumService: SolanaSerumService
  let solanaSigner: SolanaSigner
  
  init() {
    serumService = SolanaSerumService()
    solanaSigner = SolanaSigner()
  }
  
  func transfer(address: KAddress, transaction: UnconfirmedTransaction,
                completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ()) {
    switch transaction.transferType {
    case .ether:
      sendSOL(address: address, transaction: transaction, completion: completion)
    case .token(let token):
      sendSPL(address: address, token: token, transaction: transaction, completion: completion)
    }
  }
  
  func cancel(address: KAddress, transaction: InternalHistoryTransaction,
              gasLimit: String, maxPriorityFee: String, maxGasFee: String,
              completion: @escaping (Result<String, AnyError>) -> Void) {
    completion(.failure(AnyError(TransactionError.methodNotSupported)))
  }
  
  func speedUp(address: KAddress, transaction: InternalHistoryTransaction,
               gasLimit: String, maxPriorityFee: String, maxGasFee: String,
               completion: @escaping (Result<String, AnyError>) -> Void) {
    completion(.failure(AnyError(TransactionError.methodNotSupported)))
  }
  
  func sendSOL(address: KAddress, transaction: UnconfirmedTransaction,
               completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ()) {
    serumService.getRecentBlockhash { recentBlockHash in
      guard let recentBlockHash = recentBlockHash else {
        completion(.failure(AnyError(TransactionError.failToGetRecentBlockHash)))
        return
      }
      do {
        let encodedString = try self.solanaSigner.signTransferTransaction(address: address, recipient: transaction.to ?? "", value: UInt64(transaction.value), recentBlockhash: recentBlockHash)
        self.serumService.sendSignedTransaction(signedTransaction: encodedString) { signature in
          guard let signature = signature else {
            completion(.failure(AnyError(TransactionError.failedToTransfer)))
            return
          }
          completion(.success(.init(hash: signature)))
        }
      } catch {
        completion(.failure(AnyError(TransactionError.failedToSignTransaction)))
      }
    }
  }
  
  func sendSPL(address: KAddress, token: TokenObject, transaction: UnconfirmedTransaction,
               completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> ()) {
    serumService.getTokenAccountsByOwner(ownerAddress: address.addressString, tokenAddress: token.address) { senderBalance, senderTokenAddress in
      guard let senderTokenAddress = senderTokenAddress else {
        completion(.failure(.init(TransactionError.failToGetSenderWalletData)))
        return
      }
      self.serumService.getTokenAccountsByOwner(ownerAddress: transaction.to ?? "", tokenAddress: token.address) { receiptBalance, receiptAddress in
        
        self.serumService.getRecentBlockhash { blockhash in
          guard let blockhash = blockhash else {
            completion(.failure(.init(TransactionError.failToGetRecentBlockHash)))
            return
          }
          let receiveTokenAddress = receiptAddress ?? self.solanaSigner.generateTokenAccountAddress(receiptWalletAddress: transaction.to ?? "", tokenMintAddress: token.address)
          
          do {
            let signedTxString = try self.solanaSigner.signTokenTransferTransaction(address: address, tokenMintAddress: token.address, senderTokenAddress: senderTokenAddress, recipientTokenAddress: receiveTokenAddress, amount: UInt64(transaction.value), recentBlockhash: blockhash, tokenDecimals: UInt32(token.decimals))
            self.serumService.sendSignedTransaction(signedTransaction: signedTxString) { signature in
              guard let signature = signature else {
                completion(.failure(AnyError(TransactionError.failedToTransfer)))
                return
              }
              let signTxObject = SignTransactionObject(
                value: transaction.value.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: token.decimals),
                from: address.addressString, to: transaction.to, nonce: 0, data: Data(),
                gasPrice: transaction.estimatedFee?.description ?? "0",
                gasLimit: transaction.estimatedFee?.description ?? "0",
                chainID: ChainType.solana.getChainId(), reservedGasLimit: ""
              )
              
              completion(.success(.init(hash: signature, transaction: signTxObject)))
            }
          } catch {
            completion(.failure(.init(TransactionError.failedToSignTransaction)))
          }
        }
        
      }
    }
  }
  
  func transferNFT(transferData: Data, from: KAddress, to: String, gasLimit: BigInt, gasPrice: BigInt, amount: Int, isERC721: Bool, collectibleAddress: String, advancedPriorityFee: String?, advancedMaxfee: String?, advancedNonce: String?, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> Void) {
    fatalError("Method not supported")
  }

}
