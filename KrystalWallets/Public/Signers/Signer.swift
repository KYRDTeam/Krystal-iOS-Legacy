//
//  Signer.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 09/06/2022.
//

import Foundation

public enum SigningError: Error {
    case addressNotFound
    case cannotSignMessage
    case cannotSignTx
}


public protocol KSignerProtocol {
    func signTransaction(address: KAddress, hash: Data) throws -> Data
    func signMessage(address: KAddress, message: String, addPrefix: Bool) throws -> Data
    func signMessageHash(address: KAddress, data: Data, addPrefix: Bool) throws -> Data
}
