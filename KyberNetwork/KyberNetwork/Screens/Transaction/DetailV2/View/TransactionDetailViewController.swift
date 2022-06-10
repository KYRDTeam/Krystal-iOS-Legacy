//
//  TransactionDetailViewController.swift
//  KyberNetwork
//
//  Created Nguyen Tung on 19/05/2022.
//  Copyright © 2022 Krystal. All rights reserved.
//

import UIKit

class TransactionDetailViewController: KNBaseViewController, TransactionDetailViewProtocol {
  
  @IBOutlet weak var tableView: UITableView!
  
  var presenter: TransactionDetailPresenterProtocol!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  private func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.registerCellNib(BridgeSubTransactionCell.self)
    tableView.registerCellNib(TransactionStepSeparatorCell.self)
    tableView.registerCellNib(TransactionTypeInfoCell.self)
    tableView.registerCellNib(TxInfoCell.self)
  }
  
  func reloadItems() {
    tableView.reloadData()
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    presenter.onTapBack()
  }
}

extension TransactionDetailViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return presenter.items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = presenter.items[indexPath.row]
    switch item {
    case .common(let type, let timestamp):
      let cell = tableView.dequeueReusableCell(TransactionTypeInfoCell.self, indexPath: indexPath)!
      cell.configure(type: type, timestamp: timestamp)
      cell.selectionStyle = .none
      return cell
    case .bridgeSubTx(let isSouceTx, let tx):
      let cell = tableView.dequeueReusableCell(BridgeSubTransactionCell.self, indexPath: indexPath)!
      cell.configure(isSourceTransaction: isSouceTx, tx: tx)
      cell.delegate = self
      cell.selectionStyle = .none
      return cell
    case .stepSeparator:
      let cell = tableView.dequeueReusableCell(TransactionStepSeparatorCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      return cell
    case .bridgeFee(let feeString):
      let cell = tableView.dequeueReusableCell(TxInfoCell.self, indexPath: indexPath)!
      cell.configure(title: Strings.transactionFee, value: feeString, showHelpIcon: false)
      cell.selectionStyle = .none
      return cell
    case .estimatedBridgeTime(let timeString):
      let cell = tableView.dequeueReusableCell(TxInfoCell.self, indexPath: indexPath)!
      cell.configure(title: Strings.estimatedTimeOfArrival, value: timeString)
      cell.selectionStyle = .none
      return cell
    }
  }
  
}

extension TransactionDetailViewController: BridgeSubTransactionCellDelegate {
  
  func openTxDetail(cell: BridgeSubTransactionCell, hash: String, chainID: String) {
    presenter?.onOpenTxScan(txHash: hash, chainID: chainID)
  }
  
  func copyTxAddress(cell: BridgeSubTransactionCell, address: String) {
    UIPasteboard.general.string = address
    self.showMessageWithInterval(message: Strings.addressCopied)
  }
  
}
