//
//  TransferNFTExtraData.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import Foundation
import TransactionModule

class TransferNFTExtraData: TxTrackingExtraData {
    let nftInfo: String
    let nftType: String
    let collectibleAddress: String
    let destAddress: String
    
    enum CodingKeys: String, CodingKey {
        case nftInfo, nftType, collectibleAddress, destAddress
    }
    
    init(nftInfo: String, nftType: String, collectibleAddress: String, destAddress: String) {
        self.nftInfo = nftInfo
        self.nftType = nftType
        self.collectibleAddress = collectibleAddress
        self.destAddress = destAddress
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nftInfo, forKey: .nftInfo)
        try container.encode(nftType, forKey: .nftType)
        try container.encode(collectibleAddress, forKey: .collectibleAddress)
        try container.encode(destAddress, forKey: .destAddress)
    }
}
