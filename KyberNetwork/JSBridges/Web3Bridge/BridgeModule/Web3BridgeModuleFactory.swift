//
//  Web3BridgeModuleFactory.swift
//  KrystalWeb3Bridge
//
//  Created by Tung Nguyen on 24/06/2022.
//

import KrystalJSBridge

@objc
public class Web3BridgeModuleFactory: NSObject, BridgeModuleFactory {
  public func createBridgeModule(eventEmitter: EventEmitter) throws -> BaseBridgeModule {
    return Web3BridgeModule(eventEmitter: eventEmitter)
  }
}
