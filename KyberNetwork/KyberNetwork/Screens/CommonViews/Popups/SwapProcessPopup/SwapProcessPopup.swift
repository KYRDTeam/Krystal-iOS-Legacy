//
//  SwapProcessPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 04/08/2022.
//

import UIKit

class SwapProcessPopup: KNBaseViewController {
//  fileprivate(set) var transaction: InternalHistoryTransaction
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!

  @IBOutlet weak var rateContainView: RectangularDashedView!
  
  @IBOutlet weak var oneStarButton: UIButton!
  @IBOutlet weak var twoStarButton: UIButton!
  @IBOutlet weak var threeStarButton: UIButton!
  @IBOutlet weak var fourStarButton: UIButton!
  @IBOutlet weak var fiveStarButton: UIButton!
  
  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var loadingIndicatorView: SRCountdownTimer!
  
  init() {
//    self.transaction = transaction
    super.init(nibName: SwapProcessPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    self.loadingIndicatorView.start(beginingValue: 5, interval: 1)
  }
  
  @IBAction func txHashButtonTapped(_ sender: UIButton) {
    
  }

  @IBAction func starButtonsTapped(_ sender: UIButton) {
    self.updateRateUI(rate: sender.tag)
    let vc = RateTransactionPopupViewController(currentRate: sender.tag, txHash: "self.transaction.hash")
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }
  
  func updateRateUI(rate: Int) {
    self.oneStarButton.configStarRate(isHighlight: rate >= 1)
    self.twoStarButton.configStarRate(isHighlight: rate >= 2)
    self.threeStarButton.configStarRate(isHighlight: rate >= 3)
    self.fourStarButton.configStarRate(isHighlight: rate >= 4)
    self.fiveStarButton.configStarRate(isHighlight: rate >= 5)
  }
  
}

extension SwapProcessPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 520
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}

extension SwapProcessPopup {
  

  
}

extension SwapProcessPopup: RateTransactionPopupDelegate {
  func didUpdateRate(rate: Int) {
    self.updateRateUI(rate: rate)
  }

  func didSendRate() {
    [oneStarButton, twoStarButton, threeStarButton, fourStarButton, fiveStarButton].forEach { button in
      button.isUserInteractionEnabled = false
    }
  }
}
