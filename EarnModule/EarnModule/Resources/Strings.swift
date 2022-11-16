//
//  Strings.swift
//  SwapModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation

extension String {
    
    func toBeLocalised() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: EarnModule.bundle, value: "", comment: "")
    }
    
}

struct Strings {
    static let ok = "ok".toBeLocalised()
    static let cancel = "cancel".toBeLocalised()
    static let searchPools = "search.pools".toBeLocalised()
    static let searchToken = "search.token".toBeLocalised()
    static let Staking = "Staking".toBeLocalised()
    static let noRecordFound = "no.record.found".toBeLocalised()
    static let earnIsCurrentlyNotSupportedOnThisChainYet = "earn.is.currently.not.supported.on.this.chain.yet".toBeLocalised()
    static let cheking = "checking".toBeLocalised()
    static let stakeNow = "stake.now".toBeLocalised()
    static let emptyTokenDeposit = "no.tokens.deposited".toBeLocalised()
    static let apyTitle = "est.apy".toBeLocalised()
    static let youWillReceive = "receive.title".toBeLocalised()
    static let rate = "rate".toBeLocalised()
    static let networkFee = "network.fee".toBeLocalised()
    static let approveToken = "approve.token".toBeLocalised()
    static let confirmStake = "confirm.stake".toBeLocalised()
    static let stakeSummary = "stake.summary".toBeLocalised()
    static let youAreStaking = "you.are.staking".toBeLocalised()
    static let amount = "amount".toBeLocalised()
    static let insufficientBalance = "insufficient.balance".toBeLocalised()
    static let shouldBeAtLeast = "not.enough.min.stake.amount".toBeLocalised()
    static let shouldNoMoreThan = "higher.than.max.stake.amount".toBeLocalised()
    static let shouldBeIntervalOf = "should.be.interval.of".toBeLocalised()
    static let confirmClaim = "confirm.claim".toBeLocalised()
    static let youAreClaiming = "you.are.claiming".toBeLocalised()
    static let confirm = "confirm".toBeLocalised()
    static let defaultErrorMessage = "default.error.message".toBeLocalised()
    static let claimInProgress = "claim.in.progress".toBeLocalised()
    static let success = "success".toBeLocalised()
    static let txFailed = "tx.failed".toBeLocalised()
    static let myPortfolio = "my.portfolio".toBeLocalised()
    static let support = "support".toBeLocalised()
    static let close = "close".toBeLocalised()
    static let edit = "edit".toBeLocalised()
}
