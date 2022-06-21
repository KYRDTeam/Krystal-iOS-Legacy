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
      address: "0x8D61aB7571b117644A52240456DF66EF846cd999",
      to: "0x8D61aB7571b117644A52240456DF66EF846cd999",
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
  }
  
}
