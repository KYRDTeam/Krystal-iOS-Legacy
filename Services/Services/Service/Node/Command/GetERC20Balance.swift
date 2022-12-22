// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct GetERC20BalanceEncode: Web3Request {
    typealias Response = String

    static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"}],\"name\":\"balanceOf\",\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

    let address: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.encodeFunctionCall(\(GetERC20BalanceEncode.abi), [\"\(address)\"])"
        return .script(command: run)
    }
}

struct GetERC20BalanceDecode: Web3Request {
    typealias Response = String

    let data: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
        return .script(command: run)
    }
}

struct GetMultipleERC20BalancesEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"reserve\",\"type\":\"address\"},{\"name\":\"tokens\",\"type\":\"address[]\"}],\"name\":\"getBalances\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let address: String
  let tokens: [String]

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(GetMultipleERC20BalancesEncode.abi), [\"\(address)\", \"\(tokens.description)\"])"
     return .script(command: run)
  }
}

struct GetMultipleERC20BalancesDecode: Web3Request {
  typealias Response = [String]

  let data: String

  var type: Web3RequestType {
      let run = "web3.eth.abi.decodeParameter('uint256[]', '\(data)')"
      return .script(command: run)
  }
}

struct GetERC721BalanceEncode: Web3Request {
    typealias Response = String

    static let abi = "{\"constant\":true,\"inputs\":[{\"internalType\":\"address\",\"name\":\"_owner\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"balanceOf\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

    let address: String
  let id: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.encodeFunctionCall(\(GetERC721BalanceEncode.abi), [\"\(address)\", \"\(id)\"])"
        return .script(command: run)
    }
}

struct GetERC721BalanceDecode: Web3Request {
    typealias Response = String

    let data: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
        return .script(command: run)
    }
}

struct GetERC1155OwnerOfEncode: Web3Request {
    typealias Response = String

    static let abi = "{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"ownerOf\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"}"

  let id: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.encodeFunctionCall(\(GetERC1155OwnerOfEncode.abi), [\"\(id)\"])"
        return .script(command: run)
    }
}

struct GetERC1155OwnerOfDecode: Web3Request {
    typealias Response = String

    let data: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.decodeParameter('address', '\(data)')"
        return .script(command: run)
    }
}
