// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Foundation
import BigInt
import Web3

struct KNGetAddressFromResolverRequest: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_node\",\"type\":\"bytes32\"}],\"name\":\"addr\",\"outputs\":[{\"name\":\"\",\"type\":\"address\"}],\"payable\":false,\"type\":\"function\"}"

  let nameHash: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetAddressFromResolverRequest.abi), [\"\(nameHash)\"])"
    return .script(command: run)
  }
}

struct KNGetAddressFromResolverResponse: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('address', '\(data)')"
    return .script(command: run)
  }
}
