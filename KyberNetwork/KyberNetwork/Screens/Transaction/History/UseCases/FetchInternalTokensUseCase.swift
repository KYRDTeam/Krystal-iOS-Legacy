//
//  InternalFetchTokensUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchInternalTokensUseCase: FetchTokensUseCase {
  
  func execute() -> [String] {
    return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
  }
  
}
