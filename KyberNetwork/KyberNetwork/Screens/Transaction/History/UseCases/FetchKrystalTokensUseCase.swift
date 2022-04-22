//
//  KrystalFetchTokensUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class FetchKrystalTokensUseCase: FetchTokensUseCase {
  
  func execute() -> [String] {
    return EtherscanTransactionStorage.shared.getEtherscanToken().map { $0.symbol }
  }
  
}
