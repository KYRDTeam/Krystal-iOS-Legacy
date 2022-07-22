//
//  EIP1559TransactionSigner.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/06/2022.
//

import Foundation
import KrystalWallets

class EIP1559TransactionSigner {
  let walletManager = WalletManager.shared
  
  func signTransaction(address: KAddress, eip1559Tx: EIP1559Transaction) -> Data? {
    do {
      let privateKey = try walletManager.exportPrivateKey(address: address)
      guard let data = Data(hexString: privateKey) else {
        return nil
      }
      return eip1559Tx.signContractGenericWithPK(data)
    } catch {
      return nil
    }
  }
}
