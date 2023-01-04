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
  
  static let abiERC1155 = "{\"constant\":false,\"inputs\":[{\"internalType\":\"address\",\"name\":\"_from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"_data\",\"type\":\"bytes\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"
  
  
  let from: String
  let to: String
  let tokenID: String
  let amount: Int
  
  let isERC721Format: Bool
  
  var type: Web3RequestType {
    if isERC721Format {
      let run = "web3.eth.abi.encodeFunctionCall(\(ContractNFTTransfer.abiERC721), [\"\(from)\", \"\(to)\", \"\(tokenID)\"])"
      return .script(command: run)
    } else {
      let run = "web3.eth.abi.encodeFunctionCall(\(ContractNFTTransfer.abiERC1155), [\"\(from)\", \"\(to)\", \"\(tokenID)\", \"\(amount)\", \"0x\"])"
      return .script(command: run)
    }
  }
}

struct GetSupportInterfaceEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"inputs\":[{\"internalType\":\"bytes4\",\"name\":\"interfaceId\",\"type\":\"bytes4\"}],\"name\":\"supportsInterface\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"}"

  var type: Web3RequestType {
      let erc721ID = "0x5b5e139f"
      let run = "web3.eth.abi.encodeFunctionCall(\(GetSupportInterfaceEncode.abi),[\"\(erc721ID)\"])"
      return .script(command: run)
  }
}

struct GetSupportInterfaceDecode: Web3Request {
  typealias Response = Bool
  
  let data: String
  
  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('bool', '\(data)')"
    return .script(command: run)
  }
}
