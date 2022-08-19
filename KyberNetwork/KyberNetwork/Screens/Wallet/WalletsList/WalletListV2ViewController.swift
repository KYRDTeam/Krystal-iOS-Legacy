//
//  WalletListV2ViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/08/2022.
//

import UIKit

class WalletListV2ViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
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
