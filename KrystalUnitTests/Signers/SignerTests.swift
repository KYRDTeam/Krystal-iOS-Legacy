//
//  SignerTests.swift
//  KyberNetworkTests
//
//  Created by Tung Nguyen on 14/06/2022.
//

import Foundation
import XCTest
import BigInt
@testable import KrystalWallets
@testable import Krystal

class SignerTests: XCTestCase {
  
  func testSignTransaction() {
    let walletManager = WalletManager.shared
    let transaction = SignTransaction(
      value: BigInt("1000000000000000"),
      address: "0x1d16814135fda79700ec09c43c38ed8341f3f7b0",
      to: "0x1d16814135fda79700ec09c43c38ed8341f3f7b0",
      nonce: 1269,
      data: Data(),
      gasPrice: BigInt("5000000000"),
      gasLimit: BigInt("25200"),
      chainID: 56
    )
    
    let signer = EIP155Signer(chainId: BigInt(transaction.chainID))
    let hash = signer.hash(transaction: transaction)
    XCTAssertEqual(
      hash.toHexString(),
      "01c910b675297eb4619cbe91f6ded66ce497dad543f4d13a066db179a9750dc7"
    )
    
    // This is a test wallet
    do {
      let wallet = try! walletManager.import(
        privateKey: "5c1a9c1522e8668d9272b8d064141b55237b0b3ff527e49431145c5f0534c0b2",
        addressType: .evm, name: "000"
      )
      let ethSigner = EthSigner()
      let address = walletManager.getAllAddresses(walletID: wallet.id).first!
      let signature = try! ethSigner.signHash(address: address, hash: hash)
      XCTAssertEqual(
        signature.toHexString(),
        "1e2b401c653677581aabc5afca31d294ef4a5460733d2b7eb3e09891581ce47f126fc61ce257af0f42e40d5cac77d353ac290665686f43f103fef0cd6389c32501"
      )
    } catch {
      XCTFail(error.localizedDescription)
    }

  }
  
}
