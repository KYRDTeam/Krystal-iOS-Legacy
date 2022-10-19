//
//  Strings.swift
//  SwapModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation

extension String {
    
    func toBeLocalised() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: SwapModule.bundle, value: "", comment: "")
    }
    
}

struct Strings {
    static let invalidInput = "invalid.input".toBeLocalised()
    static let unsupported = "unsupported".toBeLocalised()
    static let amountTooBig = "amount.too.big".toBeLocalised()
    static let invalidAmount = "invalid.amount".toBeLocalised()
    static let rateMightChange = "rate.might.change".toBeLocalised()
    static let toSwap = "to swap".toBeLocalised()
    
    static let superFast = "super.fast".toBeLocalised()
    static let fast = "fast".toBeLocalised()
    static let regular = "regular".toBeLocalised()
    static let standard = "standard".toBeLocalised()
    static let slow = "slow".toBeLocalised()
    static let advanced = "advanced".toBeLocalised()
    static let custom = "custom".toBeLocalised()
    
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
    
    static let canNotSwapSameToken = "can.not.swap.same.token".toBeLocalised()
    static let pleaseEnterAmountToContinue = "please.enter.an.amount.to.continue".toBeLocalised()
    static let canNotFindExchangeRate = "can.not.find.exchange.rate".toBeLocalised()
    static let balanceNotEnoughToMakeTransaction = "balance.not.enough.to.make.transaction".toBeLocalised()
    static let amountTooSmallToSwap = "amount.too.small.to.perform.swap".toBeLocalised()
    static let depositMoreXOrClickAdvancedToLowerGasFee = "deposit.more.x.or.click.advanced.to.lower.gas.fee".toBeLocalised()
    static let insufficientXForTransaction = "insufficient.x.for.transaction".toBeLocalised()
    static let pleaseWaitForExpectedRateUpdate = "please.wait.for.expected.rate.updated".toBeLocalised()
    static let amountToSendGreaterThanZero = "amount.to.send.greater.than.zero".toBeLocalised()
    static let selectToken = "select.token".toBeLocalised()
    static let selectPlatformToSupply = "select.platform.to.supply.x".toBeLocalised()
    
    static let transactionFailed = "transaction.failed".toBeLocalised()
}
