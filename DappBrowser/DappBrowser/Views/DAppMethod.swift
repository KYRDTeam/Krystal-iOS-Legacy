//
//  DAppMethod.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 12/12/2022.
//

import Foundation

enum DAppMethod: String, Decodable, CaseIterable {
    case signRawTransaction
    case signTransaction
    case signMessage
    case signTypedMessage
    case signPersonalMessage
    case sendTransaction
    case ecRecover
    case requestAccounts
    case watchAsset
    case addEthereumChain
    case switchEthereumChain // legacy compatible
    case switchChain
}
