//
//  WalletsListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/20/20.
//

import UIKit
import MBProgressHUD
import KrystalWallets

enum WalletsListViewEvent {
  case didSelect(address: KAddress)
  case manageWallet
  case connectWallet
  case addWallet
}

protocol WalletsListViewControllerDelegate: class {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent)
}

class WalletsListViewModel {
  
  let walletManager = WalletManager.shared
  
  var addresses: [KAddress]
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  init() {
    let addressType = KNGeneralProvider.shared.chainAddressType
    self.addresses = walletManager.getAllAddresses(addressType: addressType)
  }

  var watchAddresses: [KAddress] {
    return addresses.filter { $0.isWatchWallet }.sorted(by: { lhs, _ in lhs == currentAddress })
  }
  
  var realAddresses: [KAddress] {
    return addresses.filter { !$0.isWatchWallet }.sorted(by: { lhs, _ in lhs == currentAddress })
  }

  var dataSource: [Any] {
    var data: [Any] = []
    let realAddressViewModels = realAddresses.map { address in
      return WalletListTableViewCellViewModel(
        walletName: address.name,
        walletAddress: address.addressString,
        isCurrentWallet: address == currentAddress
      )
    }
    if !realAddressViewModels.isEmpty {
      let sectionViewModel = WalletListSectionTableViewCellViewModel(sectionTile: "Change Wallets", isFirstSection: true)
      data.append(sectionViewModel)
      data.append(contentsOf: realAddressViewModels)
    }
    
    let watchAddressViewMoels = watchAddresses.map { address in
      return WalletListTableViewCellViewModel(
        walletName: address.name,
        walletAddress: address.addressString,
        isCurrentWallet: address == currentAddress
      )
    }

    if !watchAddressViewMoels.isEmpty {
      let sectionModel = WalletListSectionTableViewCellViewModel(sectionTile: "Watch wallets", isFirstSection: data.isEmpty)
      data.append(sectionModel)
      data.append(contentsOf: watchAddressViewMoels)
    }

    return data
  }

  var walletCellRowHeight: CGFloat {
    return 60.0
  }

  var walletCellSectionRowHeight: CGFloat {
    return 80.0
  }
  
  func getAddress(addressString: String) -> KAddress? {
    return addresses.first { $0.addressString == addressString }
  }

  var walletTableViewHeight: CGFloat {
    var realWalletCellsHeight = CGFloat(self.realAddresses.count) * self.walletCellRowHeight
    if realWalletCellsHeight > 0 {
      realWalletCellsHeight += self.walletCellSectionRowHeight
    }
    var watchWalletCellsHeight = CGFloat(self.watchAddresses.count) * self.walletCellRowHeight
    if watchWalletCellsHeight > 0 {
      watchWalletCellsHeight += self.walletCellSectionRowHeight
    }
    return min(372.0, realWalletCellsHeight + watchWalletCellsHeight)
  }
}

class WalletsListViewController: KNBaseViewController {
  @IBOutlet weak var walletTableView: UITableView!
  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var connectWalletButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var manageWalletTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var qrCodeIcon: UIImageView!
  fileprivate var viewModel: WalletsListViewModel

  fileprivate let kWalletTableViewCellID: String = "WalletListTableViewCell"
  fileprivate let kWalletSectionTableViewCellID: String = "WalletListSectionTableViewCell"
  let transitor = TransitionDelegate()
  weak var delegate: WalletsListViewControllerDelegate?

  init(viewModel: WalletsListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: WalletListTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kWalletTableViewCellID)

    let sectionNib = UINib(nibName: WalletListSectionTableViewCell.className, bundle: nil)
    self.walletTableView.register(sectionNib, forCellReuseIdentifier: kWalletSectionTableViewCellID)

    self.walletsTableViewHeightContraint.constant = self.viewModel.walletTableViewHeight
    self.walletTableView.allowsSelection = true
    self.connectWalletButton.isHidden = KNGeneralProvider.shared.currentChain == .solana
    self.qrCodeIcon.isHidden = KNGeneralProvider.shared.currentChain == .solana
    self.manageWalletTopConstraint.constant = KNGeneralProvider.shared.currentChain == .solana ? 12 : 66
  }

  @IBAction func manageWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .manageWallet)
    }
  }

  @IBAction func connectWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .connectWallet)
    }
  }

  @IBAction func tapView(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension WalletsListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let viewModel = self.viewModel.dataSource[indexPath.row]
    if let sectionViewModel = viewModel as? WalletListSectionTableViewCellViewModel {
      let cell = tableView.dequeueReusableCell(withIdentifier: kWalletSectionTableViewCellID, for: indexPath) as! WalletListSectionTableViewCell
      cell.updateCellWith(viewModel: sectionViewModel)
      cell.delegate = self
      return cell
    }

    if let cellViewModel = viewModel as? WalletListTableViewCellViewModel {
      let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath) as! WalletListTableViewCell
      cell.updateCell(with: cellViewModel)
      cell.delegate = self
      return cell
    }
    return UITableViewCell()
  }
}

extension WalletsListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let viewModel = self.viewModel.dataSource[indexPath.row]
    if let sectionModel = viewModel as? WalletListSectionTableViewCellViewModel {
      return sectionModel.isFirstSection ? 80.0 : 60.0
    } else {
      return 60.0
    }
  }
}

extension WalletsListViewController: WalletListTableViewCellDelegate {
  func walletListTableViewCell(_ controller: WalletListTableViewCell, run event: WalletListTableViewCellEvent) {
    switch event {
    case .copy(let addressString):
      if let address = self.viewModel.getAddress(addressString: addressString) {
        UIPasteboard.general.string = address.addressString
        self.showMessage(text: Strings.copied)
      }
    case .select(let addressString):
      self.dismiss(animated: true) {
        if let address = self.viewModel.getAddress(addressString: addressString) {
          AppDelegate.shared.coordinator.switchAddress(address: address)
          self.delegate?.walletsListViewController(self, run: .didSelect(address: address))
        }
      }
    }
  }
}

extension WalletsListViewController: WalletListSectionTableViewCellDelegate {
  func walletListSectionTableViewCellDidSelectAction(_ cell: WalletListSectionTableViewCell) {
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .addWallet)
    }
  }
}

extension WalletsListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    let padding = KNGeneralProvider.shared.currentChain == .solana ? 125 : 179
    return self.viewModel.walletTableViewHeight + CGFloat(padding)
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
