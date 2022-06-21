//
//  EarnMenuViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/26/21.
//

import UIKit
import KrystalWallets

protocol EarnMenuViewControllerDelegate: class {
  func earnMenuViewControllerDidSelectToken(controller: EarnMenuViewController, token: TokenData)
  func earnMenuViewControllerDidSelectAddChainWallet(controller: EarnMenuViewController, chainType: ChainType)
}

class EarnMenuViewModel {
  var dataSource: [EarnMenuTableViewCellViewModel] = []
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
}

class EarnMenuViewController: KNBaseViewController {
  @IBOutlet weak var menuTableView: UITableView!
  @IBOutlet weak var walletsSelectButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet var warningContainerView: UIView!
  @IBOutlet weak var mainInfoTitle: UILabel!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var noDataLabel: UILabel!

  let viewModel: EarnMenuViewModel
  weak var delegate: EarnMenuViewControllerDelegate?
  fileprivate var isViewSetup: Bool = false
  weak var navigationDelegate: NavigationBarDelegate?

  init(viewModel: EarnMenuViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnMenuViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: EarnMenuTableViewCell.className, bundle: nil)
    self.menuTableView.register(
      nib,
      forCellReuseIdentifier: EarnMenuTableViewCell.kCellID
    )
    self.menuTableView.rowHeight = EarnMenuTableViewCell.kCellHeight
    self.updateUIWalletSelectButton()
    self.menuTableView.tableFooterView = self.warningContainerView
    let attributedString = NSMutableAttributedString(string: "Select the token you wish to supply to earn interest. Interest rate may change as per market dynamics.\n", attributes: [
      .font: UIFont(name: "Karla-Regular", size: 16.0)!,
      .foregroundColor: UIColor(named: "textWhiteColor"),
      .kern: 0.0
    ])
    attributedString.addAttributes([
      .font: UIFont(name: "Karla-Bold", size: 16.0)!,
      .foregroundColor: UIColor(named: "buttonBackgroundColor")
    ], range: NSRange(location: 29, length: 6))
    attributedString.addAttributes([
      .font: UIFont(name: "Karla-Bold", size: 16.0)!,
      .foregroundColor: UIColor(named: "buttonBackgroundColor")
    ], range: NSRange(location: 39, length: 13))
    self.mainInfoTitle.attributedText = attributedString
    self.noDataLabel.text = (KNGeneralProvider.shared.currentChain == .eth || KNGeneralProvider.shared.currentChain == .bsc || KNGeneralProvider.shared.currentChain == .polygon) ? "No data" : "Coming soon"
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.updateUIPendingTxIndicatorView()
    self.updateUISwitchChain()
    self.updateUIEmptyView()
  }

  fileprivate func updateUISwitchChain() {
    guard self.isViewLoaded else {
      return
    }
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
  }
  
  fileprivate func updateUIWalletSelectButton() {
    self.walletsSelectButton.setTitle(viewModel.currentAddress.name, for: .normal)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }

  @IBAction func walletsButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "APY (Annual percentage yield) may change over time".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 10
    )
  }

  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { [weak self] selected in
      guard let self = self else { return }
      if KNWalletStorage.shared.getAvailableWalletForChain(selected).isEmpty {
        self.delegate?.earnMenuViewControllerDidSelectAddChainWallet(controller: self, chainType: selected)
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selected)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.present(popup, animated: true, completion: nil)
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

  fileprivate func updateUIEmptyView() {
    if self.isViewLoaded {
      self.emptyView.isHidden = !self.viewModel.dataSource.isEmpty
    }
  }
  
  func coordinatorDidUpdateLendingToken(_ tokens: [TokenData]) {
    self.viewModel.dataSource = tokens.map { EarnMenuTableViewCellViewModel(token: $0) }.sorted(by: { (left, right) -> Bool in
      return left.supplyRate > right.supplyRate
    })
    self.updateUIEmptyView()
    if self.isViewSetup {
      DispatchQueue.main.async {
        self.menuTableView.reloadData()
      }
      
    }
  }
  
  func coordinatorAppSwitchAddress() {
    if self.isViewSetup {
      self.updateUIWalletSelectButton()
      self.updateUIPendingTxIndicatorView()
    }
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }

  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
  }
}

extension EarnMenuViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: EarnMenuTableViewCell.kCellID,
      for: indexPath
    ) as! EarnMenuTableViewCell
    let cellViewModel = viewModel.dataSource[indexPath.row]
    cell.updateCellWithViewModel(cellViewModel)
    return cell
  }
}

extension EarnMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.earnMenuViewControllerDidSelectToken(controller: self, token: self.viewModel.dataSource[indexPath.row].token)
  }
}
