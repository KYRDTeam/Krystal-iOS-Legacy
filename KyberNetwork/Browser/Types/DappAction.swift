// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import BigInt
import WebKit
import TrustKeystore
import TrustCore

enum DappAction {
    case signMessage(String)
    case signPersonalMessage(String)
    case signTypedMessage([EthTypedData])
    case signTypedMessageV3(EIP712TypedData)
    case signTransaction(SignTransactionObject)
    case sendTransaction(SignTransactionObject)
    case sendRawTransaction(String)
    case ethCall(from: String, to: String, data: String)
    case walletAddEthereumChain(WalletAddEthereumChainObject)
    case walletSwitchEthereumChain(WalletSwitchEthereumChainObject)
    case unknown
}

extension DappAction {
  static func fromCommand(_ command: DappOrWalletCommand) -> DappAction {
    switch command {
    case .eth(let command):
      switch command.name {
      case .signTransaction:
        return .signTransaction(DappAction.makeUnconfirmedTransaction(command.object))
      case .sendTransaction:
        return .sendTransaction(DappAction.makeUnconfirmedTransaction(command.object))
      case .signMessage:
        let data = command.object["data"]?.value ?? ""
        return .signMessage(data)
      case .signPersonalMessage:
        let data = command.object["data"]?.value ?? ""
        return .signPersonalMessage(data)
      case .signTypedMessage:
        if let data = command.object["data"] {
          if let eip712Data = data.eip712v3And4Data {
            return .signTypedMessageV3(eip712Data)
          } else {
            return .signTypedMessage(data.eip712PreV3Array)
          }
        } else {
          return .signTypedMessage([])
        }
      case .ethCall:
        let from = command.object["from"]?.value ?? ""
        let to = command.object["to"]?.value ?? ""
        let data = command.object["data"]?.value ?? ""
        return .ethCall(from: from, to: to, data: data)
      case .unknown:
        return .unknown
      }
    case .walletAddEthereumChain(let command):
      return .walletAddEthereumChain(command.object)
    case .walletSwitchEthereumChain(let command):
      return .walletSwitchEthereumChain(command.object)
    }
  }

  private static func makeUnconfirmedTransaction(_ object: [String: DappCommandObjectValue]) -> SignTransactionObject {
    let to = object["to"]?.value ?? ""
    let from = object["from"]?.value ?? ""
    let value = BigInt((object["value"]?.value ?? "0").drop0x, radix: 16) ?? BigInt()
//    let nonce: BigInt? = {
//      guard let value = object["nonce"]?.value else { return .none }
//      return BigInt(value.drop0x, radix: 16)
//    }()
    let gasLimit: BigInt? = {
      guard let value = object["gasLimit"]?.value ?? object["gas"]?.value else { return KNGasConfiguration.exchangeTokensGasLimitDefault }
        if value.hasPrefix("0x") {
            return BigInt(value.drop0x, radix: 16)
        } else {
            return BigInt(value)
        }
    }()
    let gasPrice: BigInt? = {
      guard let value = object["gasPrice"]?.value else { return KNGasCoordinator.shared.fastKNGas }
        if value.hasPrefix("0x") {
            return BigInt(value.drop0x, radix: 16)
        } else {
            return BigInt(value)
        }
    }()
    let data = Data(hex: object["data"]?.value ?? "0x")

    return SignTransactionObject(
      value: value.description,
      from: from,
      to: to,
      nonce: 0,
      data: data,
      gasPrice: gasPrice?.description ?? "",
      gasLimit: gasLimit?.description ?? "",
      chainID: KNGeneralProvider.shared.customRPC.chainID,
      reservedGasLimit: gasLimit?.description ?? ""
    )
  }
  
  static func fromMessage(_ message: WKScriptMessage) -> DappOrWalletCommand? {
    let decoder = JSONDecoder()
    guard var body = message.body as? [String: AnyObject] else {
      print("[Browser] Invalid body in message: \(message.body)")
      return nil
    }
    if var object = body["object"] as? [String: AnyObject], object["gasLimit"] is [String: AnyObject] {
      //Some dapps might wrongly have a gasLimit dictionary which breaks our decoder. MetaMask seems happy with this, so we support it too
      object["gasLimit"] = nil
      body["object"] = object as AnyObject
    }
    guard let jsonString = body.jsonString else {
      print("[Browser] Invalid jsonString. body: \(body)")
      return nil
    }
    let data = jsonString.data(using: .utf8)!
    if let command = try? decoder.decode(DappCommand.self, from: data) {
      return .eth(command)
    } else if let command = try? decoder.decode(AddCustomChainCommand.self, from: data) {
      return .walletAddEthereumChain(command)
    } else if let command = try? decoder.decode(SwitchChainCommand.self, from: data) {
      return .walletSwitchEthereumChain(command)
    } else {
      return nil
    }
  }
}

enum SignMessageType {
    case message(Data)
    case personalMessage(Data)
    case typedMessage([EthTypedData])
    case eip712v3And4(EIP712TypedData)
}
