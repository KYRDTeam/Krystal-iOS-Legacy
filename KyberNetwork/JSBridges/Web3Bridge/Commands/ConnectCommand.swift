//
//  ConnectCommand.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/07/2022.
//

import Foundation
import KrystalJSBridge
import UIKit

class ConnectCommand: NSObject, BridgeCommandProtocol {
  
  typealias BridgeInput = ConnectInput
  typealias BridgeOutput = ConnectOutput
  
  var eventEmitter: EventEmitter
  var commandName: String = "connect"
  
  required init(eventEmitter: EventEmitter) {
    self.eventEmitter = eventEmitter
  }
  
  func execute(moduleName: String, subscriberId: String, params: BridgeInput) throws -> CommandSubscription? {
    let currentAddress = AppDelegate.session.address
    if currentAddress.addressType == .solana {
      if currentAddress.isWatchWallet {
        sendSuccessEvent(
          to: moduleName,
          with: subscriberId,
          and: ConnectOutput(code: 400, message: "Cannot connect to watch wallet", address: currentAddress.addressString)
        )
      } else {
        sendSuccessEvent(
          to: moduleName,
          with: subscriberId,
          and: ConnectOutput(code: 200, message: "Success", address: currentAddress.addressString)
        )
      }
      
    } else {
      sendSuccessEvent(
        to: moduleName,
        with: subscriberId,
        and: ConnectOutput(code: 400, message: "The wallet does not support this chain", address: nil)
      )
    }
    
    return nil
  }
  
  struct ConnectInput: Codable {

  }
  
  struct ConnectOutput: Codable {
    var code: Int
    var message: String
    var address: String?
  }
  
}
