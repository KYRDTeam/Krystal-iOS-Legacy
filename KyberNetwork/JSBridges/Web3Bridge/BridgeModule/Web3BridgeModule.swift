//
//  Web3BridgeModule.swift
//  KrystalWeb3Bridge
//
//  Created by Tung Nguyen on 24/06/2022.
//

import Foundation
import KrystalJSBridge

class Web3BridgeModule: BaseBridgeModule {
  
  override func getModuleName() -> String {
    return "Web3Module"
  }
  
  required override init(eventEmitter: EventEmitter) {
    super.init(eventEmitter: eventEmitter)
    addCommand(command: GetBalanceCommand(eventEmitter: eventEmitter))
    addCommand(command: TransferCommand(eventEmitter: eventEmitter))
  }
}
