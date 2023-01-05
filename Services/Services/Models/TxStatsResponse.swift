//
//  TxStatsResponse.swift
//  Services
//
//  Created by Tung Nguyen on 05/01/2023.
//

import Foundation

public struct TxStatsResponse: Decodable {
    public var data: TxStatsData?
}

public struct ChainTxStats: Decodable {
    public var chainId: Int
    public var chainName: String
    public var chainLogo: String
    public var totalTx: Int
    public var totalGasSpent: String
    public var totalGasSpentUsd: Double
    public var totalVolumeUsd: Double
}

public struct TxStatsData: Decodable {
    public var userAddress: String?
    public var statsByChain: [String: ChainTxStats]?
}
