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
  static let searchPools = "search.pools".toBeLocalised()
  static let searchToken = "search.token".toBeLocalised()
  static let Staking = "Staking".toBeLocalised()
  static let noRecordFound = "no.record.found".toBeLocalised()
  static let earnIsCurrentlyNotSupportedOnThisChainYet = "earn.is.currently.not.supported.on.this.chain.yet".toBeLocalised()
  static let emptyTokenDeposit = "no.tokens.deposited".toBeLocalised()
}
