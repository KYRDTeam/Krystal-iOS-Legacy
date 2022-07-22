//
//  TransactionSigner.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/06/2022.
//

import Foundation
import KrystalWallets
import BigInt
import Result
import TrustCore

class EthereumTransactionSigner {
  
  func signTransactionData(address: KAddress, transaction: UnconfirmedTransaction, nonce: Int, data: Data?, chainID: Int) -> Result<(data: Data, tx: SignTransaction), AnyError> {
    let defaultGasLimit: BigInt = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transaction.transferType.tokenObject())
    let signTransaction: SignTransaction = SignTransaction(
      value: transaction.transferType.isETHTransfer() ? transaction.value : BigInt(0),
      address: address.addressString,
      to: addressToSend(transaction),
      nonce: nonce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: chainID
    )
    
    let signResult = self.signTransaction(address: address, transaction: signTransaction)
    switch signResult {
    case .success(let data):
      return .success((data: data, tx: signTransaction))
    case .failure(let error):
      return .failure(AnyError(error))
    }
  }
  
  func signTransaction(address: KAddress, transaction: SignTransaction) -> Result<Data, AnyError> {
    do {
      let signer: Signer
      if transaction.chainID == 0 {
          signer = HomesteadSigner()
      } else {
          signer = EIP155Signer(chainId: BigInt(transaction.chainID))
      }

      let hash = signer.hash(transaction: transaction)
      let signature = try EthSigner().signHash(address: address, hash: hash)
      let (r, s, v) = signer.values(transaction: transaction, signature: signature)
      let data = RLP.encode([
          transaction.nonce,
          transaction.gasPrice,
          transaction.gasLimit,
          transaction.to.map { Data(hexString: $0) ?? Data() } ?? Data(),
          transaction.value,
          transaction.data,
          v, r, s,
      ])!
      return .success(data)
    } catch {
      return .failure(AnyError(error))
    }
  }
  
  private func addressToSend(_ transaction: UnconfirmedTransaction) -> String? {
    switch transaction.transferType {
    case .ether:
      return transaction.to
    case .token(let token):
      return token.addressObj.description
    }
  }
  
}
