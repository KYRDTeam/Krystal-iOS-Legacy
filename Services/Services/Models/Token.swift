//
//  Token.swift
//  Services
//
//  Created by Tung Nguyen on 17/10/2022.
//

import Foundation
import AppState

public struct Token: Codable, Equatable, Hashable {
    public private(set) var address: String
    public private(set) var name: String
    public private(set) var symbol: String
    public private(set) var decimals: Int
    public private(set) var logo: String
    public private(set) var tag: String?

    public init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.symbol = dictionary["symbol"] as? String ?? ""
        self.address = (dictionary["address"] as? String ?? "")
        if AppState.shared.currentChain == .solana {
            if let addressStr = dictionary["addressStr"] as? String, !addressStr.isEmpty {
                self.address = addressStr
            }
        }
        self.decimals = dictionary["decimals"] as? Int ?? 0
        self.logo = dictionary["logo"] as? String ?? ""
        if let tag = dictionary["tag"] as? String, !tag.isEmpty {
            self.tag = tag
        }
    }

    public init(name: String, symbol: String, address: String, decimals: Int, logo: String) {
        self.name = name
        self.symbol = symbol
        self.address = address
        self.decimals = decimals
        self.logo = logo
    }
  
    public func isQuoteToken() -> Bool {
        return self.symbol.lowercased() == AppState.shared.currentChain.quoteToken().lowercased()
    }
    
//  func getBalanceBigInt() -> BigInt {
//    let balance = BalanceStorage.shared.balanceForAddress(self.address)
//    return BigInt(balance?.balance ?? "") ?? BigInt(0)
//  }
}
