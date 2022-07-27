//
//  GetPrivateKeyCommand.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/07/2022.
//

import Foundation
import KrystalJSBridge
import UIKit
import KrystalWallets

class GetPrivateKeyCommand: NSObject, BridgeCommandProtocol {
  
  typealias BridgeInput = PrivateKeyInput
  typealias BridgeOutput = PrivateKeyOutput
  
  var eventEmitter: EventEmitter
  var commandName: String = "getPrivateKey"
  let walletManager = WalletManager.shared
  
  required init(eventEmitter: EventEmitter) {
    self.eventEmitter = eventEmitter
  }
  
  func execute(moduleName: String, subscriberId: String, params: BridgeInput) throws -> CommandSubscription? {
    guard let address = walletManager.getAllAddresses().first(where: { $0.addressString == params.address }) else {
      sendErrorEvent(to: moduleName, with: subscriberId, and: "Wallet not found")
      return nil
    }
    
    guard let data = walletManager.privateKeyData(address: address) else {
      sendErrorEvent(to: moduleName, with: subscriberId, and: "Cannot export private key")
      return nil
    }
    sendSuccessEvent(to: moduleName, with: subscriberId, and: PrivateKeyOutput(privateKey: data.bytes))
    return nil
  }
  
  struct PrivateKeyInput: Codable {
    var address: String
  }
  
  struct PrivateKeyOutput: Codable {
    var privateKey: [UInt8]
  }
  
}
