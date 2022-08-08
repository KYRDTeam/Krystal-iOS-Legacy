//
//  ScannerUtilsTests.swift
//  KrystalUnitTests
//
//  Created by Tung Nguyen on 04/08/2022.
//

import Foundation
@testable import Krystal
import XCTest

class ScannerUtilTestCase: XCTestCase {
  
  func test_formattedText_ethPublicKey() {
    let text1 = "ethereum:0xb5616DC78E7F32672e71621cAEDd81B0AF940976"
    let formatted1 = ScannerUtils.formattedText(text: text1, forType: .ethPublicKey)
    XCTAssertEqual(formatted1, "0xb5616DC78E7F32672e71621cAEDd81B0AF940976")
    
    let text2 = "ethereum:0xb5616DC78E7F32672e71621cAEDd81B0AF940976@123"
    let formatted2 = ScannerUtils.formattedText(text: text2, forType: .ethPublicKey)
    XCTAssertEqual(formatted2, "0xb5616DC78E7F32672e71621cAEDd81B0AF940976")
    
    let text3 = "0xb5616DC78E7F32672e71621cAEDd81B0AF940976"
    let formatted3 = ScannerUtils.formattedText(text: text3, forType: .ethPublicKey)
    XCTAssertEqual(formatted3, "0xb5616DC78E7F32672e71621cAEDd81B0AF940976")
  }
  
  func test_isValid_ethPublicKey() {
    XCTAssertFalse(ScannerUtils.isValid(text: "0xb5616DC78E7F32672e71621cAEDd81B0AF94097", forType: .ethPublicKey))
    XCTAssertTrue(ScannerUtils.isValid(text: "0xb5616DC78E7F32672e71621cAEDd81B0AF940976", forType: .ethPublicKey))
  }
  
  func test_isValid_solPublicKey() {
    XCTAssertFalse(ScannerUtils.isValid(text: "9jHyieb6LF3MUbNcoSaC7yXYs9qc7Xbf7", forType: .solPublicKey))
    XCTAssertTrue(ScannerUtils.isValid(text: "9jHyieb6LF3MUbNcoSaC7yXYs9qc7Xbf7nDEhx1Wi7zL", forType: .solPublicKey))
  }
  
  func test_isValid_solPrivateKey() {
    XCTAssertFalse(ScannerUtils.isValid(text: "4tt2RUx13XwyczSPSNpqVnGyq3rohDWnWi6Woutw7twJzXxVHvDpp2uCknrk7PerhDVqxHdj18rgZecrRCiDo", forType: .solPrivateKey))
    
    // This is a test wallet
    XCTAssertTrue(ScannerUtils.isValid(text: "4tt2RUx13XwyczSPSNpqVnGyq3rohDWnWi6Woutw7twJzXxVHvDpp2uCknrk7PerhDVqxHdj18rgZecrRCiDoFnE", forType: .solPrivateKey))
    
    // This is a test wallet
    
    XCTAssertTrue(ScannerUtils.isValid(text: "[43,223,112,153,62,136,228,153,47,143,81,172,242,104,187,179,183,249,38,29,178,102,11,170,244,186,39,179,141,214,65,136,230,47,219,27,85,68,170,52,163,174,177,192,67,183,82,101,220,93,199,31,117,136,120,167,103,92,14,99,4,253,91,146]", forType: .solPrivateKey))
    
    XCTAssertFalse(ScannerUtils.isValid(text: "[43,223,112,153,62,136,228,153,47,143,81,172,242,104,187,179,183,249,38,29,178,102,11,170,244,186,39,179,141,214,65,136,230,47,219,27,85,68,170,52,163,174,177,192,67,183,82,101,220,93,199,31,117,136,120,167,103,92,14,99,4,146]", forType: .solPrivateKey))
  }
  
}
