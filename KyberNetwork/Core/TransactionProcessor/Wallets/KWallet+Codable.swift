//
//  Wallet+Codable.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/06/2022.
//

import Foundation
import KrystalWallets

extension KWallet: Codable {
  
  enum CodingKeys: String, CodingKey {
    case id, importType, name, secureKey
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(importType.rawValue, forKey: .importType)
    try container.encode(name, forKey: .name)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let id = try container.decode(String.self, forKey: .id)
    let importType = KImportType(rawValue: try container.decode(Int.self, forKey: .importType)) ?? .mnemonic
    let name = try container.decode(String.self, forKey: .name)
    self.init(id: id, importType: importType, name: name)
  }

}
