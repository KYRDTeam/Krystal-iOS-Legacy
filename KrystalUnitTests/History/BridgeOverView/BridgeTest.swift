//
//  BridgeTest.swift
//  KrystalUnitTests
//
//  Created by Com1 on 07/06/2022.
//

@testable import Krystal
import Foundation
import Quick
import Nimble
import UIKit

class BridgeTest: QuickSpec {
  override func spec() {
    describe("Test fetch data") {
      var sut: BridgeCoordinator!
      let acceptableTimeOut = 30
      beforeEach {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let session = appDelegate.coordinator.session
        sut = BridgeCoordinator(navigationController: UINavigationController())
        // pretend user update data via screen Bridge
        sut.rootViewController.viewModel.currentSendToAddress = "0x7cE5E5a679DA7Cc4B4A7D75dB7b2D4443DBC30bC"
        sut.rootViewController.viewModel.currentSourceChain = .polygon
        sut.rootViewController.viewModel.currentDestChain = .bsc
        sut.rootViewController.viewModel.sourceAmount = 16
        sut.rootViewController.viewModel.currentSourceToken = KNSupportedTokenStorage.shared.getAllTokenObject().first { $0.address == "0xc2132d05d31c914a87c6611c10748aeb04b58e8f" }
      }
      
      describe("ServerInfo") {
        it("should return value and can parse to local model in client app") {
          waitUntil(timeout: .seconds(acceptableTimeOut)) { done in
            sut.getServerInfo(chainId: KNGeneralProvider.shared.currentChain.getChainId()) {
              expect(sut.data.count).to(beGreaterThan(0), description: "response structure match client model")
              done()
            }
          }
        }
      }
      
      describe("Get pool info") {
        it("should return value and can parse to local model in client app") {
          waitUntil(timeout: .seconds(acceptableTimeOut)) { done in
            // USDT address on polygon
            let address = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
            // polygon chain Id
            let chainId = 137
            sut.getPoolInfo(chainId: chainId, tokenAddress: address) { poolInfo in
              expect(poolInfo?.symbol).to(equal("USDT"), description: "response structure match client model")
              done()
            }
            
          }
        }
      }
      
      describe("Build Swap Chain Tx") {
        it("should return value match bridge contract") {
          waitUntil(timeout: .seconds(acceptableTimeOut)) { done in
            let bridgeContract = "0x4f3Aff3A747fCADe12598081e80c6605A8be192F"
            sut.buildSwapChainTx { txObject in
              expect(txObject?.to).to(equal(bridgeContract), description: "response structure match client model")
              done()
            }
          }
        }
      }
    }
  }
}
