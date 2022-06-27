//
//  GetBalanceCommand.swift
//  KrystalWeb3Bridge
//
//  Created by Tung Nguyen on 24/06/2022.
//

import Foundation
import KrystalJSBridge

class GetBalanceCommand: NSObject, BridgeCommandProtocol {
  typealias BridgeInput = BalanceInput
  typealias BridgeOutput = BalanceOutput
  
  var eventEmitter: EventEmitter
  var commandName: String = "getBalance"
  
  required init(eventEmitter: EventEmitter) {
    self.eventEmitter = eventEmitter
  }
  
  func execute(moduleName: String, subscriberId: String, params: BridgeInput) throws -> CommandSubscription? {
    
    sendSuccessEvent(
      to: moduleName,
      with: subscriberId,
      and: BalanceOutput()
    )
    
    return nil
  }
  
  struct BalanceInput: Codable {
    
  }
  
  struct BalanceOutput: Codable {
    
  }
  
}
