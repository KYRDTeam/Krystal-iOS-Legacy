//
//  BridgeViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

enum BridgeEvent {
  case switchChain
  case openHistory
  case openWalletsList
  case addChainWallet(chainType: ChainType)
  case selectSourceToken
  case selectDestChain
  case selectDestToken
}

protocol BridgeViewControllerDelegate: class {
  func bridgeViewControllerController(_ controller: BridgeViewController, run event: BridgeEvent)
}

class BridgeViewController: KNBaseViewController {
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var walletsListButton: UIButton!
  weak var delegate: BridgeViewControllerDelegate?
  var viewModel: BridgeViewModel
  
  init(viewModel: BridgeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: BridgeViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.setupViewModel()
  }
  
  func setupUI() {
    self.tableView.registerCellNib(SelectChainCell.self)
    self.tableView.registerCellNib(SelectTokenCell.self)
    self.tableView.registerCellNib(ChainInfoCell.self)
    self.tableView.registerCellNib(BridgeSendToCell.self)
    self.tableView.registerCellNib(BridgeReminderCell.self)
    self.tableView.registerCellNib(BridgeSwapButtonCell.self)
    self.updateUISwitchChain()
  }
  
  func setupViewModel() {
    self.viewModel.selectSourceChainBlock = {
      self.openSwitchChainPopup()
    }
    
    self.viewModel.selectSourceTokenBlock = {
      self.delegate?.bridgeViewControllerController(self, run: .selectSourceToken)
    }
    
    self.viewModel.selectDestChainBlock = {
      self.delegate?.bridgeViewControllerController(self, run: .selectDestChain)
    }
    
    self.viewModel.selectDestTokenBlock = {
      self.delegate?.bridgeViewControllerController(self, run: .selectDestToken)
    }
  }
  
  func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.chainIcon.image = icon
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
    self.tableView.reloadData()
  }
  
  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
  }
  
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
  }
  
  func openSwitchChainPopup(_ chainTypes: [ChainType] = ChainType.getAllChain(), _ shouldChainWallet: Bool = true) {
    let popup = SwitchChainViewController()
    popup.dataSource = chainTypes
    popup.completionHandler = { selected in
      if !shouldChainWallet {
        self.viewModel.currentDestChain = selected
        self.tableView.reloadData()
      } else if KNWalletStorage.shared.getAvailableWalletForChain(selected).isEmpty {
        self.delegate?.bridgeViewControllerController(self, run: .addChainWallet(chainType: selected))
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selected)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.present(popup, animated: true, completion: nil)
  }

  @IBAction func switchWalletButtonTapped(_ sender: Any) {
    self.delegate?.bridgeViewControllerController(self, run: .openWalletsList)
  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func switchChainButtonTapped(_ sender: Any) {
    self.openSwitchChainPopup()
  }

  @IBAction func showHistoryButtonTapped(_ sender: Any) {
    
  }
}

extension BridgeViewController {
  func coordinatorDidUpdateData() {
    self.tableView.reloadData()
  }
}

extension BridgeViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return self.viewModel.cellForRows(tableView: tableView, indexPath: indexPath)
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows(section: section)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberOfSection()
  }
}

extension BridgeViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return CGFloat(32.0)
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return section == 0 ? CGFloat(80) : CGFloat(0.01)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return self.viewModel.viewForHeader(section: section)
  }
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return section == 0 ? self.viewModel.viewForFooter() : nil
  }
}
