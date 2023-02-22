//
//  DAppMethod.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 12/12/2022.
//

import Foundation
import UIKit

enum DAppMethod: String, Decodable, CaseIterable {
    case signRawTransaction
    case signTransaction
    case signMessage
    case signTypedMessage
    case signPersonalMessage
    case sendTransaction
    case ecRecover
    case requestAccounts
    case watchAsset
    case addEthereumChain
    case switchEthereumChain // legacy compatible
    case switchChain
}
//
//extension DAppMethod {
//    static func fromMessage(_ message: WKScriptMessage) {
//        
//      let decoder = JSONDecoder()
//      guard var body = message.body as? [String: AnyObject] else {
//        print("[Browser] Invalid body in message: \(message.body)")
//        return nil
//      }
//      if var object = body["object"] as? [String: AnyObject], object["gasLimit"] is [String: AnyObject] {
//        //Some dapps might wrongly have a gasLimit dictionary which breaks our decoder. MetaMask seems happy with this, so we support it too
//        object["gasLimit"] = nil
//        body["object"] = object as AnyObject
//      }
//      guard let jsonString = body.jsonString else {
//        print("[Browser] Invalid jsonString. body: \(body)")
//        return nil
//      }
//      let data = jsonString.data(using: .utf8)!
//      if let command = try? decoder.decode(DappCommand.self, from: data) {
//        return .eth(command)
//      } else if let command = try? decoder.decode(AddCustomChainCommand.self, from: data) {
//        return .walletAddEthereumChain(command)
//      } else if let command = try? decoder.decode(SwitchChainCommand.self, from: data) {
//        return .walletSwitchEthereumChain(command)
//      } else {
//        return nil
//      }
//    }
//}
