//
//  AbstractHistoryTransactionViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit

protocol AbstractHistoryTransactionViewModel: class {
  var fromIconSymbol: String { get }
  var toIconSymbol: String { get }
  var displayedAmountString: String { get }
  var transactionDetailsString: String { get }
  var transactionTypeString: String { get }
  var isError: Bool { get }
  var transactionTypeImage: UIImage { get }
  var displayTime: String { get }
}
