//
//  MultiSendViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import UIKit
import SwipeCellKit
import QRCodeReaderViewController
import BigInt

typealias MultiSendItem = (String, BigInt, Token)

enum MultiSendViewControllerEvent {
  case searchToken(selectedToken: Token)
  case openContactsList
  case addContact(address: String)
  case checkApproval(items: [MultiSendItem])
  case confirm(items: [MultiSendItem])
  case openHistory
  case openWalletsList
}

protocol MultiSendViewControllerDelegate: class {
  func multiSendViewController(_ controller: MultiSendViewController, run event: MultiSendViewControllerEvent)
}

class MultiSendViewModel {
  var cellModels = [MultiSendCellModel()]
  var updatingIndex = 0
  fileprivate(set) var wallet: Wallet
  
  init(wallet: Wallet) {
    self.wallet = wallet
  }
  
  var selectedToken: [Token] {
    return self.cellModels.map { element in
      return element.from
    }
  }

  var sendItems: [MultiSendItem] {
    return self.cellModels.map { element in
      return (element.addressString, element.amountBigInt, element.from)
    }
  }
  
  var isFormValid: ValidStatus {
    let errors = self.cellModels.map { e in
      return e.isCellFormValid
    }.filter { status in
      return status != .success
    }
    if let anError = errors.first {
      return anError
    } else {
      return .success
    }
  }
  
  func resetDataSource() {
    self.cellModels = [MultiSendCellModel()]
  }
  
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
  }
}

class MultiSendViewController: KNBaseViewController {
  @IBOutlet weak var inputTableView: UITableView!
  @IBOutlet weak var inputTableViewHeight: NSLayoutConstraint!
  
  
  @IBOutlet weak var historyButton: UIButton!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet weak var walletsListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  
  let viewModel: MultiSendViewModel
  weak var delegate: MultiSendViewControllerDelegate?

  init(viewModel: MultiSendViewModel) {
    self.viewModel = viewModel
    super.init(nibName: MultiSendViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: MultiSendCell.className, bundle: nil)
    self.inputTableView.register(nib, forCellReuseIdentifier: MultiSendCell.cellID)
    self.inputTableView.rowHeight = MultiSendCell.cellHeight
    self.updateAvailableBalanceForToken(KNGeneralProvider.shared.quoteTokenObject.toToken())
    self.updateUISwitchChain()
    self.updateUIWalletButton()
    self.updateUIPendingTxIndicatorView()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    if case .error(let description) = self.viewModel.isFormValid {
      self.showErrorTopBannerMessage(message: description)
    } else {
      self.delegate?.multiSendViewController(self, run: .checkApproval(items: self.viewModel.sendItems))
    }
  }
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { selected in
      let viewModel = SwitchChainWalletsListViewModel(selected: selected)
      let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }
  
  @IBAction func switchWalletButtonTapped(_ sender: UIButton) {
    self.delegate?.multiSendViewController(self, run: .openWalletsList)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.delegate?.multiSendViewController(self, run: .openHistory)
  }
  
  fileprivate func updateUIWalletButton() {
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
  }
  
  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
    self.viewModel.resetDataSource()
    self.inputTableView.reloadData()
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
      transaction.state == .pending
    }
    self.pendingTxIndicatorView.isHidden = pendingTransaction == nil
  }

  private func openQRCode() {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.present(qrcodeReaderVC, animated: true, completion: nil)
  }
  
  func coordinatorDidUpdateSendToken(_ from: Token) {
    let cm = self.viewModel.cellModels[self.viewModel.updatingIndex]
    cm.from = from
    self.updateAvailableBalanceForToken(from)
    self.inputTableView.reloadData()
    self.viewModel.updatingIndex = 0
  }
  
  func coordinatorDidSelectContact(_ contact: KNContact) {
    let cm = self.viewModel.cellModels[self.viewModel.updatingIndex]
    let isAddressChanged = cm.addressString.lowercased() != contact.address.lowercased()
    guard isAddressChanged else { return }
    cm.updateAddress(contact.address)
    KNContactStorage.shared.updateLastUsed(contact: contact)
    self.inputTableView.reloadData()
  }
  
  func coordinatorSend(to address: String) {
    let cm = self.viewModel.cellModels[self.viewModel.updatingIndex]
    let isAddressChanged = cm.addressString.lowercased() != address.lowercased()
    guard isAddressChanged else { return }
    cm.updateAddress(address)
    if let contact = KNContactStorage.shared.contacts.first(where: { return address.lowercased() == $0.address.lowercased() }) {
      KNContactStorage.shared.updateLastUsed(contact: contact)
    }
    self.inputTableView.reloadData()
  }
  
  func coordinatorDidFinishApproveTokens() {
    self.delegate?.multiSendViewController(self, run: .confirm(items: self.viewModel.sendItems))
  }
  
  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
  }
  
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.updateUIWalletButton()
    self.viewModel.resetDataSource()
    self.inputTableView.reloadData()
    self.updateUIPendingTxIndicatorView()
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
}

extension MultiSendViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.cellModels.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: MultiSendCell.cellID,
      for: indexPath
    ) as! MultiSendCell
    cell.cellDelegate = self
    cell.delegate = self
    let cm = self.viewModel.cellModels[indexPath.row]
    cell.updateCellModel(cm)
    return cell
  }
}

extension MultiSendViewController: UITableViewDelegate {
  
}

extension MultiSendViewController: MultiSendCellDelegate {
  fileprivate func updateAvailableBalanceForToken(_ selectedToken: Token) {
    var total = selectedToken.getBalanceBigInt()
    self.viewModel.cellModels.forEach { item in
      if item.from == selectedToken {
        total -= item.amountBigInt
      }
    }
    self.viewModel.cellModels.forEach { item in
      if item.from == selectedToken {
        item.availableAmount = total
      }
    }
  }
  
  func multiSendCell(_ cell: MultiSendCell, run event: MultiSendCellEvent) {
    switch event {
    case .add:
      let element = MultiSendCellModel()
      element.index = self.viewModel.cellModels.count
      element.addButtonEnable = true
      self.viewModel.cellModels.forEach { e in
        e.addButtonEnable = false
      }
      self.viewModel.cellModels.append(element)
      self.inputTableViewHeight.constant = CGFloat(self.viewModel.cellModels.count) * MultiSendCell.cellHeight
      self.updateAvailableBalanceForToken(element.from)
      self.inputTableView.reloadData()
    case .searchToken(selectedToken: let selectedToken, cellIndex: let cellIndex):
      self.viewModel.updatingIndex = cellIndex
      self.delegate?.multiSendViewController(self, run: .searchToken(selectedToken: selectedToken))
    case .updateAmount(amount: _, selectedToken: let selectedToken):
      updateAvailableBalanceForToken(selectedToken)
      self.inputTableView.reloadData()
    case .qrCode(cellIndex: let cellIndex):
      self.viewModel.updatingIndex = cellIndex
      self.openQRCode()
    case .openContact(cellIndex: let cellIndex):
      self.viewModel.updatingIndex = cellIndex
      self.delegate?.multiSendViewController(self, run: .openContactsList)
    case .addContact(address: let address):
      self.delegate?.multiSendViewController(self, run: .addContact(address: address))
    }
  }
}

extension MultiSendViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard indexPath.row > 0 else { return nil }

    let delete = SwipeAction(style: .destructive, title: nil) { _, _ in
      self.viewModel.cellModels.remove(at: indexPath.row)
      self.viewModel.cellModels.last?.addButtonEnable = true
      self.inputTableView.reloadData()
    }
    delete.title = "delete".toBeLocalised().uppercased()
    delete.textColor = UIColor(named: "textWhiteColor")
    delete.font = UIFont.Kyber.medium(with: 12)

    return [delete]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}

extension MultiSendViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      let cm = self.viewModel.cellModels[self.viewModel.updatingIndex]

      let isAddressChanged = cm.addressString.lowercased() != address.lowercased()
      guard isAddressChanged else { return }
      cm.addressString = address
      self.viewModel.updatingIndex = 0
      self.inputTableView.reloadData()
    }
  }
}
