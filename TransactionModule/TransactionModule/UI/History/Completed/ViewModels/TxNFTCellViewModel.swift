//
//  TxNFTCellViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 26/12/2022.
//

import Foundation
import Services

struct TxNFTCellViewModel {
    var imageUrl: String?
    var tokenId: String
    var amount: Int
    var symbol: String
    var isPositiveAmount: Bool
    
    var amountString: String {
        let symbolString = symbol.isEmpty ? "" : " \(symbol)"
        return "\(amount)\(symbolString) #\(tokenId)"
    }
    
    init(token: TokenInfo, amount: Int, tokenId: String) {
        self.imageUrl = token.logo
        self.tokenId = tokenId
        self.amount = amount
        self.symbol = token.symbol
        self.isPositiveAmount = amount > 0
    }
}
