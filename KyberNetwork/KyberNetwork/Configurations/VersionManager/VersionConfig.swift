//
//  VersionConfig.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/03/2023.
//

import Foundation

struct VersionConfig: Decodable {
    var name: String
    var status: VersionStatus
    var releaseNote: String
    
    enum CodingKeys: String, CodingKey {
        case name, status
        case releaseNote = "release_note"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.status = VersionStatus(value: try container.decode(String.self, forKey: .status))
        self.releaseNote = try container.decode(String.self, forKey: .releaseNote)
    }
}
