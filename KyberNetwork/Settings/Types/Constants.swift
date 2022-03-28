// Copyright SIX DAY LLC. All rights reserved.

import Foundation

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

  public static let ethMainnetPRC = CustomRPC(
    chainID: 1,
    name: "Mainnet",
    symbol: "Mainnet",
    endpoint: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointAlchemy: "https://eth-mainnet.alchemyapi.io/v2/" + KNSecret.alchemyKey,
    etherScanEndpoint: "https://etherscan.io/",
    ensAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
    wrappedAddress: "0x6172afc8c00c46e0d07ce3af203828198194620a",
    apiEtherscanEndpoint: "https://api.etherscan.io/",
    proxyAddress: "0x70270C228c5B4279d1578799926873aa72446CcD"
  )

  public static let ethRoptenPRC = CustomRPC(
    chainID: 3,
    name: "Ropsten",
    symbol: "Ropsten",
    endpoint: "https://ropsten.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://ropsten.infura.io/v3/" + KNSecret.infuraKey,
    endpointAlchemy: "https://eth-ropsten.alchemyapi.io/v2/" + KNSecret.alchemyRopstenKey,
    etherScanEndpoint: "https://ropsten.etherscan.io/",
    ensAddress: "0x112234455c3a32fd11230c42e7bccd4a84e02010",
    wrappedAddress: "0x665d34f192f4940da4e859ff7768c0a80ed3ae10",
    apiEtherscanEndpoint: "https://api-ropsten.etherscan.io/",
    proxyAddress: "0xf351Dd5EC89e5ac6c9125262853c74E714C1d56a"
  )

  public static let ethStaggingPRC = CustomRPC(
    chainID: 1,
    name: "Mainnet",
    symbol: "Mainnet",
    endpoint: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointAlchemy: "https://eth-mainnet.alchemyapi.io/v2/" + KNSecret.alchemyKey,
    etherScanEndpoint: "https://etherscan.io/",
    ensAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
    wrappedAddress: "0x6172afc8c00c46e0d07ce3af203828198194620a",
    apiEtherscanEndpoint: "https://api.etherscan.io/",
    proxyAddress: "0x70270C228c5B4279d1578799926873aa72446CcD"
  )
  
  public static let bscMainnetPRC = CustomRPC(
    chainID: 56,
    name: "MainnetBSC",
    symbol: "MainnetBSC",
    endpoint: "https://bsc.krystal.app/v1/mainnet/geth?appId=prod-krystal-ios",
    endpointKyber: "https://bsc-dataseed1.defibit.io/",
    endpointAlchemy: "https://bsc-dataseed1.ninicoin.io/",
    etherScanEndpoint: "https://bscscan.com/",
    ensAddress: "",
    wrappedAddress: "0x465661625B3B96b102a49e07E2Eb31cC9F5cE58B",
    apiEtherscanEndpoint: "https://api.bscscan.com/",
    proxyAddress: "0x051DC16b2ECB366984d1074dCC07c342a9463999"
  )
  
  public static let bscRoptenPRC = CustomRPC(
    chainID: 97,
    name: "RopstenBSC",
    symbol: "RopstenBSC",
    endpoint: "https://data-seed-prebsc-1-s1.binance.org:8545/",
    endpointKyber: "https://data-seed-prebsc-2-s1.binance.org:8545/",
    endpointAlchemy: "https://data-seed-prebsc-1-s1.binance.org:8545/",
    etherScanEndpoint: "https://testnet.bscscan.com/",
    ensAddress: "",
    wrappedAddress: "0x813718C50df497BC136d5d6dfc0E0aDA8AB0C93e",
    apiEtherscanEndpoint: "https://api-testnet.bscscan.com/",
    proxyAddress: "0xA58573970cfFAd93309071cE9aff46b8A35eC62B"
  )
  
  public static let polygonMainnetPRC = CustomRPC(
    chainID: 137,
    name: "MaticMainnet",
    symbol: "MaticMainnet",
    endpoint: "https://polygon-rpc.com/",
    endpointKyber: "https://rpc-mainnet.maticvigil.com",
    endpointAlchemy: "https://polygon-rpc.com/",
    etherScanEndpoint: "https://polygonscan.com/",
    ensAddress: "",
    wrappedAddress: "0xf351Dd5EC89e5ac6c9125262853c74E714C1d56a",
    apiEtherscanEndpoint: "https://api.polygonscan.com/",
    proxyAddress: "0x70270c228c5b4279d1578799926873aa72446ccd"
  )
  
  public static let polygonRoptenPRC = CustomRPC(
    chainID: 80001,
    name: "MaticRopsten",
    symbol: "MaticRopsten",
    endpoint: "https://rpc-mumbai.maticvigil.com/",
    endpointKyber: "https://rpc-mumbai.maticvigil.com/",
    endpointAlchemy: "https://rpc-mumbai.maticvigil.com/",
    etherScanEndpoint: "https://mumbai.polygonscan.com/",
    ensAddress: "",
    wrappedAddress: "0xB8C6Ed80688a2674623D89A0AaBD3a87507B1868",
    apiEtherscanEndpoint: "https://api.polygonscan.com",
    proxyAddress: "0x6deaAe9d76991db2943064Bca84e00f63c46C0A3"
  )
  
  public static let avalancheRoptenPRC = CustomRPC(
    chainID: 43113,
    name: "Avalanche FUJI C-Chain",
    symbol: "AVAX",
    endpoint: "https://api.avax-test.network/ext/bc/C/rpc",
    endpointKyber: "https://api.avax-test.network/ext/bc/C/rpc",
    endpointAlchemy: "https://api.avax-test.network/ext/bc/C/rpc",
    etherScanEndpoint: "https://cchain.explorer.avax-test.network/",
    ensAddress: "",
    wrappedAddress: "",
    apiEtherscanEndpoint: "",
    proxyAddress: "0xAE0505c0C30Dc0EA077cDB4Ed1B2BB894D9c6B65"
  )

  public static let avalancheMainnetPRC = CustomRPC(
    chainID: 43114,
    name: "Avalanche Mainnet C-Chain",
    symbol: "AVAX",
    endpoint: "https://api.avax.network/ext/bc/C/rpc",
    endpointKyber: "https://avalanche.krystal.app/v1/mainnet/geth?appId=\(KNEnvironment.default.endpointName)-krystal-ios",
    endpointAlchemy: "https://api.avax.network/ext/bc/C/rpc",
    etherScanEndpoint: "https://cchain.explorer.avax.network/",
    ensAddress: "",
    wrappedAddress: "",
    apiEtherscanEndpoint: "",
    proxyAddress: "0x8C27aBf05DE1d4847c3924566C3cBAFec6eFb42A"
  )

  public static let cronosMainnetRPC = CustomRPC (
    chainID: 25,
    name: "Cronos",
    symbol: "CRO",
    endpoint: "https://evm-cronos.crypto.org",
    endpointKyber: "https://evm-cronos.crypto.org",
    endpointAlchemy: "https://evm-cronos.crypto.org",
    etherScanEndpoint: "https://cronoscan.com/",
    ensAddress: "",
    wrappedAddress: "",
    apiEtherscanEndpoint: "",
    proxyAddress: "0xf351Dd5EC89e5ac6c9125262853c74E714C1d56a"
  )

  public static let fantomMainnetRPC = CustomRPC (
    chainID: 250,
    name: "Fantom",
    symbol: "FTM",
    endpoint: "https://rpc.ftm.tools",
    endpointKyber: "https://fantom.krystal.app/v1/mainnet/geth?appId=\(KNEnvironment.default.endpointName)-krystal-ios",
    endpointAlchemy: "https://rpc.ftm.tools",
    etherScanEndpoint: "https://ftmscan.com/",
    ensAddress: "",
    wrappedAddress: "",
    apiEtherscanEndpoint: "",
    proxyAddress: "0xf351Dd5EC89e5ac6c9125262853c74E714C1d56a"
  )

  public static let arbitrumMainnetRPC = CustomRPC (
    chainID: 42161,
    name: "Arbitrum One",
    symbol: "ETH",
    endpoint: "https://arb1.arbitrum.io/rpc",
    endpointKyber: "https://arbitrum.knstats.com/v1/mainnet/geth?appId=\(KNEnvironment.default.endpointName)-krystal-ios",
    endpointAlchemy: "https://arb1.arbitrum.io/rpc",
    etherScanEndpoint: "https://arbiscan.io/",
    ensAddress: "",
    wrappedAddress: "",
    apiEtherscanEndpoint: "",
    proxyAddress: "0x864F01c5E46b0712643B956BcA607bF883e0dbC5"
  )

  public static let bnbAddress = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  public static let ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  public static let maticAddress = "0xcccccccccccccccccccccccccccccccccccccccc"
  public static let avaxAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  public static let cronosAddress = "0xffffffffffffffffffffffffffffffffffffffff"
  public static let fantomAddress = "0xdddddddddddddddddddddddddddddddddddddddd"
  public static let arbitrumAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  public static let multisendBscAddress = "0xA58573970cfFAd93309071cE9aff46b8A35eC62B"
}

public struct UnitConfiguration {
  public static let gasPriceUnit: EthereumUnit = .gwei
  public static let gasFeeUnit: EthereumUnit = .ether
}

public struct DecimalNumber {
  public static let eth = 4
  public static let usd = 2
  public static let btc = 5
  public static let bnb = 4
  public static let matic = 4
  public static let avax = 4
  public static let cro = 4
  public static let ftm = 4
}
