//
//  FeatureFlagManager.swift
//  KyberNetwork
//
//  Created by Com1 on 28/02/2022.
//

import LaunchDarkly

struct FeatureFlagKeys {
  static let bifinityIntegration = "bifinity-integration"
  static let promotionCodeIntegration = "promotion-code"
  static let auroraChainIntegration = "aurora-chain"
  static let rewardHunting = "reward-hunting"
  static let solanaChainIntegration = "solana-chain"
  static let klaytnChainIntegration = "klaytn-chain"
  static let bridgeIntegration = "cross-chain-bridge"
  static let advancedSearch = "advanced-search"
  static let tokenPool = "token-pool"
  static let tradingView = "trading-view"
}

class FeatureFlagManager {
  static let shared = FeatureFlagManager()

  func configClient(session: KNSession?) {
    var currentAddress = session?.wallet.addressString ?? ""
    if KNGeneralProvider.shared.currentChain != .solana {
      currentAddress = currentAddress.lowercased()
    }

    var config = LDConfig(mobileKey: KNEnvironment.default.mobileKey)
    config.backgroundFlagPollingInterval = 60
    let user = LDUser(key: currentAddress)
    if let client = LDClient.get() {
      client.identify(user: user)
    }
    LDClient.start(config: config, user: user) {
      KNNotificationUtil.postNotification(for: kUpdateFeatureFlag)
    }
  }

  func showFeature(forKey flagKey: String) -> Bool {
    guard let client = LDClient.get() else { return false }
    return client.variation(forKey: flagKey, defaultValue: false)
  }
}

func runIfFeatureEnabled(key: String, block: () -> ()) {
  if FeatureFlagManager.shared.showFeature(forKey: key) {
    block()
  }
}
