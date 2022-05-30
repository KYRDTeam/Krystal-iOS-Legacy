//
//  MockTransactionDetailView.swift
//  KyberNetworkTests
//
//  Created by Tung Nguyen on 27/05/2022.
//

import Foundation
@testable import Krystal

class MockTransactionDetailView: TransactionDetailViewProtocol {
  
  var isItemsReloaded: Bool = false
  
  func reloadItems() {
    isItemsReloaded = true
  }
  
}
