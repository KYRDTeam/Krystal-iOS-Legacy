//
//  SwitchChainWalletsListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/2/21.
//

import UIKit
import KrystalWallets

class SwitchChainWalletsListViewModel {
  let dataSource: [KNWalletTableCellViewModel]
  var selectedAddress: KAddress?
  let selectedChain: ChainType
  var addresses: [KAddress]
  var completionHandler: (ChainType) -> Void = { selected in }
  
  init(selected: ChainType) {
    self.selectedChain = selected
    self.addresses = WalletManager.shared.getAllAddresses(addressType: selected.addressType)
    self.dataSource = addresses.map { address -> KNWalletTableCellViewModel in
      return KNWalletTableCellViewModel(address: address)
    }
  }
  
  var title: String {
    return "Choose Wallet"
  }
}

class SwitchChainWalletsListViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet var backgroundView: UIView!
  @IBOutlet weak var nextButton: UIButton!
  
  let kContactTableViewCellID: String = "kContactTableViewCellID"
  let transitor = TransitionDelegate()
  let viewModel: SwitchChainWalletsListViewModel
  
  init(viewModel: SwitchChainWalletsListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SwitchChainWalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
    
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: KNContactTableViewCell.className, bundle: nil)
    self.walletsTableView.register(nib, forCellReuseIdentifier: kContactTableViewCellID)
    self.walletsTableView.rowHeight = KNContactTableViewCell.height
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self
    self.titleLabel.text = self.viewModel.title
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    backgroundView.addGestureRecognizer(tapGesture)
    self.updateUINextButton(isActive: viewModel.selectedAddress != nil)
  }

  @objc func tapOutside() {
      self.dismiss(animated: true, completion: nil)
  }

  @IBAction func nextButtonTapped(_ sender: UIButton) {
    if viewModel.selectedAddress == nil {
      self.viewModel.selectedAddress = self.viewModel.dataSource.first?.address
    }
    self.dismiss(animated: true) {
      KNGeneralProvider.shared.currentChain = self.viewModel.selectedChain
      var userInfo: [String: Any] = [:]
      userInfo["chain"] = self.viewModel.selectedChain
      KNNotificationUtil.postNotification(
        for: kChangeChainNotificationKey,
        object: nil,
        userInfo: userInfo
      )
      self.viewModel.completionHandler(self.viewModel.selectedChain)
      guard let address = self.viewModel.selectedAddress else {
        return
      }
      guard let wallet = WalletManager.shared.wallet(forAddress: address) else {
        return
      }
      AppDelegate.shared.coordinator.switchWallet(wallet: wallet, chain: self.viewModel.selectedChain)
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  private func updateUINextButton(isActive: Bool) {
    if isActive {
      self.nextButton.alpha = 1
      self.nextButton.isEnabled = true
    } else {
      self.nextButton.alpha = 0.2
      self.nextButton.isEnabled = false
    }
  }
}

extension SwitchChainWalletsListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}


extension SwitchChainWalletsListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellModel = self.viewModel.dataSource[indexPath.row]
    self.viewModel.selectedAddress = cellModel.address
    self.updateUINextButton(isActive: viewModel.selectedAddress != nil)
    tableView.reloadData()
  }
}

extension SwitchChainWalletsListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath) as! KNContactTableViewCell
    let cellModel = self.viewModel.dataSource[indexPath.row]
    cell.update(with: cellModel, selected: self.viewModel.selectedAddress)
    return cell
  }
}
