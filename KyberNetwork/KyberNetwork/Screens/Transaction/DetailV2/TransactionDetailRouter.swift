//
//  TransactionDetailRouter.swift
//  KyberNetwork
//
//  Created Nguyen Tung on 19/05/2022.
//  Copyright © 2022 Krystal. All rights reserved.
//

import UIKit
import SafariServices

class TransactionDetailRouter: TransactionDetailRouterProtocol {
  weak var view: UIViewController!

  func openTxUrl(url: URL) {
    let vc = SFSafariViewController(url: url)
    view.present(vc, animated: true, completion: nil)
  }
  
  func goBack() {
    view.navigationController?.popViewController(animated: true, completion: nil)
  }
  
}
