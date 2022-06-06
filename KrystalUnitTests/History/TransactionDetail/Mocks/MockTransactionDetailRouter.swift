//
//  MockTransactionDetailRouter.swift
//  KyberNetworkTests
//
//  Created by Tung Nguyen on 27/05/2022.
//

import Foundation
@testable import Krystal

class MockTransactionDetailRouter: TransactionDetailRouterProtocol {
  
  var isTxUrlOpened: Bool = false
  var isWentBack: Bool = false
  
  func openTxUrl(url: URL) {
    isTxUrlOpened = true
  }
  
  func goBack() {
    isWentBack = true
  }

}
