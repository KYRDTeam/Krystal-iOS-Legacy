// Copyright SIX DAY LLC. All rights reserved.

import Foundation

extension Data {
  var hex: String {
    return map { String(format: "%02hhx", $0) }.joined()
  }
  
  var hexEncoded: String {
    return "0x" + self.hex
  }
  
//  init(hex: String) {
//    let len = hex.count / 2
//    var data = Data(capacity: len)
//    for i in 0..<len {
//      let from = hex.index(hex.startIndex, offsetBy: i*2)
//      let to = hex.index(hex.startIndex, offsetBy: i*2 + 2)
//      let bytes = hex[from ..< to]
//      if var num = UInt8(bytes, radix: 16) {
//        data.append(&num, count: 1)
//      }
//    }
//    self = data
//  }
  
  
  func toString() -> String? {
    return String(data: self, encoding: .utf8)
  }
  
  init(_hex value: String, chunkSize: Int) {
    if value.count > chunkSize {
      self = value.chunked(into: chunkSize).reduce(NSMutableData()) { result, chunk -> NSMutableData in
        let part = Data(_hex: String(chunk))
        result.append(part)
        
        return result
      } as Data
    } else {
      self = Data(_hex: value)
    }
  }
  
  init(_hex hex: String) {
    let len = hex.count / 2
    var data = Data(capacity: len)
    for i in 0..<len {
      let from = hex.index(hex.startIndex, offsetBy: i*2)
      let to = hex.index(hex.startIndex, offsetBy: i*2 + 2)
      let bytes = hex[from ..< to]
      if var num = UInt8(bytes, radix: 16) {
        data.append(&num, count: 1)
      }
    }
    self = data
  }
}
