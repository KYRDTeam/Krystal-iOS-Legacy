//
//  AdvancedSearchToken.swift
//  Services
//
//  Created by Tung Nguyen on 23/12/2022.
//

import Foundation

public struct AdvancedSearchResponse: Decodable {
    public var data: AdvancedSearchData?
}

public struct AdvancedSearchData: Decodable {
    public var tokens: [AdvancedSearchToken]?
}

public struct AdvancedSearchToken: Decodable {
    public var id: String
    public var chainId: Int
    public var chainName: String
    public var chainLogo: String
    public var name: String
    public var symbol: String
    public var decimals: Int
    public var logo: String
    public var tag: String
    public var usdValue: Double?
    public var tvl: Double?
}
