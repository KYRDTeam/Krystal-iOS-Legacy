//
//  SolanaBridgeModule.swift
//  KrystalWeb3Bridge
//
//  Created by Tung Nguyen on 24/06/2022.
//

import Foundation
import KrystalJSBridge

class SolanaBridgeModule: BaseBridgeModule {
  
  override func getModuleName() -> String {
    return "SolanaModule"
  }
  
  required override init(eventEmitter: EventEmitter) {
    super.init(eventEmitter: eventEmitter)
    addCommand(command: SolanaConnectCommand(eventEmitter: eventEmitter))
    addCommand(command: SolanaGetPrivateKeyCommand(eventEmitter: eventEmitter))
  }
}
