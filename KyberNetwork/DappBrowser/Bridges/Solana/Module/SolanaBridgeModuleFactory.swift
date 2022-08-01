//
//  SolanaBridgeModuleFactory.swift
//  Krystal
//
//  Created by Tung Nguyen on 24/06/2022.
//

import KrystalJSBridge

@objc
public class SolanaBridgeModuleFactory: NSObject, BridgeModuleFactory {
  public func createBridgeModule(eventEmitter: EventEmitter) throws -> BaseBridgeModule {
    return SolanaBridgeModule(eventEmitter: eventEmitter)
  }
}
