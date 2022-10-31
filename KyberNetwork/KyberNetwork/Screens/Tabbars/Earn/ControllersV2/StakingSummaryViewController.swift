//
//  StakingSummaryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/10/2022.
//

import UIKit
import KrystalWallets

class StakingSummaryViewModel {
  var session: KNSession {
    return AppDelegate.session
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  
}

class StakingSummaryViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  @IBOutlet weak var chainIconImageView: UIImageView!
  @IBOutlet weak var chainNameLabel: UILabel!
  
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var platformNameLabel: UILabel!
  
  @IBOutlet weak var apyInfoView: SwapInfoView!
  @IBOutlet weak var receiveAmountInfoView: SwapInfoView!
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var feeInfoView: SwapInfoView!
  
  let transitor = TransitionDelegate()
  
  init() {
    super.init(nibName: StakingSummaryViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  private func setupUI() {
    apyInfoView.setTitle(title: "APY (Est. Yield", underlined: false)
    apyInfoView.iconImageView.isHidden = true
    
    receiveAmountInfoView.setTitle(title: "You will receive", underlined: false)
    receiveAmountInfoView.iconImageView.isHidden = true
    
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.iconImageView.isHidden = true
    
    feeInfoView.setTitle(title: "Network Fee", underlined: false)
    feeInfoView.iconImageView.isHidden = true
    
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    
  }
  
}

extension StakingSummaryViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 542
    
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
