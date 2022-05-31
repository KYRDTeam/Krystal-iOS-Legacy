//
//  BridgeViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit
import BigInt

enum BridgeEvent {
  case openHistory
  case openWalletsList
  case addChainWallet(chainType: ChainType)
  case selectSourceToken
  case willSelectDestChain
  case didSelectDestChain(chain: ChainType)
  case selectDestToken
  case changeShowDestAddress
  case changeAmount(amount: Double)
  case changeDestAddress(address: String)
  case selectSwap
  case checkAllowance(token: TokenObject)
  case sendApprove(token: TokenObject, remain: BigInt)
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
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateAllowance()
  }
  
  fileprivate func updateAllowance() {
    guard KNGeneralProvider.shared.currentChain != .solana else { return }
    guard let currentSourceToken = self.viewModel.currentSourceToken else { return }
    guard !currentSourceToken.isWrapToken && !currentSourceToken.isQuoteToken else { return }

//    self.delegate?.kSwapViewController(self, run: .checkAllowance(token: self.viewModel.from))
    self.delegate?.bridgeViewControllerController(self, run: .checkAllowance(token: currentSourceToken))
  }
  
  func setupUI() {
    self.tableView.registerCellNib(SelectChainCell.self)
    self.tableView.registerCellNib(SelectTokenCell.self)
    self.tableView.registerCellNib(ChainInfoCell.self)
    self.tableView.registerCellNib(BridgeSendToCell.self)
    self.tableView.registerCellNib(BridgeReminderCell.self)
    self.tableView.registerCellNib(BridgeSwapButtonCell.self)
    self.tableView.registerCellNib(TextFieldCell.self)
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
      self.delegate?.bridgeViewControllerController(self, run: .willSelectDestChain)
    }
    
    self.viewModel.selectDestTokenBlock = {
      self.delegate?.bridgeViewControllerController(self, run: .selectDestToken)
    }
    
    self.viewModel.selectSenToBlock = {
      self.delegate?.bridgeViewControllerController(self, run: .changeShowDestAddress)
    }
    
    self.viewModel.changeAmountBlock = { amount in
      if let doubleAmount = Double(amount) {
        self.delegate?.bridgeViewControllerController(self, run: .changeAmount(amount: doubleAmount))
      }
    }
    
    self.viewModel.changeAddressBlock = { address in
      self.delegate?.bridgeViewControllerController(self, run: .changeDestAddress(address: address))
    }
    
    self.viewModel.swapBlock = {
      if self.viewModel.isNeedApprove {
        guard let remain = self.viewModel.remainApprovedAmount else {
          return
        }
        self.delegate?.bridgeViewControllerController(self, run: .sendApprove(token: remain.0, remain: remain.1))
      } else {
        self.delegate?.bridgeViewControllerController(self, run: .selectSwap)
      }
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
    self.setupViewModel()
  }
  
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.walletsListButton.setTitle(self.viewModel.wallet.getWalletObject()?.name ?? "---", for: .normal)
  }
  
  func coordinatorDidUpdateAllowance(token: TokenObject, allowance: BigInt) {
    guard let currentSourceToken = self.viewModel.currentSourceToken else { return }
    
    guard !currentSourceToken.isQuoteToken else {
//      self.updateUIForSendApprove(isShowApproveButton: false)
      return
    }
    self.viewModel.isNeedApprove = currentSourceToken.getBalanceBigInt() > allowance
    if currentSourceToken.getBalanceBigInt() > allowance {
      self.viewModel.remainApprovedAmount = (token, allowance)
    }
    self.tableView.reloadData()
  }

  func coordinatorDidFailUpdateAllowance(token: TokenObject) {
    
  }
  
  func coordinatorSuccessApprove(token: TokenObject) {
    self.viewModel.isNeedApprove = false
    self.tableView.reloadData()
  }

  func coordinatorFailApprove(token: TokenObject) {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
    self.viewModel.isNeedApprove = true
    self.tableView.reloadData()
  }
  
  func openSwitchChainPopup(_ chainTypes: [ChainType] = ChainType.getAllChain(), _ shouldChangeWallet: Bool = true) {
    let popup = SwitchChainViewController()
    popup.dataSource = chainTypes
    popup.completionHandler = { selected in
      if !shouldChangeWallet {
        self.delegate?.bridgeViewControllerController(self, run: .didSelectDestChain(chain: selected))
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
