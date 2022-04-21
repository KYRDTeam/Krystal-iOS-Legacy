// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit


enum KNListWalletsViewEvent {
  case close
  case select(wallet: KNWalletObject)
  case remove(wallet: KNWalletObject)
  case edit(wallet: KNWalletObject)
  case addWallet(type: AddNewWalletType)
  case copy(data: WalletData)
}

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent)
}

class KNListWalletsViewModel {
  var listWallets: [KNWalletObject] = []
  var curWallet: KNWalletObject
  var isDisplayWatchWallets: Bool = false
  let keyStore: Keystore
  var seedsCellModels: [KNListWalletsTableViewCellModel] = []
  var nonSeedsCellModels: [KNListWalletsTableViewCellModel] = []
  var watchCellModels: [KNListWalletsTableViewCellModel] = []

  init(listWallets: [KNWalletObject], curWallet: KNWalletObject, keyStore: Keystore) {
    self.listWallets = listWallets
    self.curWallet = curWallet
    self.keyStore = keyStore
  }

  var displayWallets: [KNWalletObject] {
    return self.listWallets.filter { (object) -> Bool in
      return object.isWatchWallet == self.isDisplayWatchWallets
    }
  }
  
  var numberSections: Int {
    if self.isDisplayWatchWallets {
      return 1
    } else if !self.seedsCellModels.isEmpty && !self.nonSeedsCellModels.isEmpty {
      return 2
    } else {
      return 1
    }
  }
  
  func titleForSection(section: Int) -> String {
    guard !self.seedsCellModels.isEmpty && !self.nonSeedsCellModels.isEmpty else { return "" }
    if self.isDisplayWatchWallets {
      return ""
    } else {
      if section == 0 {
        if self.seedsCellModels.isEmpty {
          return "WALLETS"
        } else {
          return "MULTI-CHAIN WALLETS"
        }
      } else {
        return "WALLETS"
      }
    }
  }

  func numberRows(section: Int) -> Int {
    if self.isDisplayWatchWallets {
      return self.watchCellModels.count
    } else {
      if section == 0 {
        if self.seedsCellModels.isEmpty {
          return self.nonSeedsCellModels.count
        } else {
          return self.seedsCellModels.count
        }
      } else {
        return self.nonSeedsCellModels.count
      }
    }
  }

  func getCellModel(at row: Int, section: Int) -> KNListWalletsTableViewCellModel {
    if self.isDisplayWatchWallets {
      return self.watchCellModels[row]
    } else {
      if section == 0 {
        if self.seedsCellModels.isEmpty {
          return self.nonSeedsCellModels[row]
        } else {
          return self.seedsCellModels[row]
        }
      } else {
        return self.nonSeedsCellModels[row]
      }
    }
  }

  func getWallet(at row: Int, section: Int) -> KNWalletObject? {
    let cm = self.getCellModel(at: row, section: section)
    let address = cm.wallet.address
    let filterd = self.listWallets.first { element in
      return element.address == address
    }
    return filterd
  }

  func isCurrentWallet(row: Int, section: Int) -> Bool {
    let cm = self.getCellModel(at: row, section: section)
    return cm.wallet.address == self.curWallet.address
  }

  func reloadDataSource(completion: @escaping () -> Void) {
    let listData = self.listWallets.map { e in
      return e.toData()
    }
    DispatchQueue.global(qos: .background).async {
      let group = DispatchGroup()

      group.enter()
      if !self.seedsCellModels.isEmpty {
        self.seedsCellModels.removeAll()
      }
      if !self.nonSeedsCellModels.isEmpty {
        self.nonSeedsCellModels.removeAll()
      }
      if !self.watchCellModels.isEmpty {
        self.watchCellModels.removeAll()
      }

      for element in listData {
        if element.isWatchWallet {
          let cm = KNListWalletsTableViewCellModel(wallet: element, isMultipleWallet: false)
          self.watchCellModels.append(cm)
          continue
        }
        if element.chainType == .multiChain {
          let cm = KNListWalletsTableViewCellModel(wallet: element, isMultipleWallet: true)
          self.seedsCellModels.append(cm)
        } else {
          let cm = KNListWalletsTableViewCellModel(wallet: element, isMultipleWallet: false)
          self.nonSeedsCellModels.append(cm)
        }
      }

      group.leave()

      group.notify(queue: .main) {
        completion()
      }
    }
  }

  func update(wallets: [KNWalletObject], curWallet: KNWalletObject) {
    self.listWallets = wallets
    self.curWallet = curWallet
  }
  
  func isMultichainWallet(data: WalletData) -> Bool {
    let filterd = self.seedsCellModels.first { element in
      return data == element.wallet
    }
    return filterd != nil
  }
}

class KNListWalletsViewController: KNBaseViewController {

  fileprivate let kCellID: String = "walletsTableViewCellID"

  weak var delegate: KNListWalletsViewControllerDelegate?
  fileprivate var viewModel: KNListWalletsViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var walletTableView: UITableView!
  @IBOutlet weak var bottomPaddingConstraintForTableView: NSLayoutConstraint!
  fileprivate var longPressTimer: Timer?
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyMessageLabel: UILabel!
  @IBOutlet weak var emptyViewAddButton: UIButton!
  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  
  init(viewModel: KNListWalletsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNListWalletsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.displayLoading()
    self.viewModel.reloadDataSource {
      self.walletTableView.reloadData()
      self.hideLoading()
    }
    self.setupUI()
    segmentedControl.highlightSelectedSegment()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupWalletTableView()
    self.setupSegmentedControl()
    self.emptyViewAddButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.emptyViewAddButton.frame.size.height / 2)
    self.updateEmptyView()
    self.addWalletButton.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
  }

  @IBAction func segmentedControlDidChange(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.isDisplayWatchWallets = self.segmentedControl.selectedSegmentIndex == 1
    self.updateEmptyView()
    self.walletTableView.reloadData()
  }
  
  fileprivate func setupSegmentedControl() {
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
  }

  fileprivate func setupNavigationBar() {
  }

  fileprivate func setupWalletTableView() {
    let nib = UINib(nibName: KNListWalletsTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.walletTableView.rowHeight = 60.0
    self.walletTableView.delegate = self
    self.walletTableView.dataSource = self
    self.bottomPaddingConstraintForTableView.constant = self.bottomPaddingSafeArea()

    self.walletTableView.isUserInteractionEnabled = true

    self.view.layoutIfNeeded()
  }

  func updateView(with wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: wallets, curWallet: currentWallet)
    self.updateEmptyView()
    self.walletTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateEmptyView() {
    self.emptyView.isHidden = !self.viewModel.displayWallets.isEmpty
    let walletString = self.segmentedControl.selectedSegmentIndex == 0 ? "wallet" : "watched wallet"
    self.emptyMessageLabel.text = "Your list of \(walletString)s is empty.".toBeLocalised()
    self.addWalletButton.setTitle("Add " + walletString, for: .normal)
  }

  func coordinatorDidUpdateWalletsList() {
    self.displayLoading()
    self.viewModel.listWallets = KNWalletStorage.shared.wallets
    self.viewModel.reloadDataSource {
      self.walletTableView.reloadData()
      self.hideLoading()
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .close)
  }

  @IBAction func addButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .addWallet(type: .full))
  }

  @IBAction func emptyViewAddButtonTapped(_ sender: UIButton) {
    self.delegate?.listWalletsViewController(self, run: self.viewModel.isDisplayWatchWallets ? .addWallet(type: .watch) : .addWallet(type: .onlyReal))
  }
}

extension KNListWalletsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let wallet = self.viewModel.getWallet(at: indexPath.row, section: indexPath.section) else { return }
    var action = [UIAlertAction]()
    if wallet.address.lowercased() != self.viewModel.curWallet.address.lowercased() {
      action.append(UIAlertAction(title: NSLocalizedString("Switch Wallet", comment: ""), style: .default, handler: { _ in
        self.delegate?.listWalletsViewController(self, run: .select(wallet: wallet))
      }))
    }
    action.append(UIAlertAction(title: NSLocalizedString("edit", value: "Edit", comment: ""), style: .default, handler: { _ in
      self.delegate?.listWalletsViewController(self, run: .edit(wallet: wallet))
    }))
    action.append(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      self.delegate?.listWalletsViewController(self, run: .remove(wallet: wallet))
    }))
    action.append(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))

    let alertController = KNActionSheetAlertViewController(title: "", actions: action)
    self.present(alertController, animated: true, completion: nil)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 28, y: 0, width: 200, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = self.viewModel.titleForSection(section: section)
    titleLabel.font = UIFont.Kyber.bold(with: 16)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    guard !self.viewModel.isDisplayWatchWallets else { return 0 }
    return 40
  }
}

extension KNListWalletsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberSections
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows(section: section)
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNListWalletsTableViewCell
    let cm = self.viewModel.getCellModel(at: indexPath.row, section: indexPath.section)
    cell.updateCell(cellModel: cm)
    cell.delegate = self
    if self.viewModel.isCurrentWallet(row: indexPath.row, section: indexPath.section) {
      cell.accessoryType = .checkmark
      cell.tintColor = UIColor.Kyber.SWGreen
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}

extension KNListWalletsViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }
    guard let wallet = self.viewModel.getWallet(at: indexPath.row, section: indexPath.section) else { return nil }

    let copy = SwipeAction(style: .default, title: nil) { (_, _) in
      let data = self.viewModel.getCellModel(at: indexPath.row, section: indexPath.section).wallet
      if self.viewModel.isMultichainWallet(data: data) {
        self.delegate?.listWalletsViewController(self, run: .copy(data: data))
      } else {
        UIPasteboard.general.string = wallet.address
        self.showMessageWithInterval(
          message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
        )
      }
    }
    copy.hidesWhenSelected = true
    copy.title = "copy".toBeLocalised().uppercased()
    copy.textColor = UIColor(named: "normalTextColor")
    copy.font = UIFont.Kyber.medium(with: 12)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 60))!
    copy.backgroundColor = UIColor(patternImage: resized)

    let edit = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.listWalletsViewController(self, run: .edit(wallet: wallet))
    }
    edit.title = "edit".toBeLocalised().uppercased()
    edit.textColor = UIColor(named: "normalTextColor")
    edit.font = UIFont.Kyber.medium(with: 12)
    edit.backgroundColor = UIColor(patternImage: resized)

    let delete = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.listWalletsViewController(self, run: .remove(wallet: wallet))
    }
    delete.title = "delete".toBeLocalised().uppercased()
    delete.textColor = UIColor(named: "normalTextColor")
    delete.font = UIFont.Kyber.medium(with: 12)
    delete.backgroundColor = UIColor(patternImage: resized)

    return [delete, edit, copy]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
