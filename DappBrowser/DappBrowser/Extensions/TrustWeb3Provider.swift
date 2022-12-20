//
//  TrustWeb3Provider.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 12/12/2022.
//

import Foundation
import TrustWeb3Provider

extension TrustWeb3Provider {
    static func createEthereum(address: String, chainId: Int, rpcUrl: String) -> TrustWeb3Provider {
        return TrustWeb3Provider(config: .init(ethereum: .init(address: address, chainId: chainId, rpcUrl: rpcUrl)))
    }
}
