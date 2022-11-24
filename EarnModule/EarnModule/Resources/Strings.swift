//
//  Strings.swift
//  SwapModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation
import UIKit

extension String {
    
    func toBeLocalised() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: EarnModule.bundle, value: "", comment: "")
    }
  
  func htmlAttributedString(size: CGFloat) -> NSAttributedString? {
      let htmlTemplate = """
            <!doctype html>
            <html>
              <head>
                <style>
                  body {
                    color: rgba(255, 255, 255, 0.5);
                    font-family: 'Karla';
                    font-size: \(size)px;
                  }
                  a:link, a:visited { color: #1DE9B6; }
                </style>
              </head>
              <body>
                \(self)
              </body>
            </html>
            """
      
      guard let data = htmlTemplate.data(using: .utf8) else {
        return nil
      }
      
      guard let attributedString = try? NSAttributedString(
        data: data,
        options: [.documentType: NSAttributedString.DocumentType.html],
        documentAttributes: nil
      ) else {
        return nil
      }
      
      return attributedString
    }
    
}

struct Strings {
    static let ok = "ok".toBeLocalised()
    static let cancel = "cancel".toBeLocalised()
    static let searchPools = "search.pools".toBeLocalised()
    static let searchToken = "search.token".toBeLocalised()
    static let staking = "Staking".toBeLocalised()
    static let stake = "Stake".toBeLocalised()
    static let unstake = "Unstake".toBeLocalised()
    static let availableToUnstake = "available.to.unstake".toBeLocalised()
    static let availableToWithdraw = "available.to.withdraw".toBeLocalised()
    static let noRecordFound = "no.record.found".toBeLocalised()
    static let earnIsCurrentlyNotSupportedOnThisChainYet = "earn.is.currently.not.supported.on.this.chain.yet".toBeLocalised()
    static let checking = "checking".toBeLocalised()
    static let stakeNow = "stake.now".toBeLocalised()
    static let emptyTokenDeposit = "no.tokens.deposited".toBeLocalised()
    static let apyTitle = "est.apy".toBeLocalised()
    static let youWillReceive = "receive.title".toBeLocalised()
    static let rate = "rate".toBeLocalised()
    static let networkFee = "network.fee".toBeLocalised()
    static let approveToken = "approve.token".toBeLocalised()
    static let confirmStake = "confirm.stake".toBeLocalised()
    static let confirmUnstake = "confirm.unstake".toBeLocalised()
    static let confirmWithdraw = "confirm.withdraw".toBeLocalised()
    static let stakeSummary = "stake.summary".toBeLocalised()
    static let unStakeSummary = "unStake.summary".toBeLocalised()
    static let withdrawSummary = "withdraw.summary".toBeLocalised()
    static let youAreStaking = "you.are.staking".toBeLocalised()
    static let youAreUnstaking = "you.are.unStaking".toBeLocalised()
    static let youAreWithdrawing = "you.are.withdrawing".toBeLocalised()
    static let amount = "amount".toBeLocalised()
    static let insufficientBalance = "insufficient.balance".toBeLocalised()
    static let insufficientQuoteBalance = "insufficient.quote.balance".toBeLocalised()
    static let shouldBeAtLeast = "not.enough.min.stake.amount".toBeLocalised()
    static let shouldNoMoreThan = "higher.than.max.stake.amount".toBeLocalised()
    static let shouldBeIntervalOf = "should.be.interval.of".toBeLocalised()
    static let confirmClaim = "confirm.claim".toBeLocalised()
    static let youAreClaiming = "you.are.claiming".toBeLocalised()
    static let confirm = "confirm".toBeLocalised()
    static let defaultErrorMessage = "default.error.message".toBeLocalised()
    static let claimInProgress = "claim.in.progress".toBeLocalised()
    static let myPortfolio = "my.portfolio".toBeLocalised()
    static let close = "close".toBeLocalised()
    static let edit = "edit".toBeLocalised()
    static let supplyingInProgress = "supplying.in.progress".toBeLocalised()
    static let stakingInProgress = "staking.in.progress".toBeLocalised()
    static let unstakeInProgress = "unstake.in.progress".toBeLocalised()
    static let approveInProgress = "approve.in.progress".toBeLocalised()
    static let approveFail = "approve.fail".toBeLocalised()
    static let success = "success".toBeLocalised()
    static let txFailed = "tx.failed".toBeLocalised()
    static let viewMyPool = "view.my.pool".toBeLocalised()
    static let viewMyPortfolio = "view.my.portfolio".toBeLocalised()
    static let support = "support".toBeLocalised()
    static let unstakeToken = "unstake.token".toBeLocalised()
    static let itTakeAboutXDaysToUnstake = "it.take.about.x.days.to.unstake".toBeLocalised()
    static let avaxUnstakeTime = "avax.unstake.time".toBeLocalised()
    static let bnbUnstakeTime = "bnb.unstake.time".toBeLocalised()
    static let ftmUnstakeTime = "ftm.unstake.time".toBeLocalised()
    static let maticUnstakeTime = "matic.unstake.time".toBeLocalised()
    static let solUnstakeTime = "sol.unstake.time".toBeLocalised()
    static let youWillReceiveYourIn = "you.will.receive.your.in".toBeLocalised()
    static let amountQuoteTokenUsedForFee = "use.amount.of.quote.token.for.fee.message".toBeLocalised()
    static let yourStakingBalanceIsNotSufficient = "your.staking.balance.is.not.suffcient".toBeLocalised()
    static let connectWallet = "connect.wallet".toBeLocalised()
    
    static let supply = "supply".toBeLocalised()
    static let supplyNow = "supply.now".toBeLocalised()
    static let withdraw = "withdraw".toBeLocalised()
    static let stakeXOnY = "stake.x.on.y".toBeLocalised()
    static let supplyXOnY = "supply.x.on.y".toBeLocalised()
    static let availableToSupply = "available.to.supply".toBeLocalised()
    static let availableToStake = "available.to.stake".toBeLocalised()
    static let youAreSupplying = "you.are.supplying".toBeLocalised()
    static let stakingProjections = "staking.projections".toBeLocalised()
    static let supplyingProjections = "supplying.projections".toBeLocalised()
    static let confirmSupply = "confirm.supply".toBeLocalised()
    static let supplySummary = "supply.summary".toBeLocalised()
    static let mySupply = "my.supply".toBeLocalised()
    static let unstakingInProgress = "unstaking.in.progress".toBeLocalised()
}
