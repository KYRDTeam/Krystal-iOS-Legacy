//
//  FeatureFlag.swift
//  Dependencies
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

public protocol FeatureFlag {
    func isFeatureEnabled(key: String, defaultValue: Bool) -> Bool
}

extension FeatureFlag {
    public func isFeatureEnabled(key: String) -> Bool {
        return isFeatureEnabled(key: key, defaultValue: false)
    }
}

public struct FeatureFlagKeys {
    public static let promotionCodeIntegration = "promotion-code"
    public static let auroraChainIntegration = "aurora-chain"
    public static let rewardHunting = "reward-hunting"
    public static let solanaChainIntegration = "solana-chain"
    public static let klaytnChainIntegration = "klaytn-chain"
    public static let tokenPool = "token-pool"
    public static let tradingView = "trading-view"
    public static let scanner = "scanner"
    public static let appBrowsing = "app-browsing"
    public static let notiV2 = "noti-v2"
    public static let earnV2 = "earn-v2"
    public static let tokenApproval = "token-approval"
    public static let unstakeWarning = "unstake-warning"
    public static let earnNewTag = "earn-new-tag"
    public static let extraReward = "extra-rewards"
    public static let loyalty = "loyalty"
    public static let historyV2 = "history-v2"
    public static let swapModule = "swap-module"
    public static let historyStats = "history-stats"
    public static let importWalletV2 = "import-wallet-v2"
    public static let backupRemind = "backup-remind"
    public static let refcode = "ref-code"
}
