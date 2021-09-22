//
//  KNEnvironment+Kyber.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 22/09/2021.
//

import Foundation

extension KNEnvironment {
  var avalancheRPC: CustomRPC {
    switch self {
    case .ropsten:
      return Constants.avalancheRoptenPRC
    default:
      return Constants.avalancheMainnetPRC
    }
  }
}
