//
//  TransactionDetailContract.swift
//  KyberNetwork
//
//  Created Nguyen Tung on 19/05/2022.
//  Copyright © 2022 Krystal. All rights reserved.
//

import Foundation

protocol TransactionDetailViewProtocol: class {
  func reloadItems()
}

protocol TransactionDetailPresenterProtocol: class {
  var items: [TransactionDetailRowType] { get }
  
  func onViewLoaded()
  func onTapBack()
  func onOpenTxScan(txHash: String, chainID: String)
}

protocol TransactionDetailInteractorProtocol: class {
  
}

protocol TransactionDetailRouterProtocol: class {
  func openTxUrl(url: URL)
  func goBack()
}
