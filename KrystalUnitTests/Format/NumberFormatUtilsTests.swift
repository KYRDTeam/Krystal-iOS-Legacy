//
//  NumberFormatUtilsTests.swift
//  KrystalUnitTests
//
//  Created by Tung Nguyen on 08/08/2022.
//

import Foundation
import XCTest
import BigInt
@testable import Krystal

class NumberFormatUtilsTests: XCTestCase {
  
  func testFormatGasFee() {
    // 0.123
    let value1 = BigInt("123000000000000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value1), "0.123")
    
    // 0.1234000123
    let value2 = BigInt("123400012300000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value2), "0.1234")
    
    // 0.0000123456
    let value3 = BigInt("12345600000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value3), "0.00001234")
    
    // 0.0000001234
    let value4 = BigInt("123400000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value4), "0.00000012")
    
    // 0.000000001234
    let value5 = BigInt("1234000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value5), "0")
    
    // 12.34502001
    let value6 = BigInt("12345020010000000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value6), "12.34")
    
    // 12.000123
    let value7 = BigInt("12000123000000000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value7), "12")
    
    // 1234.34502001
    let value8 = BigInt("1234345020010000000000")
    XCTAssertEqual(NumberFormatUtils.gasFee(value: value8), "1,234.34")
  }
  
}
