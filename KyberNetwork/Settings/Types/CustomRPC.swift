// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct CustomRPC {
  let chainID: Int
  let type: String
  let name: String
  let symbol: String
  let endpoint: String
  let endpointKyber: String
  let endpointAlchemy: String
  let etherScanEndpoint: String
  let webScanName: String
  let ensAddress: String
  let wrappedAddress: String
  let apiEtherscanEndpoint: String
  let proxyAddress: String
  let quoteTokenAddress: String
  let chainIcon: String
  let quoteToken: String
  let apiChainPath: String
}

extension CustomRPC: Equatable {
  public static func == (lhs: CustomRPC, rhs: CustomRPC) -> Bool {
    return
      lhs.chainID == rhs.chainID &&
      lhs.type == rhs.type &&
      lhs.name == rhs.name &&
      lhs.symbol == rhs.symbol &&
      lhs.endpoint == rhs.symbol &&
      lhs.endpointKyber == rhs.endpointKyber &&
      lhs.endpointAlchemy == rhs.endpointAlchemy &&
      lhs.webScanName == rhs.webScanName &&
      lhs.proxyAddress == rhs.proxyAddress &&
      lhs.quoteTokenAddress == rhs.quoteTokenAddress &&
      lhs.chainIcon == rhs.chainIcon &&
      lhs.quoteToken == rhs.quoteToken &&
      lhs.apiChainPath == rhs.apiChainPath
  }
}
