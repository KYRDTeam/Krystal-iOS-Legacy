//
//  EIP1559TransactionSigner.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import KrystalWallets

public class EIP1559TransactionSigner {
    let walletManager = WalletManager.shared
    
    public init() {}
    
    public func signTransaction(address: KAddress, eip1559Tx: EIP1559Transaction) -> Data? {
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
