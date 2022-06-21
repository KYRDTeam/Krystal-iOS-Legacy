//
//  WalletManagerTests.swift
//  KrystalWalletManagerTests
//
//  Created by Tung Nguyen on 03/06/2022.
//

import Foundation
import XCTest
@testable import KrystalWallets

class WalletManagerTests: XCTestCase {
  
  var sut: WalletManager = .shared
  
  // Only use test wallets
  func testImportMnemonic() {
    let wallet = try! sut.import(mnemonic: "rely gentle ready someone hub liar hurt tennis pact deliver income matrix", name: "test_wallet_import_from_mnemonic")
    let addresses = sut.getAllAddresses(walletID: wallet.id)
    XCTAssertEqual(addresses[0].addressString, "0xE2dE5d59D937E11f11F6013502674a9B07D411b3")
    XCTAssertEqual(addresses[1].addressString, "9jHyieb6LF3MUbNcoSaC7yXYs9qc7Xbf7nDEhx1Wi7zL")

    let privateKey0 = try! sut.exportPrivateKey(walletID: wallet.id, addressType: .solana)
    XCTAssertEqual(privateKey0, "5o42V1bDDAvFvehNrNr9EXyVwy1C3Z9y69GLo5sebiYAaMqEGP6MsrZbuxom35kzVRJPupxUhpm4MRA4eicki7Ki")

    let privateKey1 = try! sut.exportPrivateKey(walletID: wallet.id, addressType: .evm)
    XCTAssertEqual(privateKey1, "abcdef")
  }
  
  func testImportSolPrivateKey() {
    let wallet = try! sut.import(
      privateKey: "5o42V1bDDAvFvehNrNr9EXyVwy1C3Z9y69GLo5sebiYAaMqEGP6MsrZbuxom35kzVRJPupxUhpm4MRA4eicki7Ki",
      addressType: .solana,
      name: "test_sol_wallet_import_from_private_key"
    )
    
    XCTAssertEqual(
      sut.getAllAddresses(walletID: wallet.id)[0].addressString,
      "9jHyieb6LF3MUbNcoSaC7yXYs9qc7Xbf7nDEhx1Wi7zL"
    )
    
    let privateKey = try! sut.exportPrivateKey(walletID: wallet.id, addressType: .solana)
    XCTAssertEqual(
      privateKey,
      "5o42V1bDDAvFvehNrNr9EXyVwy1C3Z9y69GLo5sebiYAaMqEGP6MsrZbuxom35kzVRJPupxUhpm4MRA4eicki7Ki"
    )
  }
  
  func testImportEvmPrivateKey() {
    let wallet = try! sut.import(
      privateKey: "d9e77170f725c62c25954b7a3dd32218192cbf4f92adeeecd888007621ce8003",
      addressType: .evm,
      name: "test_evm_wallet_import_from_private_key"
    )
    
    XCTAssertEqual(
      sut.getAllAddresses(walletID: wallet.id)[0].addressString,
      "0xD5b7028406e01c68b7Ef55E9Ca0D75be9eC44C33"
    )
    
    let privateKey = try! sut.exportPrivateKey(walletID: wallet.id, addressType: .evm)
    XCTAssertEqual(
      privateKey,
      "d9e77170f725c62c25954b7a3dd32218192cbf4f92adeeecd888007621ce8003"
    )
  }
  
}
