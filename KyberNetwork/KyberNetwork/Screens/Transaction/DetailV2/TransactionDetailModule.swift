//
//  TransactionDetailModule.swift
//  KyberNetwork
//
//  Created Nguyen Tung on 19/05/2022.
//  Copyright © 2022 Krystal. All rights reserved.
//

import UIKit

class TransactionDetailModule {
  
  static func build(tx: KrystalHistoryTransaction) -> UIViewController {
    let view = TransactionDetailViewController()
    let interactor = TransactionDetailInteractor()
    let router = TransactionDetailRouter()
    let presenter = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
    
    presenter.setupTransaction(tx: tx)
    view.hidesBottomBarWhenPushed = true
    view.presenter = presenter
    interactor.presenter = presenter
    router.view = view
    
    return view
  }
  
  static func build(internalTx: InternalHistoryTransaction) -> UIViewController {
    let view = TransactionDetailViewController()
    let interactor = TransactionDetailInteractor()
    let router = TransactionDetailRouter()
    let presenter = TransactionDetailPresenter(view: view, interactor: interactor, router: router)
    
    presenter.setupTransaction(internalTx: internalTx)
    view.hidesBottomBarWhenPushed = true
    view.presenter = presenter
    interactor.presenter = presenter
    router.view = view
    
    return view
  }
  
}
