//
//  ConfirmBridgeViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 30/05/2022.
//

import UIKit

struct ConfirmBridgeViewModel {
  let fromChain: ChainType?
  let fromValue: String
  let fromAddress: String
  let toChain: ChainType?
  let toValue: String
  let toAddress: String
  let fee: String
  
  init(fromChain: ChainType?,
       fromValue: String,
       fromAddress: String,
       toChain: ChainType?,
       toValue: String,
       toAddress: String,
       fee: String) {
    self.fromChain = fromChain
    self.fromValue = fromValue
    self.fromAddress = fromAddress
    self.toChain = toChain
    self.toValue = toValue
    self.toAddress = toAddress
    self.fee = fee
  }
}

class ConfirmBridgeViewController: KNBaseViewController {

  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var fromTokenValueLabel: UILabel!
  @IBOutlet weak var fromChainLabel: UILabel!
  @IBOutlet weak var fromIcon: UIImageView!
  @IBOutlet weak var toIcon: UIImageView!
  @IBOutlet weak var toChainLabel: UILabel!
  @IBOutlet weak var toChainTokenValueLabel: UILabel!
  @IBOutlet weak var toAddressLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UIButton!
  @IBOutlet weak var estimatedTimeLabel: UIButton!
  
  @IBOutlet weak var tapOutsideView: UIView!
  @IBOutlet weak var contentView: UIScrollView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containViewHeighConstraint: NSLayoutConstraint!
  fileprivate var viewModel: ConfirmBridgeViewModel
  let transitor = TransitionDelegate()
  
  init(viewModel: ConfirmBridgeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ConfirmBridgeViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.tapOutsideView.addGestureRecognizer(tapGesture)
    self.fromIcon.image = self.viewModel.fromChain?.chainIcon()
    self.fromChainLabel.text = self.viewModel.fromChain?.chainName()
    self.fromTokenValueLabel.text = self.viewModel.fromValue
    self.fromAddressLabel.text = self.viewModel.fromAddress
    self.toIcon.image = self.viewModel.toChain?.chainIcon()
    self.toChainLabel.text = self.viewModel.toChain?.chainName()
    self.toChainTokenValueLabel.text = self.viewModel.toValue
    self.toAddressLabel.text = self.viewModel.toAddress
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: {
      
    })
  }
  
  @IBAction func editButtonTapped(_ sender: Any) {
  }
  
  @IBAction func confirmButtonTapped(_ sender: Any) {

  }
}

extension ConfirmBridgeViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.containViewHeighConstraint.constant
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
