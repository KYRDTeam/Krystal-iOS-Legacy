// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt
import Utilities

typealias BlankBlock = () -> Void 

enum ValidStatus: Equatable {
  case success
  case error(description: String)

  static func == (lhs: ValidStatus, rhs: ValidStatus) -> Bool {
    switch (lhs, rhs) {
    case (.success, .success):
      return true
    case (.error, .error):
      return true
    default:
      return false
    }
  }
}

public struct Constants {
  public static let keychainKeyPrefix = "com.kyberswap.ios"
  public static let transactionIsLost = "is_lost"
  public static let transactionIsCancel = "is_cancel"
  public static let isDoneShowQuickTutorialForBalanceView = "balance_tutorial_done"
  public static let isDoneShowQuickTutorialForSwapView = "swap_tutorial_done"
  public static let isDoneShowQuickTutorialForLimitOrderView = "lo_tutorial_done"
  public static let isDoneShowQuickTutorialForHistoryView = "history_tutorial_done"
  public static let kisShowQuickTutorialForLongPendingTx = "kisShowQuickTutorialForLongPendingTx"
  public static let klimitNumberOfTransactionInDB = 1000
  public static let animationDuration = 0.3
  /// Value in USD to validate if current token should display blue tick or not
  public static let hightVolAmount = 100000.0
  public static let useGasTokenDataKey = "use_gas_token_data_key"
  public static let isCreatedPassCode = "is_created_passcode"
  public static let isAppOpenAlready = "is_app_open_already"

  public static let oneSignalAppID = KNEnvironment.default == .ropsten ? "361e7815-4da2-41c9-ba0a-d35add5a58ef" : "0487532e-7b19-415b-91a1-2a285b0b8382"
  public static let gasTokenAddress = KNEnvironment.default == .ropsten ? "0x0000000000b3F879cb30FE243b4Dfee438691c04" : "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c"
  
  public static let tokenStoreFileName = "token.data"
  public static let balanceStoreFileName = "_balance.data"
  public static let nftBalanceStoreFileName = "_nft.data"
  public static let customNftBalanceStoreFileName = "_custom_nft.data"
  public static let customBalanceStoreFileName = "-custom-balance.data"
  public static let favedTokenStoreFileName = "faved_token.data"
  public static let lendingBalanceStoreFileName = "-lending-balance.data"
  public static let lendingDistributionBalanceStoreFileName = "-lending-distribution-balance.data"
  public static let liquidityPoolStoreFileName = "-liquidity-pool.data"
  public static let summaryChainStoreFileName = "-summary-chain.data"
  public static let customTokenStoreFileName = "custom-token.data"
  public static let etherscanTokenTransactionsStoreFileName = "-etherscan-token-transaction.data"
  public static let etherscanInternalTransactionsStoreFileName = "-etherscan-internal-transaction.data"
  public static let etherscanNFTTransactionsStoreFileName = "-etherscan-nft-transaction.data"
  public static let etherscanTransactionsStoreFileName = "-etherscan-transaction.data"
  public static let customFilterOptionFileName = "custom-filter-option.data"
  public static let marketingAssetsStoreFileName = "marketing-assets.data"
  public static let referralOverviewStoreFileName = "-referral-overview.data"
  public static let referralTiersStoreFileName = "-referral-tiers.data"
  public static let historyTransactionsStoreFileName = "-history-transaction.data"
  public static let notificationsStoreFileName = "notification.data"
  public static let loginTokenStoreFileName = "-login-token.data"
  public static let krytalHistoryStoreFileName = "-krytal-history.data"
  public static let coingeckoPricesStoreFileName = "coingecko-price.data"
  public static let acceptedTermKey = "accepted-terms-key"
  public static let lendingTokensStoreFileName = "lending-tokens.data"
  public static let platformWallet = KNEnvironment.default == .production ? "0x5250b8202AEBca35328E2c217C687E894d70Cd31" : "0x5250b8202AEBca35328E2c217C687E894d70Cd31"
  public static let currentChainSaveFileName = "current-chain-save-key.data"
  public static let disableTokenStoreFileName = "disable-token.data"
  public static let deleteTokenStoreFileName = "delete-token.data"
  public static let hideBalanceKey = "hide_balance_key"
  public static let viewModeStoreFileName = "view-mode.data"
  public static let historyKrystalTransactionsStoreFileName = "-krystal-history-transaction.data"
  public static let unsupportedChainHistoryTransactionsFileName = "-unsupported-chain-history-transaction.data"
  public static let gasPriceStoreFileName = "-gas_price.data"
  public static let browserFavoriteFileName = "browser-favorite.data"
  public static let browserRecentlyFileName = "browser-recently.data"
  public static let methodIdApprove = "0x095ea7b3"
  public static let currentCurrencyMode = "current_currency_mode"
  public static let multisendBscAddress = "0xA58573970cfFAd93309071cE9aff46b8A35eC62B"
  public static let maxValueBigInt = BigInt(2).power(256) - BigInt(1)
  public static let rewardHuntingPath = "reward-hunting"
  public static let multichainExplorerURL = "https://anyswap.net/explorer"
  static let maxFractionDigits: Int = 5
  public static let bridgeWarningAcceptedKey = "bridge-warning-accept-key"
  public static let didSelectAllChainOption = "did-select-all-chain-key"
  public static let supportURL = "https://t.me/KrystalDefi"
  public static let lowLimitGas = 21000
  public static let slippageRateSaveKey = "slippage-rate-saving-key"
  public static let expertModeSaveKey = "expert-mode-saving-key"
  public static let bridgeWarningSettingFile = "bridge_warning_setting.data"
  public static let defaultTokenIconURL = "https://files.kyberswap.com/DesignAssets/tokens/iOS/%@.png"
}

public struct UnitConfiguration {
  public static let gasPriceUnit: EthereumUnit = .gwei
  public static let gasFeeUnit: EthereumUnit = .ether
}

public struct DecimalNumber {
  public static let eth = 4
  public static let usd = 2
  public static let btc = 5
  public static let quote = 4
}

public struct SolConstant {
  public static let PUBLIC_KEY_LENGTH = 32
  public static let UINT_16_LENGTH = 2
  public static let UINT_32_LENGTH = 4
  public static let UINT_64_LENGTH = 8
  public static let UINT_128_LENGTH = 16
  public static let ACCOUNT_INFO_DATA_LENGTH: Int = (PUBLIC_KEY_LENGTH + PUBLIC_KEY_LENGTH
              + UINT_64_LENGTH + UINT_32_LENGTH + PUBLIC_KEY_LENGTH + 1
              + UINT_32_LENGTH + UINT_64_LENGTH + UINT_64_LENGTH
              + UINT_32_LENGTH + PUBLIC_KEY_LENGTH)

}
