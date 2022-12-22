//
//  TxRecord.swift
//  Services
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation

struct HistoryResponse: Decodable {
    var timestamp: Int?
    var data: [TxRecord]?
}

public struct TxRecord: Decodable {
    
    public struct Chain: Decodable {
        public var chainName: String
        public var chainId: Int
        public var chainLogo: String
    }
    
    public struct TokenTransfer: Decodable {
        public var otherAddress: String
        public var amount: String
        public var valueInUsd: Double
        public var currentPrice: Double
        public var historicalPrice: Double
        public var historicalValueInUsd: Double
        public var token: TokenInfo?
    }
    
    public struct TokenApproval: Decodable {
        public var token: TokenInfo?
        public var spenderAddress: String
        public var spenderName: String
        public var amount: String
    }
    
    public struct ContractInteraction: Decodable {
        public var contractName: String
        public var methodName: String
    }
    
    public var walletAddress: String
    public var chain: Chain
    public var txHash: String
    public var blockTime: Int
    public var blockNumber: Int
    public var gas: Int
    public var gasPrice: String
    public var nativeTokenPrice: Double
    public var historicalNativeTokenPrice: Double
    public var status: String
    public var contractInteraction: ContractInteraction?
    public var from: String
    public var to: String
    public var tokenTransfers: [TokenTransfer]?
    public var tokenApproval: TokenApproval?
}
