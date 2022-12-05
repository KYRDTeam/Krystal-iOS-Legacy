//
//  SwapBuildTxRequest.swift
//  Services
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation

public struct SwapBuildTxRequest {
    public let userAddress: String
    public let src: String
    public let dest: String
    public let srcQty: String
    public let minDesQty: String
    public let gasPrice: String
    public let nonce: Int
    public let hint: String
    public let useGasToken: Bool
    
    public init(userAddress: String, src: String, dest: String, srcQty: String, minDesQty: String, gasPrice: String, nonce: Int, hint: String, useGasToken: Bool) {
        self.userAddress = userAddress
        self.src = src
        self.dest = dest
        self.srcQty = srcQty
        self.minDesQty = minDesQty
        self.gasPrice = gasPrice
        self.nonce = nonce
        self.hint = hint
        self.useGasToken = useGasToken
    }
    
}
