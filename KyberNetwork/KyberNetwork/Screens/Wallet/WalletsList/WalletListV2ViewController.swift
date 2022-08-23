//
//  WalletListV2ViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/08/2022.
//

import UIKit
import KrystalWallets

class WalletListV2ViewModel {
  var wallets: [KWallet] = []
  var watchAddresses: [KAddress] = []
  
  
  
  func reloadData() {
    wallets = WalletManager.shared.getAllWallets()
    watchAddresses = WalletManager.shared.watchAddresses()
    
    
  }
}

class WalletListV2ViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableView: UITableView!
  
  let transitor = TransitionDelegate()
  
  init() {
    super.init(nibName: WalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    walletsTableView.registerCell(WalletCell.self)
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
}


extension WalletListV2ViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
//    let padding = KNGeneralProvider.shared.currentChain == .solana ? 125 : 179
//    return self.viewModel.walletTableViewHeight + CGFloat(padding)
    
    return 600
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension WalletListV2ViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: WalletCell.cellID,
      for: indexPath
    ) as! WalletCell
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 9
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
}
