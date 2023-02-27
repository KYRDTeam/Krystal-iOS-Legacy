//
//  StakingTrackingExtraData.swift
//  EarnModule
//
//  Created by Tung Nguyen on 27/02/2023.
//

import Foundation
import TransactionModule

class StakingTrackingExtraData: TxTrackingExtraData {
    var token: String
    var tokenAmount: Double
    var stakeToken: String
    var platform: String
    
    enum CodingKeys: String, CodingKey {
        case token, tokenAmount, stakeToken, platform
    }
    
    init(token: String, tokenAmount: Double, stakeToken: String, platform: String) {
        self.token = token
        self.tokenAmount = tokenAmount
        self.stakeToken = stakeToken
        self.platform = platform
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(tokenAmount, forKey: .tokenAmount)
        try container.encode(stakeToken, forKey: .stakeToken)
        try container.encode(platform, forKey: .platform)
    }
}
