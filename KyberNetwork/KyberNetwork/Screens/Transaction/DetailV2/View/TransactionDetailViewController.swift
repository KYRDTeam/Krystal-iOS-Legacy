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
  
  var currentChainID: String {
    return "\(KNGeneralProvider.shared.currentChain.getChainId())"
  }
  
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
    tableView.registerCellNib(MultiSendSubTransactionCell.self)
    tableView.registerCellNib(TxListHeaderCell.self)
    tableView.registerCellNib(TxApplicationInfoCell.self)
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
    case .common(let type, let timestamp, let hideStatus, let status):
      let cell = tableView.dequeueReusableCell(TransactionTypeInfoCell.self, indexPath: indexPath)!
      cell.configure(type: type, timestamp: timestamp, hideStatus: hideStatus, status: status)
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
    case .multisendHeader(let total):
      let cell = tableView.dequeueReusableCell(TxListHeaderCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      cell.configure(title: Strings.numberOfTransfers, total: total)
      return cell
    case .multisendTx(let index, let address, let amount):
      let cell = tableView.dequeueReusableCell(MultiSendSubTransactionCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      cell.configure(index: index, address: address, amount: amount)
      return cell
    case .application(let walletAddress, let applicationAddress):
      let cell = tableView.dequeueReusableCell(TxApplicationInfoCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      cell.configure(walletAddress: walletAddress, applicationAddress: applicationAddress)
      cell.onOpenWallet = { [weak self] in
        guard let self = self else { return }
        self.presenter.openAddress(address: walletAddress, chainID: self.currentChainID)
      }
      cell.onOpenApplication = { [weak self] in
        guard let self = self else { return }
        self.presenter.openAddress(address: applicationAddress, chainID: self.currentChainID)
      }
      return cell
    case .transactionFee(let fee):
      let cell = tableView.dequeueReusableCell(TxInfoCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      cell.configure(title: Strings.transactionFee, value: fee, showHelpIcon: true)
      cell.helpHandler = { [weak self] in
        self?.showBottomBannerView(
          message: Strings.gasFeeDescription,
          icon: Images.helpLargeIcon,
          time: 3
        )
      }
      return cell
    case .txHash(let hash):
      let cell = tableView.dequeueReusableCell(TxInfoCell.self, indexPath: indexPath)!
      cell.selectionStyle = .none
      cell.configure(title: Strings.txHash, value: hash, actionIcon: Images.openLinkIcon)
      cell.onAction = { [weak self] in
        guard let self = self else { return }
        self.presenter.onOpenTxScan(txHash: hash, chainID: self.currentChainID)
      }
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let item = presenter.items[indexPath.row]
    switch item {
    case .application:
      return 102
    case .multisendTx:
      return 40
    default:
      return UITableView.automaticDimension
    }
  }
  
}

extension TransactionDetailViewController: BridgeSubTransactionCellDelegate {
  
  func openTxDetail(cell: BridgeSubTransactionCell, hash: String, chainID: String) {
    presenter.onOpenTxScan(txHash: hash, chainID: chainID)
  }
  
  func copyTxAddress(cell: BridgeSubTransactionCell, address: String) {
    UIPasteboard.general.string = address
    self.showMessageWithInterval(message: Strings.addressCopied)
  }
  
}
