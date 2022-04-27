//
//  UnconfirmedSolTransaction.swift
//  KyberNetwork
//
//  Created by Com1 on 21/04/2022.
//

import Foundation
import BigInt

enum SolTransferType {
  case sol(destination: String)
  case splToken(TokenObject)
  
  func tokenObject() -> TokenObject {
    switch self {
    case .sol:
      return KNGeneralProvider.shared.quoteTokenObject
    case .splToken(let object):
      return object
    }
  }
}

struct UnconfirmedSolTransaction {
  let value: BigInt
  let to: String
  let data: Data?
  let fee: BigInt
  let lamportPerSignature: BigInt = SolFeeCoordinator.shared.lamportPerSignature
  let totaSignature: BigInt = BigInt(1)
  var mintTokenAddress: String?
  var decimal: Int?
  let transferType: SolTransferType
}
