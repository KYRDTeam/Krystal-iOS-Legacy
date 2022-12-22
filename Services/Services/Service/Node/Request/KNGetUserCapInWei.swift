// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KNGetUserCapInWeiEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"user\",\"type\":\"address\"}],\"name\":\"getUserCapInWei\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let address: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetUserCapInWeiEncode.abi), [\"\(address)\"])"
    return .script(command: run)
  }
}

struct KNGetUserCapInWeiDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
    return .script(command: run)
  }
}
