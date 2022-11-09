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
  static let cheking = "Checking".toBeLocalised()
  static let stakeNow = "Stake Now".toBeLocalised()
  static let emptyTokenDeposit = "no.tokens.deposited".toBeLocalised()
  static let apyTitle = "APY (Est. Yield".toBeLocalised()
  static let youWillReceive = "You will receive".toBeLocalised()
  static let rate = "Rate".toBeLocalised()
  static let networkFee = "Network Fee".toBeLocalised()
  static let approveToken = "approve.token".toBeLocalised()
}
