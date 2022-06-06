//
//  MockTransactionDetailPresenter.swift
//  KrystalUnitTests
//
//  Created by Tung Nguyen on 30/05/2022.
//

import Foundation
@testable import Krystal

class MockTransactionDetailPresenter: TransactionDetailPresenterProtocol {
  
  var items: [TransactionDetailRowType] = []
  var isOnViewLoadedCalled: Bool = false
  var isOnTapBackCalled: Bool = false
  var isOnOpenTxScanCall: Bool = false
  
  func onViewLoaded() {
    isOnViewLoadedCalled = true
  }
  
  func onTapBack() {
    isOnTapBackCalled = true
  }
  
  func onOpenTxScan(txHash: String, chainID: String) {
    isOnOpenTxScanCall = true
  }
  
}
