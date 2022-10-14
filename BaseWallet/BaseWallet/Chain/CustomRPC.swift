//
//  CustomRPC.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation

public struct CustomRPC {
    public let chainID: Int
    public let type: String
    public let name: String
    public let symbol: String
    public let endpoint: String
    public let endpointKyber: String
    public let endpointAlchemy: String
    public let etherScanEndpoint: String
    public let webScanName: String
    public let ensAddress: String
    public let wrappedAddress: String
    public let apiEtherscanEndpoint: String
    public let proxyAddress: String
    public let quoteTokenAddress: String
    public let chainIcon: String
    public let quoteToken: String
    public let apiChainPath: String
}

extension CustomRPC: Equatable {
    public static func == (lhs: CustomRPC, rhs: CustomRPC) -> Bool {
        return  lhs.chainID == rhs.chainID &&
                lhs.type == rhs.type &&
                lhs.name == rhs.name &&
                lhs.symbol == rhs.symbol &&
                lhs.endpoint == rhs.symbol &&
                lhs.endpointKyber == rhs.endpointKyber &&
                lhs.endpointAlchemy == rhs.endpointAlchemy &&
                lhs.webScanName == rhs.webScanName &&
                lhs.proxyAddress == rhs.proxyAddress &&
                lhs.quoteTokenAddress == rhs.quoteTokenAddress &&
                lhs.chainIcon == rhs.chainIcon &&
                lhs.quoteToken == rhs.quoteToken &&
                lhs.apiChainPath == rhs.apiChainPath
    }
}
