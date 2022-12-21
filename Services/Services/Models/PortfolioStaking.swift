//
//  PortfolioStaking.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 13/10/2022.
//

import Foundation
import BigInt
import Utilities

// MARK: - PendingUnstakesResponse
public struct PendingUnstakesResponse: Codable {
  public let pendingUnstakes: [PendingUnstake]
}

// MARK: - PendingUnstake
public struct PendingUnstake: Codable {
  public let chainID: Int
  public let address, symbol: String
  public let logo: String
  public let balance: String
  public let decimals: Int
  public let platform: Platform
  public let extraData: StakingExtraData
  public let priceUsd: Double
    
    public init(chainID: Int, address: String, symbol: String, logo: String, balance: String, decimals: Int, platform: Platform, extraData: StakingExtraData, priceUsd: Double) {
        self.chainID = chainID
        self.address = address
        self.symbol = symbol
        self.logo = logo
        self.balance = balance
        self.decimals = decimals
        self.platform = platform
        self.extraData = extraData
        self.priceUsd = priceUsd
    }

    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case address, symbol, logo, balance, decimals, platform, extraData, priceUsd
    }
}

// MARK: - ExtraData
public struct StakingExtraData: Codable {
  public let status, nftID: String?
    public init(status: String) {
        self.status = status
        self.nftID = nil
    }

    enum CodingKeys: String, CodingKey {
        case status
        case nftID = "nftId"
    }
}

// MARK: - Platform
public struct Platform: Codable {
  public let name: String
  public let logo: String
  public let type, desc: String
    
    public init(name: String, logo: String) {
        self.name = name
        self.logo = logo
        self.type = ""
        self.desc = ""
    }
    
    public func toEarnPlatform() -> EarnPlatform {
        return EarnPlatform(platform: self, apy: -1, tvl: -1)
    }
}

// MARK: - EarningBalancesResponse
public struct EarningBalancesResponse: Codable {
  public let earningBalances: [EarningBalance]
}

// MARK: - EarningBalance
public struct EarningBalance: Codable {
    public let chainID: Int
    public let platform: Platform
    public let stakingToken, toUnderlyingToken: IngToken
    public let underlyingUsd, apy, ratio, rewardApy: Double
    public let status: StatusClass
    
    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case platform, stakingToken, toUnderlyingToken, underlyingUsd, apy, ratio, status, rewardApy
    }
    
    func usdBigIntValue() -> BigInt? {
        if let toUnderlyingBalanceBigInt = BigInt(toUnderlyingToken.balance) {
            return BigInt(underlyingUsd * pow(10.0 , Double(toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(toUnderlyingToken.decimals)))
        }
        return nil
    }
    
    public func usdValue() -> Double {
        if let usdBigIntValue = usdBigIntValue() {
            return usdBigIntValue.doubleValue(decimal: toUnderlyingToken.decimals)
        }
        return 0.0
    }
    
    public func balanceString() -> String {
        var toUnderlyingBalanceString = "---"
        if let toUnderlyingBalanceBigInt = BigInt(toUnderlyingToken.balance) {
            if toUnderlyingBalanceBigInt < BigInt(pow(10.0, Double(toUnderlyingToken.decimals - 6))) {
                toUnderlyingBalanceString = "< 0.000001 \(toUnderlyingToken.symbol)"
            } else {
                toUnderlyingBalanceString = toUnderlyingBalanceBigInt.shortString(decimals: toUnderlyingToken.decimals) + " " + toUnderlyingToken.symbol
            }
        }
        return toUnderlyingBalanceString
    }
    
    public func usdDetailString(totalValue: Double) -> String {
        var detailString = "---"
        if let usdBigIntValue = usdBigIntValue() {
            detailString = "$" + usdBigIntValue.shortString(decimals: toUnderlyingToken.decimals, maxFractionDigits: 2) + " | " + StringFormatter.percentString(value: usdValue() / totalValue)
        }
        return detailString
    }
}

public struct StatusClass: Codable {
    public let value: String
    public let detail: String

    enum CodingKeys: String, CodingKey {
        case value
        case detail
    }
}

// MARK: - IngToken
public struct IngToken: Codable {
  public let address, symbol: String
  public let logo: String
  public let balance: String
  public let decimals: Int
    
    public func toToken() -> Token {
        return Token(name: symbol, symbol: symbol, address: address, decimals: decimals, logo: logo)
    }
}

public struct WrapInfo: Codable {
    public let isWrappable: Bool
    public let wrapAddress: String
}

// MARK: - OptionDetailResponse
public struct OptionDetailResponse: Codable {
    public let earningTokens: [EarningToken]
    public let poolAddress: String
    public var validation: EarnOptionValidation?
    public let wrap: WrapInfo?
    public var token: TokenInfo?
}
// MARK: - EarningToken
public struct EarningToken: Codable {
    public let addressStr, address, symbol, name: String
    public let decimals: Int
    public let logo: String
    public let tag: String
    public let exchangeRate: Double
    public let desc: String
    public let requireApprove: Bool
}

public struct EarnOptionValidation: Codable {
    public var minStakeAmount: Double?
    public var maxStakeAmount: Double?
    public var minUnstakeAmount: Double?
    public var maxUnstakeAmount: Double?
    public var stakeInterval: Double?
}
