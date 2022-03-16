//
//  FeatureFlagManager.swift
//  KyberNetwork
//
//  Created by Com1 on 28/02/2022.
//

import LaunchDarkly

let mobileKey = "mob-23b6e6df-bf90-494b-90e9-85c1d59ab4a2"

public struct FeatureFlagKeys {
  public static let bifinityIntegration = "bifinity-integration"
}

class FeatureFlagManager {
  static let shared = FeatureFlagManager()

  func configClient(session: KNSession) {
    let currentAddress = session.wallet.address.description.lowercased()

    var config = LDConfig(mobileKey: mobileKey)
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
    let client = LDClient.get()!
    return client.variation(forKey: flagKey, defaultValue: false)
  }
}
