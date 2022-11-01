//
//  StakingSummaryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/10/2022.
//

import UIKit
import KrystalWallets
import BigInt
import AppState

class StakingSummaryViewModel {
  var session: KNSession {
    return AppDelegate.session
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var gasPrice: BigInt
  var gasLimit: BigInt
  
  let txObject: TxObject
  let settings: UserSettings
  let displayInfo: StakeDisplayInfo
  
  init(txObject: TxObject, settings: UserSettings, displayInfo: StakeDisplayInfo) {
    self.txObject = txObject
    self.settings = settings
    self.displayInfo = displayInfo
    self.gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? KNGasConfiguration.earnGasLimitDefault
    if let advanced = settings.1?.maxFee {
      self.gasPrice = advanced
    } else {
      self.gasPrice = settings.0.gasPriceType.getGasValue()
    }
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
  let viewModel: StakingSummaryViewModel
  
  init(viewModel: StakingSummaryViewModel) {
    self.viewModel = viewModel
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
    
    let currentChain = AppState.shared.currentChain
    chainIconImageView.image = currentChain.squareIcon()
    chainNameLabel.text = currentChain.chainName()
    
    apyInfoView.setValue(value: viewModel.displayInfo.apy)
    receiveAmountInfoView.setValue(value: viewModel.displayInfo.receiveAmount)
    rateInfoView.setValue(value: viewModel.displayInfo.rate)
    feeInfoView.setValue(value: viewModel.displayInfo.fee)
    
    tokenIconImageView.setImage(urlString: viewModel.displayInfo.stakeTokenIcon, symbol: "")
    tokenNameLabel.text = viewModel.displayInfo.amount
    platformNameLabel.text = "On " + viewModel.displayInfo.platform.uppercased()
    
    
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    
  }
  
  @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
    dismiss(animated: true)
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
