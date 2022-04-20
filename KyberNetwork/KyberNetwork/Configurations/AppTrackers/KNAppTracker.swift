// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore

enum KNTransactionLoadState: Int {
  case none = 0
  case done = 1
  case failed = 2
}

class KNAppTracker {
  
  var favedTokens: [String] = KNAppTracker.getListFavouriteTokens()
  static let shared = KNAppTracker()

  static let kPlatformFeeBps = 8 // 8 bps, 0.08%
  // Env
  static let kPlatformFeeKey: String = "kPlatformFeeKey"
  static let kInternalTrackerEndpointKey: String = "kInternalTrackerEndpointKey"
  static let kExternalEnvironmentKey: String = "kExternalEnvironmentKey"

  static let kTransactionLoadStateKey: String = "kTransactionLoadStateKey"
  static let kAllTransactionLoadLastBlockKey: String = "kAllTransactionLoadLastBlockKey"
  static let kInternalTransactionLoadLastBlockKey: String = "kInternalTransactionLoadLastBlockKey"
  static let kTransactionNonceKey: String = "kTransactionNonceKey"

  static let kSupportedLoadingTimeKey: String = "kSupportedLoadingTimeKey"

  static let kCurrencyTypeKey: String = "kCurrencyTypeKey"

  static let kAppStyle: String = "kAppStyle"

  static let kPushNotificationTokenKey: String = "kPushNotificationTokenKey"

  static let kForceUpdateAlertKey: String = "kForceUpdateAlertKey"

  static let kHasLoggedUserOutWithNativeSignInKey: String = "kHasLoggedUserOutWithNativeSignInKey"

  static let kHasSentPushTokenKey: String = "kHasLoggedUserOutWithNativeSignInKey"

  static let kHistoryFilterKey: String = "kHistoryFilterKey"

  static let kLastTimeAuthenticateKey: String = "kLastTimeAuthenticateKey"

  static let kFavouriteTokensKey: String = "kFavouriteTokensKey"

  static let kFavouriteMarketsKey: String = "kFavouriteMarketsKey"

  static let kTutorialCancelOpenOrderKey: String = "kTutorialCancelOpenOrderKey"
  static let kWonderWhyOrdersAreNotFilled: String = "kWonderWhyOrdersAreNotFilled"

  static let kShouldOpenLimitOrderAfterSignedInKey: String = "kShouldOpenLimitOrderAfterSignedInKey"

  static let kFirstInstallTimeKey: String = "kFirstInstallTimeKey"
  static let kFirstTimeSwapKey: String = "kFirstTimeSwapKey"
  static let kFirstTimeLimitOrderKey: String = "kFirstTimeLimitOrderKey"
  static let kFirstTimePriceAlertKey: String = "kFirstTimePriceAlertKey"
  static let kHasShownTransferConsentKey: String = "kHasShownTransferConsentKey"

  static let kSavedRestoreIDForLiveChat: String = "kSavedRestoreIDForLiveChat"

  static let userDefaults: UserDefaults = UserDefaults.standard

  static let minimumPriceAlertPercent: Double = -99.0
  static let minimumPriceAlertChangePercent: Double = 0.1 // min change 0.1%
  static let maximumPriceAlertPercent: Double = 10000.0
  static let timeToAuthenticate: Double = 60.0 // 1 minute

  static func updateInternalTrackerEndpoint(value: String) {
    userDefaults.set(value, forKey: kInternalTrackerEndpointKey)
    userDefaults.synchronize()
  }

  // MARK: External environment
  static func externalEnvironment() -> KNEnvironment {
    if let value = userDefaults.object(forKey: kExternalEnvironmentKey) as? Int, let env = KNEnvironment(rawValue: value) {
      return env
    }
    return KNEnvironment.ropsten
  }

  static func updateExternalEnvironment(_ env: KNEnvironment) {
    userDefaults.set(env.rawValue, forKey: kExternalEnvironmentKey)
    userDefaults.synchronize()
  }

  // MARK: Transaction load state
  static func transactionLoadState(for address: Address) -> KNTransactionLoadState {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return KNTransactionLoadState(rawValue: value) ?? .none
    }
    return .none
  }

  static func updateTransactionLoadState(_ state: KNTransactionLoadState, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    userDefaults.set(state.rawValue, forKey: key)
    userDefaults.synchronize()
  }

  static func lastBlockLoadAllTransaction(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kAllTransactionLoadLastBlockKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return value
    }
    return 0
  }

  static func updateAllTransactionLastBlockLoad(_ block: Int, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kAllTransactionLoadLastBlockKey + sessionID
    userDefaults.set(block, forKey: key)
    userDefaults.synchronize()
  }

  static func lastBlockLoadInternalTransaction(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kInternalTransactionLoadLastBlockKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return value
    }
    return 0
  }

  static func updateInternalTransactionLastBlockLoad(_ block: Int, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kInternalTransactionLoadLastBlockKey + sessionID
    userDefaults.set(block, forKey: key)
    userDefaults.synchronize()
  }

  static func transactionNonce(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    return userDefaults.object(forKey: key) as? Int ?? 0
  }

  static func updateTransactionNonce(_ nonce: Int, address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    userDefaults.set(nonce, forKey: key)
    userDefaults.synchronize()
  }

  // MARK: Supported Tokens
  static func updateSuccessfullyLoadSupportedTokens() {
    let time = Date().timeIntervalSince1970
    userDefaults.set(time, forKey: kSupportedLoadingTimeKey)
    userDefaults.synchronize()
  }

  static func getSuccessfullyLoadSupportedTokensDate() -> Date? {
    guard let time = userDefaults.value(forKey: kSupportedLoadingTimeKey) as? Double else {
      return nil
    }
    return Date(timeIntervalSince1970: time)
  }

  // MARK: Currency used (USD, ETH)
//  static func updateCurrencyType(_ type: KWalletCurrencyType) {
//    userDefaults.set(type.rawValue, forKey: kCurrencyTypeKey)
//    userDefaults.synchronize()
//  }
//
//  static func getCurrencyType() -> KWalletCurrencyType {
//    if let type = userDefaults.object(forKey: kCurrencyTypeKey) as? String {
//      return KWalletCurrencyType(rawValue: type) ?? .usd
//    }
//    return .usd
//  }

  // MARK: Profile base string
  static func getKyberProfileBaseString() -> String {
    return KNEnvironment.default.kyberswapURL
  }

  // MARK: App style
  static func updateAppStyleType(_ type: KNAppStyleType) {
    userDefaults.set(type.rawValue, forKey: kAppStyle)
    userDefaults.synchronize()
  }

  static func getAppStyleType() -> KNAppStyleType {
    let type = userDefaults.object(forKey: kAppStyle) as? String ?? ""
    return KNAppStyleType(rawValue: type) ?? .default
  }

  // MARK: Push notification token
  static func updatePushNotificationToken(_ token: String) {
    userDefaults.set(token, forKey: kPushNotificationTokenKey)
    userDefaults.synchronize()
  }

  static func getPushNotificationToken() -> String? {
    return userDefaults.object(forKey: kPushNotificationTokenKey) as? String
  }

  // MARK: Reset app tracker
  static func resetAppTrackerData(for address: Address) {
    self.updateAllTransactionLastBlockLoad(0, for: address)
    self.updateTransactionLoadState(.none, for: address)
    self.updateTransactionNonce(0, address: address)
    self.updateInternalTransactionLastBlockLoad(0, for: address)
  }

  static func resetAllAppTrackerData() {
    userDefaults.removeObject(forKey: kSupportedLoadingTimeKey)
    userDefaults.removeObject(forKey: kCurrencyTypeKey)
  }

  static var isPriceAlertEnabled: Bool { return true }

  static func hasLoggedUserOutWithNativeSignIn() -> Bool {
    return userDefaults.object(forKey: kHasLoggedUserOutWithNativeSignInKey) as? Bool ?? false
  }

  static func updateHasLoggedUserOutWithNativeSignIn(isTrue: Bool = true) {
    userDefaults.set(isTrue, forKey: kHasLoggedUserOutWithNativeSignInKey)
    userDefaults.synchronize()
  }

  static func hasSentPlayerIdUpdateRequest(userID: String) -> Bool {
    let key = "\(KNEnvironment.default.displayName)_\(kHasSentPushTokenKey)_\(userID)"
    return userDefaults.object(forKey: key) as? Bool ?? false
  }

  static func updateHasSentPlayerIdUpdateRequest(userID: String, hasSent: Bool) {
    let key = "\(KNEnvironment.default.displayName)_\(kHasSentPushTokenKey)_\(userID)"
    if hasSent {
      userDefaults.set(true, forKey: key)
    } else {
      userDefaults.removeObject(forKey: key)
    }
    userDefaults.synchronize()
  }

//  static func saveHistoryFilterData(_ object: KNTransactionFilter) {
//    let key = "\(KNEnvironment.default.displayName)_\(kHistoryFilterKey)"
//    userDefaults.set(json, forKey: key)
//    userDefaults.synchronize()
//    Storage.store(object, as: Constants.customFilterOptionFileName)
//  }

  static func removeHistoryFilterData() {
    let key = "\(KNEnvironment.default.displayName)_\(kHistoryFilterKey)"
    userDefaults.set(nil, forKey: key)
    userDefaults.synchronize()
  }

//  static func getLastHistoryFilterData() -> KNTransactionFilter? {
//    Storage.retrieve(Constants.customFilterOptionFileName, as: KNTransactionFilter.self)
//  }

  static func saveLastTimeAuthenticate() {
    userDefaults.set(Date().timeIntervalSince1970, forKey: kLastTimeAuthenticateKey)
    userDefaults.synchronize()
  }

  static func shouldShowAuthenticate() -> Bool {
    if let time = userDefaults.object(forKey: kLastTimeAuthenticateKey) as? Double {
      return Date().timeIntervalSince(Date(timeIntervalSince1970: time)) >= timeToAuthenticate
    }
    return true
  }

  static func getListFavouriteTokens() -> [String] {
    KNAppTracker.migrationFavoriteFromPreviousVersion()
    let filename = NSObject.getDocumentsDirectory().appendingPathComponent("\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey).txt")

    let saved = try? String(contentsOf: filename)
    if let savedString = saved {
      let addresses = savedString.components(separatedBy: ", ")
      return addresses
    } else {
      return []
    }
  }

  static func isTokenFavourite(_ address: String) -> Bool {
    return KNAppTracker.shared.favedTokens.contains(address.lowercased())
  }

  static func updateFavouriteToken(_ address: String, add: Bool) {
    KNAppTracker.migrationFavoriteFromPreviousVersion()
    let filename = NSObject.getDocumentsDirectory().appendingPathComponent("\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey).txt")
    do {
      let saved = try? String(contentsOf: filename)
      if let savedString = saved {
        var addresses = savedString.components(separatedBy: ", ")
        if add {
          if !addresses.contains(address.lowercased()) { addresses.append(address) }
        } else if let id = addresses.index(of: address.lowercased()) {
          addresses.remove(at: id)
        }
        let result = addresses.joined(separator: ", ")
        try result.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
      } else {
        if add {
          try address.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        }
      }
    } catch {
    }
    KNAppTracker.shared.favedTokens = KNAppTracker.getListFavouriteTokens()
  }

  static func migrationFavoriteFromPreviousVersion() {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey)"
    if let addresses = userDefaults.object(forKey: key) as? [String] {
      let filename = NSObject.getDocumentsDirectory().appendingPathComponent("\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey).txt")
      let result = addresses.joined(separator: ", ")
      do {
        try result.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
      } catch {}
      userDefaults.removeObject(forKey: key)
    }
  }

  static func getListFavouriteMarkets() -> [String] {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteMarketsKey)"
    return userDefaults.object(forKey: key) as? [String] ?? []
  }

  static func setListFavouriteMarkets(pairs: [String]) {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteMarketsKey)"
    let filterd = pairs.map { $0.formatMarketPairString() }
    userDefaults.set(filterd, forKey: key)
    userDefaults.synchronize()
  }

  static func cleanAllFavouriteMarkets() {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteMarketsKey)"
    userDefaults.removeObject(forKey: key)
  }

  static func updateFavouriteMarket(_ pair: String, add: Bool) {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteMarketsKey)"
    var pairs = userDefaults.object(forKey: key) as? [String] ?? []
    if add {
      let formattedPair = pair.formatMarketPairString()
      if !pairs.contains(formattedPair.uppercased()) { pairs.append(formattedPair) }
    } else if let id = pairs.index(of: pair.uppercased()) {
      pairs.remove(at: id)
    }
    userDefaults.set(pairs, forKey: key)
    userDefaults.synchronize()
  }

  static func isMarketFavourite(_ pair: String) -> Bool {
    return self.getListFavouriteMarkets().contains(pair.uppercased())
  }

  static func updateCancelOpenOrderTutorial(isRemove: Bool = false) {
    let key = "\(KNEnvironment.default.displayName)-\(kTutorialCancelOpenOrderKey)"
    userDefaults.set(isRemove ? nil : true, forKey: key)
    userDefaults.synchronize()
  }

  static func needShowCancelOpenOrderTutorial() -> Bool {
    let key = "\(KNEnvironment.default.displayName)-\(kTutorialCancelOpenOrderKey)"
    return userDefaults.value(forKey: key) == nil
  }

  static func updateWonderWhyOrdersNotFilled(isRemove: Bool = false) {
    let key = "\(KNEnvironment.default.displayName)-\(kWonderWhyOrdersAreNotFilled)"
    userDefaults.set(isRemove ? nil : true, forKey: key)
    userDefaults.synchronize()
  }

  static func needShowWonderWhyOrdersNotFilled() -> Bool {
    let key = "\(KNEnvironment.default.displayName)-\(kWonderWhyOrdersAreNotFilled)"
    return userDefaults.value(forKey: key) == nil
  }

  static func shouldOpenLimitOrderAfterSignedIn() -> Bool {
    return userDefaults.value(forKey: kShouldOpenLimitOrderAfterSignedInKey) as? Bool == true
  }

  static func updateShouldOpenLimitOrderAfterSignedIn(_ isOpen: Bool) {
    userDefaults.set(isOpen, forKey: kShouldOpenLimitOrderAfterSignedInKey)
    userDefaults.synchronize()
  }

  static func shouldShowUserTranserConsentPopUp() -> Bool {
    return userDefaults.value(forKey: kHasShownTransferConsentKey) as? Bool == true
  }

  static func updateShouldShowUserTranserConsentPopUp(_ shouldShown: Bool) {
    userDefaults.set(shouldShown, forKey: kHasShownTransferConsentKey)
    userDefaults.synchronize()
  }

  static func saveFirstInstallTimeIfNeeded() {
    if userDefaults.value(forKey: kFirstInstallTimeKey) == nil {
      userDefaults.set(Date().timeIntervalSince1970, forKey: kFirstInstallTimeKey)
      userDefaults.synchronize()
    }
  }

  static func getFirstInstallTime() -> TimeInterval {
    if let time = userDefaults.value(forKey: kFirstInstallTimeKey) as? Double {
      return time
    }
    return Date().timeIntervalSince1970
  }

  static func isNightMode() -> Bool { return true }

  static func getPlatformFee(source: Address, dest: Address) -> Int {
    let eth = KNSupportedTokenStorage.shared.ethToken
    if let weth = KNSupportedTokenStorage.shared.wethToken {
      let ethAddress = eth.addressObj
      let wethAddress = weth.addressObj
      if (source == ethAddress && dest == wethAddress) ||
        (dest == ethAddress && source == wethAddress) {
        return 0
      }
    }

    if let fee = userDefaults.object(forKey: kPlatformFeeKey) as? Int {
      return fee
    } else {
      return kPlatformFeeBps
    }
  }
}
