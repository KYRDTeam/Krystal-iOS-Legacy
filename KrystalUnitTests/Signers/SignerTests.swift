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
    let transaction = SignTransaction(
      value: BigInt("1000000000000000"),
      address: "0x8d61ab7571b117644a52240456df66ef846cd999",
      to: "0x8d61ab7571b117644a52240456df66ef846cd999",
      nonce: 330,
      data: Data(),
      gasPrice: BigInt("100000000000"),
      gasLimit: BigInt("180000"),
      chainID: 250
    )
    
    let signer = EIP155Signer(chainId: BigInt(transaction.chainID))
    let hash = signer.hash(transaction: transaction)
    XCTAssertEqual(
      hash.toHexString(),
      "4ab7720e91fb575b285bc9fd0f4e29311b8b97844aa63eef70b2831eb1412c1e"
    )
    
  }
  
}
