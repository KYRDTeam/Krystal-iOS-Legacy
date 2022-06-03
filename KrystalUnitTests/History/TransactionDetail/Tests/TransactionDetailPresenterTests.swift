//
//  TransactionDetailPresenterTests.swift
//  KyberNetworkTests
//
//  Created by Tung Nguyen on 27/05/2022.
//

import Foundation
import XCTest
@testable import Krystal
import Quick
import Nimble

class TransactionDetailPresenterSpec: QuickSpec {
  
  override func spec() {
    describe("TransactionDetailPresenter") {
      var view: MockTransactionDetailView!
      var interactor: MockTransactionDetailInteractor!
      var router: MockTransactionDetailRouter!
      var sut: TransactionDetailPresenter!
      
      beforeEach {
        view = MockTransactionDetailView()
        interactor = MockTransactionDetailInteractor()
        router = MockTransactionDetailRouter()
      }
      
      describe("getTransactionType") {
        it("should be correct type") {
          sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
          expect(sut.getTransactionType(txType: "BridgeFrom")).to(equal(.bridgeFrom))
          expect(sut.getTransactionType(txType: "BridgeTo")).to(equal(.bridgeTo))
          expect(sut.getTransactionType(txType: "Bridge")).to(equal(.contractInteraction))
          expect(sut.getTransactionType(txType: "Swap")).to(equal(.swap))
        }
      }
      
      describe("setupTransaction - KrystalHistoryTransaction") {
        
        context("transaction type is Bridge and from or to is nil") {
          it("returns 0 items") {
            let from = self.extraBridgeTransaction(status: "success")
            let extraData = self.extraData(from: from, to: nil)
            let tx = self.transaction(type: "BridgeFrom", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(0))
          }
          
          it("returns 0 items") {
            let to = self.extraBridgeTransaction(status: "success")
            let extraData = self.extraData(from: nil, to: to)
            let tx = self.transaction(type: "BridgeFrom", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(0))
          }
        }
        
        context("transaction type is Bridge and status is success") {
          it("returns 5 items") {
            let from = self.extraBridgeTransaction(status: "success")
            let to = self.extraBridgeTransaction(status: "success")
            let extraData = self.extraData(from: from, to: to)
            let tx = self.transaction(type: "BridgeFrom", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(5))
            expect(sut.items[0]).to(equal(.common(type: .bridgeFrom, timestamp: 123456789)))
            expect(sut.items[1]).to(equal(.bridgeSubTx(from: true, tx: from)))
            expect(sut.items[2]).to(equal(.stepSeparator))
            expect(sut.items[3]).to(equal(.bridgeSubTx(from: false, tx: to)))
            expect(sut.items[4]).to(equal(.bridgeFee(fee: "0.00012345 BNB")))
          }
        }
        
        context("transaction type is BridgeFrom and status is not success") {
          
          it("returns 6 items") {
            let from = self.extraBridgeTransaction(status: "success")
            let to = self.extraBridgeTransaction(status: "other")
            let extraData = self.extraData(from: from, to: to)
            let tx = self.transaction(type: "BridgeFrom", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(6))
            expect(sut.items[5]).to(equal(.estimatedBridgeTime(time: "9-30 mins")))
          }
          
          it("returns 6 items") {
            let from = self.extraBridgeTransaction(status: "pending")
            let to = self.extraBridgeTransaction(status: "other")
            let extraData = self.extraData(from: from, to: to)
            let tx = self.transaction(type: "BridgeFrom", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(6))
            expect(sut.items[5]).to(equal(.estimatedBridgeTime(time: "9-30 mins")))
          }
          
        }
        
        context("transaction type is not BridgeFrom or BridgeTo") {
          
          it("returns 0 items") {
            let from = self.extraBridgeTransaction(status: "success")
            let to = self.extraBridgeTransaction(status: "other")
            let extraData = self.extraData(from: from, to: to)
            let tx = self.transaction(type: "Swap", extraData: extraData)
            
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.setupTransaction(tx: tx)
            expect(sut.items.count).to(equal(6))
          }
          
        }
        
      }
      
      describe("onViewLoaded") {
        
        it("view items should be reloaded") {
          sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
          expect(view.isItemsReloaded).to(equal(false))
          sut.onViewLoaded()
          expect(view.isItemsReloaded).to(equal(true))
        }
        
      }
      
      describe("onTapBack") {
        
        it("router should call go back") {
          sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
          expect(router.isWentBack).to(equal(false))
          sut.onTapBack()
          expect(router.isWentBack).to(equal(true))
        }
        
      }
      
      describe("onOpenTxScan") {
        
        context("chainID is not supported") {
          it("router should not open tx url") {
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.onOpenTxScan(txHash: "some hash", chainID: "592929292")
            
            expect(router.isTxUrlOpened).to(equal(false))
          }
        }
        
        context("chainID is supported") {
          it("router should open tx url") {
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.onOpenTxScan(txHash: "0xabcdef", chainID: "56")
            
            expect(router.isTxUrlOpened).to(equal(true))
          }
        }
        
        context("chainID is supported, hash not valid") {
          it("router should not open tx url") {
            sut = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
            sut.onOpenTxScan(txHash: "invalid hash?!22--🚀", chainID: "56")
            
            expect(router.isTxUrlOpened).to(equal(false))
          }
        }
        
      }
      
    }
  }
  
  private func extraBridgeTransaction(status: String) -> ExtraBridgeTransaction {
    return ExtraBridgeTransaction(address: "", amount: "", chainId: "56", decimals: 0, token: "", tx: "", txStatus: status)
  }
  
  private func extraData(from: ExtraBridgeTransaction?, to: ExtraBridgeTransaction?) -> ExtraData {
    return ExtraData(receiveToken: nil, receiveValue: nil, owner: nil, spender: nil, token: nil, tokenAddress: nil, tokenName: nil, value: nil, sendToken: nil, sendValue: nil, from: from, to: to, type: nil, error: nil)
  }
  
  private func transaction(type: String, extraData: ExtraData) -> KrystalHistoryTransaction {
    return KrystalHistoryTransaction(hash: "", blockNumber: 0, timestamp: 123456789, from: "", to: "", status: "", value: "", valueQuote: 0, gasLimit: 0, gasUsed: 0, gasPrice: "", gasPriceQuote: 0, gasCost: "123450000000000", gasCostQuote: 0, type: "BridgeFrom", nonce: 0, extraData: extraData)
  }
  
}
