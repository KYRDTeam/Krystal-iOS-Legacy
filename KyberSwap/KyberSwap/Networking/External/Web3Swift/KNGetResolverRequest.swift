// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Foundation
import BigInt
import TrustKeystore
import TrustCore

struct KNGetResolverRequest: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_node\",\"type\":\"bytes32\"}],\"name\":\"resolver\",\"outputs\":[{\"name\":\"\",\"type\":\"address\"}],\"payable\":false,\"type\":\"function\"}"

  let nameHash: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetResolverRequest.abi), [\"\(nameHash)\"])"
    return .script(command: run)
  }
}

struct KNGetResolverResponse: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('address', '\(data)')"
    return .script(command: run)
  }
}
