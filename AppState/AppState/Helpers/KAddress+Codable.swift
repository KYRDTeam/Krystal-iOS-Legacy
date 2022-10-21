//
//  KAddress+Codable.swift
//  AppState
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import KrystalWallets

extension KAddress: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id, walletID, addressType, name, addressString
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(walletID, forKey: .walletID)
        try container.encode(addressType.rawValue, forKey: .addressType)
        try container.encode(name, forKey: .name)
        try container.encode(addressString, forKey: .addressString)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let walletID = try container.decode(String.self, forKey: .walletID)
        let addressType = KAddressType(rawValue: try container.decode(Int.self, forKey: .addressType)) ?? .evm
        let name = try container.decode(String.self, forKey: .name)
        let addressString = try container.decode(String.self, forKey: .addressString)
        self.init(id: id, walletID: walletID, addressType: addressType, name: name, addressString: addressString)
    }
    
}
