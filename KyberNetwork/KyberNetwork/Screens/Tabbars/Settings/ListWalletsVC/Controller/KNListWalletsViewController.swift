// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import KrystalWallets

enum KNListWalletsViewEvent {
  case close
  case removeWallet(wallet: KWallet)
  case removeWatchAddress(address: KAddress)
  case editWatchAddress(address: KAddress)
  case editWallet(wallet: KWallet, addressType: KAddressType)
  case addWallet(type: AddNewWalletType)
  case open(wallet: KWallet)
}

enum WalletListSection {
  case multichainWallets
  case normalWallets
}

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent)
}

class KNListWalletsViewModel {
  var isWatchWalletsTabSelecting: Bool = false
  var seedsCellModels: [KNListWalletsTableViewCellModel] = []
  var nonSeedsCellModels: [KNListWalletsTableViewCellModel] = []
  var watchCellModels: [KNListWalletsWatchAddressCellModel] = []

  var wallets: [KWallet] = []
  var watchAddresses: [KAddress] = []
  var walletSections: [WalletListSection] = []
  
  var walletsImportedFromSeed: [KWallet] {
    return wallets.filter { $0.importType == .mnemonic }
  }
  
  var walletsImportedFromKey: [KWallet] {
    return wallets.filter { $0.importType == .privateKey }
  }
  
  var isListEmpty: Bool {
    if isWatchWalletsTabSelecting {
      return watchAddresses.isEmpty
    } else {
      return wallets.isEmpty
    }
  }
  
  init() {
    reloadData()
  }
  
  func reloadData() {
    wallets = WalletManager.shared.getAllWallets()
    watchAddresses = WalletManager.shared.watchAddresses()
    self.walletSections = []
    if !walletsImportedFromSeed.isEmpty {
      walletSections.append(.multichainWallets)
    }
    walletSections.append(.normalWallets)
  }
  
  var numberSections: Int {
    if self.isWatchWalletsTabSelecting {
      return 1
    } else {
      return walletSections.count
    }
  }
  
  func titleForSection(section: Int) -> String {
    if self.isWatchWalletsTabSelecting {
      return ""
    } else {
      switch walletSections[section] {
      case .multichainWallets:
        return "MULTI-CHAIN WALLETS"
      default:
        return "WALLETS"
      }
    }
  }

  func numberRows(section: Int) -> Int {
    if self.isWatchWalletsTabSelecting {
      return self.watchCellModels.count
    } else {
      switch walletSections[section] {
      case .multichainWallets:
        return seedsCellModels.count
      case .normalWallets:
        return nonSeedsCellModels.count
      }
    }
  }

  func reloadDataSource(completion: @escaping () -> Void) {
    reloadData()
    seedsCellModels = walletsImportedFromSeed.map { wallet in
      return KNListWalletsTableViewCellModel(wallet: wallet, address: "")
    }
    nonSeedsCellModels = walletsImportedFromKey.map { wallet in
      let address = WalletManager.shared.getAllAddresses(walletID: wallet.id).first
      return KNListWalletsTableViewCellModel(wallet: wallet, address: address?.addressString ?? "")
    }
    watchCellModels = watchAddresses.map { address in
      return KNListWalletsWatchAddressCellModel(address: address)
    }
    completion()
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
    self.viewModel.isWatchWalletsTabSelecting = self.segmentedControl.selectedSegmentIndex == 1
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

  func reloadData() {
    self.updateEmptyView()
    self.viewModel.reloadDataSource {
      DispatchQueue.main.async {
        self.walletTableView.reloadData()
        self.hideLoading()
      }
    }
  }

  fileprivate func updateEmptyView() {
    self.emptyView.isHidden = !self.viewModel.isListEmpty
    let walletString = self.segmentedControl.selectedSegmentIndex == 0 ? "wallet" : "watched wallet"
    self.emptyMessageLabel.text = "Your list of \(walletString)s is empty.".toBeLocalised()
    self.addWalletButton.setTitle("Add " + walletString, for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .close)
  }

  @IBAction func addButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .addWallet(type: .full))
  }

  @IBAction func emptyViewAddButtonTapped(_ sender: UIButton) {
    self.delegate?.listWalletsViewController(self, run: self.viewModel.isWatchWalletsTabSelecting ? .addWallet(type: .watch) : .addWallet(type: .onlyReal))
  }
}

extension KNListWalletsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if viewModel.isWatchWalletsTabSelecting {
      let watchAddress = viewModel.watchAddresses[indexPath.row]
      var action = [UIAlertAction]()
      action.append(UIAlertAction(title: Strings.edit, style: .default, handler: { _ in
        self.delegate?.listWalletsViewController(self, run: .editWatchAddress(address: watchAddress))
      }))
      action.append(UIAlertAction(title: Strings.delete, style: .destructive, handler: { _ in
        self.delegate?.listWalletsViewController(self, run: .removeWatchAddress(address: watchAddress))
      }))
      action.append(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
      let alertController = KNActionSheetAlertViewController(title: "", actions: action)
      self.present(alertController, animated: true, completion: nil)
    } else {
      switch viewModel.walletSections[indexPath.section] {
      case .multichainWallets:
        let wallet = viewModel.walletsImportedFromSeed[indexPath.row]
        delegate?.listWalletsViewController(self, run: .open(wallet: wallet))
      case .normalWallets:
        let wallet = viewModel.walletsImportedFromKey[indexPath.row]
        guard let address = WalletManager.shared.address(forWalletID: wallet.id) else {
          return
        }
        var action = [UIAlertAction]()
        action.append(UIAlertAction(title: Strings.edit, style: .default, handler: { _ in
          self.delegate?.listWalletsViewController(self, run: .editWallet(wallet: wallet, addressType: address.addressType))
        }))
        action.append(UIAlertAction(title: Strings.delete, style: .destructive, handler: { _ in
          self.delegate?.listWalletsViewController(self, run: .removeWallet(wallet: wallet))
        }))
        action.append(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
        let alertController = KNActionSheetAlertViewController(title: "", actions: action)
        self.present(alertController, animated: true, completion: nil)
      }
    }
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
    guard !self.viewModel.isWatchWalletsTabSelecting else { return 0 }
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
    cell.delegate = self
    cell.selectionStyle = .none
    cell.accessoryType = .none
    if viewModel.isWatchWalletsTabSelecting {
      cell.configure(watchAddressCellModel: viewModel.watchCellModels[indexPath.row])
      return cell
    } else {
      switch viewModel.walletSections[indexPath.section] {
      case .multichainWallets:
        cell.updateCell(cellModel: viewModel.seedsCellModels[indexPath.row])
      case .normalWallets:
        cell.updateCell(cellModel: viewModel.nonSeedsCellModels[indexPath.row])
      }
    }
    return cell
  }
}

extension KNListWalletsViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }
    let copy = SwipeAction(style: .default, title: nil) { [weak self] (_, _) in
      guard let self = self else { return }
      if self.viewModel.isWatchWalletsTabSelecting {
        let address = self.viewModel.watchAddresses[indexPath.row]
        UIPasteboard.general.string = address.addressString
        self.showMessageWithInterval(message: Strings.addressCopied)
      } else {
        switch self.viewModel.walletSections[indexPath.section] {
        case .multichainWallets:
          let wallet = self.viewModel.walletsImportedFromSeed[indexPath.row]
          self.delegate?.listWalletsViewController(self, run: .open(wallet: wallet))
          return
        case .normalWallets:
          let cellModel = self.viewModel.nonSeedsCellModels[indexPath.row]
          UIPasteboard.general.string = cellModel.address
          self.showMessageWithInterval(message: Strings.addressCopied)
        }
      }
    }
    copy.hidesWhenSelected = true
    copy.title = "copy".toBeLocalised().uppercased()
    copy.textColor = UIColor(named: "normalTextColor")
    copy.font = UIFont.Kyber.medium(with: 12)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 60))!
    copy.backgroundColor = UIColor(patternImage: resized)

    let edit = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
      guard let self = self else { return }
      if self.viewModel.isWatchWalletsTabSelecting {
        let address = self.viewModel.watchAddresses[indexPath.row]
        self.delegate?.listWalletsViewController(self, run: .editWatchAddress(address: address))
      } else {
        switch self.viewModel.walletSections[indexPath.section] {
        case .multichainWallets:
          let wallet = self.viewModel.walletsImportedFromSeed[indexPath.row]
          self.delegate?.listWalletsViewController(self, run: .editWallet(wallet: wallet, addressType: .evm))
          return
        case .normalWallets:
          let wallet = self.viewModel.walletsImportedFromKey[indexPath.row]
          guard let address = WalletManager.shared.address(forWalletID: wallet.id) else {
            return
          }
          self.delegate?.listWalletsViewController(self, run: .editWallet(wallet: wallet, addressType: address.addressType))
        }
      }
    }
    edit.title = "edit".toBeLocalised().uppercased()
    edit.textColor = UIColor(named: "normalTextColor")
    edit.font = UIFont.Kyber.medium(with: 12)
    edit.backgroundColor = UIColor(patternImage: resized)

    let delete = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
      guard let self = self else { return }
      if self.viewModel.isWatchWalletsTabSelecting {
        let address = self.viewModel.watchAddresses[indexPath.row]
        self.delegate?.listWalletsViewController(self, run: .removeWatchAddress(address: address))
      } else {
        switch self.viewModel.walletSections[indexPath.section] {
        case .multichainWallets:
          let wallet = self.viewModel.walletsImportedFromSeed[indexPath.row]
          self.delegate?.listWalletsViewController(self, run: .removeWallet(wallet: wallet))
          return
        case .normalWallets:
          let wallet = self.viewModel.walletsImportedFromKey[indexPath.row]
          self.delegate?.listWalletsViewController(self, run: .removeWallet(wallet: wallet))
        }
      }
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
