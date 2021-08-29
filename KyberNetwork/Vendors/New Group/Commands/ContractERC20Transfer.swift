// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

struct ContractERC20Transfer: Web3Request {
    typealias Response = String

    let amount: BigInt
    let address: String

    var type: Web3RequestType {
        let run = "web3.eth.abi.encodeFunctionCall({\"constant\": false, \"inputs\": [ { \"name\": \"_to\", \"type\": \"address\" }, { \"name\": \"_value\", \"type\": \"uint256\" } ], \"name\": \"transfer\", \"outputs\": [ { \"name\": \"success\", \"type\": \"bool\" } ], \"type\": \"function\"} , [\"\(address)\", \"\(amount.description)\"])"
        return .script(command: run)
    }
}

struct ContractNFTTransfer: Web3Request {
  typealias Response = String
  
  static let abiERC721 = "{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"
  
  static let abiERC1155 = "{\"constant\":false,\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"
  
  let from: String
  let to: String
  let tokenID: String
  
  let isERC721Format: Bool
  
  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(isERC721Format ? ContractNFTTransfer.abiERC721 : ContractNFTTransfer.abiERC1155), [\"\(from)\", \"\(to)\", \"\(tokenID)\"])"
    return .script(command: run)
  }
}
