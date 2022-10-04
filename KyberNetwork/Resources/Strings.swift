//
//  Strings.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import Foundation

struct Strings {
  // Common
  static let ok = "ok".toBeLocalised()
  static let OK = "OK".toBeLocalised()
  static let Cancel = "Cancel".toBeLocalised()
  static let approve = "approve".toBeLocalised()
  static let cancelled = "cancelled".toBeLocalised()
  static let confirm = "confirm".toBeLocalised()
  static let cancel = "cancel".toBeLocalised()
  static let delete = "delete".toBeLocalised()
  static let next = "Next".toBeLocalised()
  
  // Actions
  static let add = "add".toBeLocalised()
  static let edit = "edit".toBeLocalised()
  static let addWatchWallet = "add.watched.wallet".toBeLocalised()
  static let editWatchWallet = "edit.watched.wallet".toBeLocalised()
  
  // Errors
  static let privateKeyError = "private.key.error".toBeLocalised()
  static let canNotGetPrivateKey = "can.not.get.private.key".toBeLocalised()
  static let invalidSession = "invalid.session".toBeLocalised()
  static let invalidSessionTryOtherQR = "invalid.session.try.other.qr".toBeLocalised()
  static let invalidEns = "invalid.ens".toBeLocalised()
  
  // Overview
  static let balanceIsEmpty = "your.balance.is.empty".toBeLocalised()
  static let notHaveLiquidityPool = "dont.have.any.liquidity.pool".toBeLocalised()
  static let notSuppliedAnyToken = "not.supply.any.token".toBeLocalised()
  static let noFavoriteToken = "no.favorite.token.yet".toBeLocalised()
  static let tokenListIsEmpty = "token.list.is.empty".toBeLocalised()
  static let notHaveAnyNFT = "not.have.any.nft".toBeLocalised()
  static let addNFT = "add.nft".toBeLocalised()
  static let supplyTokensToEarnInterest = "supply.tokens.to.earn.interest".toBeLocalised()
  
  // Explore screen
  static let explore = "explore".toBeLocalised()
  static let swap = "swap".toBeLocalised()
  static let transfer = "transfer".toBeLocalised()
  static let reward = "reward".toBeLocalised()
  static let referral = "referral".toBeLocalised()
  static let dApps = "dapps".toBeLocalised()
  static let multiSend = "multisend".toBeLocalised()
  static let multiReceive = "multi.receive".toBeLocalised()
  static let buyCrypto = "buy.crypto".toBeLocalised()
  static let promotion = "promotion".toBeLocalised()
  static let supportedPlatforms = "supported.platforms".toBeLocalised()
  static let gasFeeDescription = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
  
  // History
  static let contract = "contract".toBeLocalised()
  static let success = "success".toBeLocalised()
  static let failure = "failed".toBeLocalised()
  static let pending = "pending".toBeLocalised()
  static let unknown = "unknown".toBeLocalised()
  static let application = "application".toBeLocalised()
  static let Account = "Account".toBeLocalised()
  static let fromWallet = "from.wallet".toBeLocalised()
  static let toWallet = "to.wallet".toBeLocalised()
  static let wallet = "wallet".toBeLocalised()
  static let fromColonX = "from_colon_x".toBeLocalised()
  static let toColonX = "to_colon_x".toBeLocalised()
  static let rewardHunting = "reward.hunting".toBeLocalised()
  static let copied = "copied".toBeLocalised()
  static let to = "to".toBeLocalised()
  static let from = "from".toBeLocalised()
  static let To = "To".toBeLocalised()
  static let From = "From".toBeLocalised()
  static let receive = "receive".toBeLocalised()
  static let sender = "Sender".toBeLocalised()
  static let receiver = "Receiver".toBeLocalised()
  static let contractExecution = "contract.execution".toBeLocalised()
  static let approval = "approval".toBeLocalised()
  static let claimReward = "claim.reward".toBeLocalised()
  static let transactionSuccess = "transaction.success".toBeLocalised()
  static let transactionFailed = "transaction.failed".toBeLocalised()
  static let transactionBeingMined = "transaction.being.mined".toBeLocalised()
  static let transactionBroadcasted = "transaction.being.broadcasted".toBeLocalised()
  static let cannotCreateTransaction = "can.not.create.transaction".toBeLocalised()
  static let noTransactionFound = "no.transaction.found".toBeLocalised()
  static let transactionFee = "transaction.fee".toBeLocalised()
  static let estimatedTimeOfArrival = "estimated.time.of.arrival".toBeLocalised()
  static let xMins = "x.mins".toBeLocalised()
  static let showLess = "SHOW LESS".toBeLocalised()
  static let showMore = "SHOW MORE".toBeLocalised()
  static let showAll = "SHOW ALL".toBeLocalised()
  static let Search = "Search".toBeLocalised()
  static let searchByTokenWalletEND = "Search token, wallet address ...".toBeLocalised()
  static let findTokenByNameSymbolAddress = "Find a token by name, symbol or address".toBeLocalised()
  static let FunctionCall = "Function call".toBeLocalised()
  static let transactions = "transactions".toBeLocalised()
  
  // Wallet
  static let chooseChainWallet = "choose.chain.wallet".toBeLocalised()
  static let rewardHuntingWatchWalletErrorMessage = "reward.hunting.watch.wallet.not.supported".toBeLocalised()
  static let notHaveChainWalletPleaseCreateOrImport = "not.have.chain.wallet.please.create.or.import".toBeLocalised()
  static let pleaseSwitchTo = "Please switch to".toBeLocalised()

  // Swap
  static let invalidInput = "invalid.input".toBeLocalised()
  static let unsupported = "unsupported".toBeLocalised()
  static let amountTooBig = "amount.too.big".toBeLocalised()
  static let invalidAmount = "invalid.amount".toBeLocalised()
  static let rateMightChange = "rate.might.change".toBeLocalised()
  static let toSwap = "to swap".toBeLocalised()
  
  static let pleaseSelectSourceToken = "please.select.source.token".toBeLocalised()
  static let pleaseSelectDestToken = "please.select.dest.token".toBeLocalised()
  static let canNotSwapSameToken = "can.not.swap.same.token".toBeLocalised()
  static let pleaseEnterAmountToContinue = "please.enter.an.amount.to.continue".toBeLocalised()
  static let canNotFindExchangeRate = "Can not find the exchange rate".toBeLocalised()
  static let balanceNotEnoughToMakeTransaction = "balance.not.enough.to.make.transaction".toBeLocalised()
  static let amountTooSmallToSwap = "amount.too.small.to.perform.swap".toBeLocalised()
  static let depositMoreXOrClickAdvancedToLowerGasFee = "deposit.more.x.or.click.advanced.to.lower.gas.fee".toBeLocalised()
  static let insufficientXForTransaction = "insufficient.x.for.transaction".toBeLocalised()
  static let pleaseWaitForExpectedRateUpdate = "please.wait.for.expected.rate.updated".toBeLocalised()
  static let amountToSendGreaterThanZero = "amount.to.send.greater.than.zero".toBeLocalised()
  static let selectToken = "select.token".toBeLocalised()
  static let selectPlatformToSupply = "select.platform.to.supply.x".toBeLocalised()
  
  // Receive screen
  static let receiveWarningText = "receive_screen_warning_text".toBeLocalised()
  static let copy = "copy".toBeLocalised()
  static let share = "share".toBeLocalised()
  static let tokenTypeAddress = "%@.address".toBeLocalised()
  static let viewOnX = "view.on.%@".toBeLocalised()
  static let addressCopied = "address.copied".toBeLocalised()
  
  // Wallets
  static let walletImported = "wallet.imported".toBeLocalised()
  static let importWalletSuccess = "you.have.successfully.imported.a.wallet".toBeLocalised()
  static let failedToParseJSON = "failed.to.parse.key.json".toBeLocalised()
  static let alreadyAddedWalletAddress = "you.already.added.this.address.to.wallets".toBeLocalised()
  static let failedToCreateWallet = "failed.to.create.wallet".toBeLocalised()
  static let failedToImportWallet = "can.not.import.your.wallet".toBeLocalised()
  static let failedToImportPrivateKey = "failed.to.import.private.key".toBeLocalised()
  static let notInContact = "not.in.contact".toBeLocalised()
  static let watchWalletCannotDoThisOperation = "watch.wallet.can.not.do.this.operation".toBeLocalised()
  static let untitled = "untitled".toBeLocalised()
  static let deleteWalletConfirmMessage = "do.you.want.to.remove.this.wallet".toBeLocalised()
  static let editWalletSuccess = "edit.wallet.success".toBeLocalised()
  static let imported = "imported".toBeLocalised()
  static let walletCreatedSuccess = "you.have.successfully.created.a.new.wallet".toBeLocalised()
  static let walletCreated = "wallet.created".toBeLocalised()
  static let creating = "creating".toBeLocalised()
  static let addressExisted = "address.existed".toBeLocalised()
  static let pleaseEnterAddress = "please.enter.address".toBeLocalised()
  static let removing = "removing".toBeLocalised()
  static let watchWalletNotSupportOperation = "watch.wallet.does.not.support.operation".toBeLocalised()
  static let invalidAddress = "invalid.address".toBeLocalised()
  static let pleaseEnterValidAddress = "please.enter.a.valid.address.to.continue".toBeLocalised()
  static let backupKeystore = "backup.keystore".toBeLocalised()
  static let backupPrivateKey = "backup.private.key".toBeLocalised()
  static let backupMnemonic = "backup.mnemonic".toBeLocalised()
  static let createWallet = "create.wallet".toBeLocalised()
  static let importWallet = "import.wallet".toBeLocalised()
  static let getStarted = "get.started".toBeLocalised()
  
  // Rewards
  static let switchToBSCToClaimRewards = "switch.to.bsc.to.claim.rewards".toBeLocalised()
  
  // Settings
  static let pinCodeUpdated = "your.pin.has.been.update.successfully".toBeLocalised()
  
  // Bridge
  static let bridge = "bridge".toBeLocalised()
  static let bridgeWarningText = "Krystal strives to offer its users the best DeFi experience on a single platform. In order to do that, Krystal carefully evaluates & partners with other platforms to facilitate these services. However, Krystal does not assume any liability for any losses incurred due to any security breach on Krystal’s partners on chain contract."
  static let warningTitle = "Risk Warning"
  
  static let KrystalBridge = "Krystal Bridge".toBeLocalised()
  static let bridgeFee = "bridge.fee".toBeLocalised()
  static let skipBackupWarningText = "Warning: You must backup your wallet and keep your mnemonics secure.\n\nWhy? If you lose your device, or uninstall the app or clear app’s memory. You won’t be able to access your wallet and funds.\n\nWhy keep your backup secure? Anyone with your backup can steal your wallet assets"
  static let understand = "I understand".toBeLocalised()
  static let goBack = "Go Back".toBeLocalised()
  static let TheAboveAddressWillReceive = "The above address will receive %@ on %@".toBeLocalised()
  static let skip = "Skip?".toBeLocalised()
  static let unsupportedChain = "Unsupported chain".toBeLocalised()
  
  // History
  static let numberOfTransfers = "number.of.transfers".toBeLocalised()
  static let txHash = "tx.hash".toBeLocalised()
  static let xTransfers = "x.transfers".toBeLocalised()
  static let oneTransfer = "1 Transfer".toBeLocalised()
  
  // Scanner
  static let scanQRCode = "scan.qr.code".toBeLocalised()
  static let scanText = "scan.text".toBeLocalised()
  static let scanner = "scanner".toBeLocalised()
  
  // Swap
  static let swapNetworkFee = "swap.network.fee".toBeLocalised()
  static let swapSavedAmount = "swap.saved.amount".toBeLocalised()
  static let swapWarnPriceImpact1 = "swap.warn_price_impact_1".toBeLocalised()
  static let swapWarnPriceImpact2 = "swap.warn_price_impact_2".toBeLocalised()
  static let swapWarnPriceImpact3 = "swap.warn_price_impact_3".toBeLocalised()
  static let swapWarnPriceImpact4 = "swap.warn_price_impact_4".toBeLocalised()
  static let swapWarnPriceImpact5 = "swap.warn_price_impact_5".toBeLocalised()
  static let swapApproveWarn = "swap.warn_approve".toBeLocalised()
  static let swapRateNotFound = "swap.rate_not_found".toBeLocalised()
  static let swapSmallAmountOfQuoteTokenUsedForFee = "swap.small_amount_of_quote_token_will_be_used".toBeLocalised()
  static let swapSlippageInfo = "swap.slippage_i".toBeLocalised()
  static let swapMinReceiveInfo = "swap.min_received_i".toBeLocalised()
  static let swapTxnFeeInfo = "swap.txn_fee_i".toBeLocalised()
  static let swapTxnMaxFeeInfo = "swap.txn_fee_max_i".toBeLocalised()
  static let swapPriceImpactInfo = "swap.price_impact_i".toBeLocalised()
  static let advancedModeWarningText = "advanced.mode.warning.text".toBeLocalised()
  static let swapBest = "swap.best".toBeLocalised()
  static let swapAlertRateChanged = "swap.alert_platform_change".toBeLocalised()
  static let swapAlertPlatformChanged = "swap.alert_platform_change_could_not_update".toBeLocalised()
  static let swapRate = "rate".toBeLocalised()
  static let maxSlippage = "max.slippage".toBeLocalised()
  static let minReceived = "min.received".toBeLocalised()
  static let estNetworkFee = "est.network.fee".toBeLocalised()
  static let maxNetworkFee = "max.network.fee".toBeLocalised()
  static let priceImpact = "price.impact".toBeLocalised()
  static let route = "route".toBeLocalised()
  static let enterAnAmount = "enter.an.amount".toBeLocalised()
  static let fetchingBestRates = "fetching.best.rates".toBeLocalised()
  static let connectWallet = "connect.wallet".toBeLocalised()
  static let reviewSwap = "review.swap".toBeLocalised()
  static let insufficientTokenBalance = "insufficient.token.balance".toBeLocalised()
  static let checkingAllowance = "checking.allowance".toBeLocalised()
  static let approveToken = "approve.token".toBeLocalised()
  static let approvingToken = "approving.token".toBeLocalised()
  
  // Swap settings
  static let superFast = "super.fast".toBeLocalised()
  static let fast = "fast".toBeLocalised()
  static let regular = "regular".toBeLocalised()
  static let standard = "standard".toBeLocalised()
  static let slow = "slow".toBeLocalised()
  static let advanced = "advanced".toBeLocalised()
  static let custom = "custom".toBeLocalised()
  
  // Create Wallets
  static let recoveryPhase1 = "recovery.phrase.1".toBeLocalised()
  static let recoveryHightlightPhase1 = "recovery.hightlight.phrase.1".toBeLocalised()
  static let recoveryPhase2 = "recovery.phrase.2".toBeLocalised()
  static let recoveryHightlightPhase2 = "recovery.hightlight.phrase.2".toBeLocalised()
  static let recoveryPhase3 = "recovery.phrase.3".toBeLocalised()
  static let recoveryHightlightPhase3 = "recovery.hightlight.phrase.3".toBeLocalised()
  static let Watchlist = "Watchlist".toBeLocalised()
  
  // Promotion
  static let invalidPromotionCode = "invalid.promotion.code".toBeLocalised()
  static let enterPromotionCode = "enter.promotion.code".toBeLocalised()
  static let scanPromotionCode = "scan.promotion.code".toBeLocalised()
  static let redeeming = "redeeming".toBeLocalised()
  static let redeemFailed = "redeem.failed".toBeLocalised()
  static let redeemSuccess = "redeem.success".toBeLocalised()
  static let redeemProcessingMessage = "redeem.processing.message".toBeLocalised()
  static let redeemSuccessMessage = "redeem.success.message".toBeLocalised()
  static let redeemFailMessage = "redeem.fail.message".toBeLocalised()
  static let redeem = "redeem".toBeLocalised()
  static let redeemNow = "redeem.now".toBeLocalised()
  
  // Notifications
  static let all = "all".toBeLocalised()
  static let unread = "unread".toBeLocalised()
  static let yesterday = "yesterday".toBeLocalised()
  static let xDaysAgo = "x.days.ago".toBeLocalised()
  static let xHoursAgo = "x.hours.ago".toBeLocalised()
  static let xMinsAgo = "x.mins.ago".toBeLocalised()
  static let xSecondsAgo = "x.seconds.ago".toBeLocalised()
  static let justNow = "just.now".toBeLocalised()
  
  // Wallet connect
  static let wcConnectingDapp = "wc.connecting.dapp".toBeLocalised()
  static let wcConnectingFailed = "wc.connecting.failed".toBeLocalised()
  static let wcTryAgain = "wc.try.again".toBeLocalised()
  static let wcConnect = "wc.connect".toBeLocalised()
  static let wcConnectMessage = "wc.connect.message".toBeLocalised()
  static let wcDisconnect = "wc.disconnect".toBeLocalised()
  static let wcDisconnectConfirm = "wc.disconnect.confirm".toBeLocalised()
  static let wcCancel = "wc.cancel".toBeLocalised()
  static let wcNotSupportWatchWallet = "wc.not.support.watch.wallet".toBeLocalised()
}
