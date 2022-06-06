//
//  BridgeTransactionStatusPopup.swift
//  KyberNetwork
//
//  Created by Com1 on 03/06/2022.
//

import UIKit

class BridgeTransactionStatusPopup: KNBaseViewController {

  @IBOutlet weak var fromChainValue: UILabel!
  @IBOutlet weak var fromChainNameLabel: UILabel!
  @IBOutlet weak var fromChainIcon: UIImageView!
  @IBOutlet weak var fromTxHashLabel: UILabel!
  @IBOutlet weak var fromWalletLabel: UILabel!

  @IBOutlet weak var toChainIcon: UIImageView!
  @IBOutlet weak var toChainNameLabel: UILabel!
  @IBOutlet weak var toWalletLabel: UILabel!
  @IBOutlet weak var toTxHashLabel: UILabel!
  @IBOutlet weak var toChainValue: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var tapOutsideView: UIView!

  fileprivate(set) var transaction: InternalHistoryTransaction
  let transitor = TransitionDelegate()
  
  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
    super.init(nibName: BridgeTransactionStatusPopup.className, bundle: nil)
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
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }


  @IBAction func openFromTxHashTapped(_ sender: Any) {
  }


  @IBAction func copyFromWalletTapped(_ sender: Any) {
  }


  @IBAction func openToTxHashTapped(_ sender: Any) {
  }
  
  
  @IBAction func copyToWalletTapped(_ sender: Any) {
  }
}

extension BridgeTransactionStatusPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 600
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
