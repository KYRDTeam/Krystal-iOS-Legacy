//
//  SwapProcessPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 04/08/2022.
//

import UIKit
import AppState

enum ProcessStatusState {
  case processing
  case success
  case failure
}

enum SwapProcessPopupEvent {
  case openLink(url: String)
  case goToSupport
  case viewToken(sym: String)
  case close
}

protocol SwapProcessPopupDelegate: class {
  func swapProcessPopup(_ controller: SwapProcessPopup, action: SwapProcessPopupEvent)
}

class SwapProcessPopup: KNBaseViewController {
  fileprivate(set) var transaction: InternalHistoryTransaction
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
  @IBOutlet weak var statusContainerView: UIView!
  @IBOutlet weak var transactionStateIcon: UIImageView!
  
  @IBOutlet weak var sourceTokenInfoContainerView: UIView!
  @IBOutlet weak var destTokenInfoContainerView: UIView!
  @IBOutlet weak var sourceTokenIcon: UIImageView!
  @IBOutlet weak var sourceTokenAmountLabel: UILabel!
  @IBOutlet weak var destTokenIcon: UIImageView!
  @IBOutlet weak var destTokenAmountLabel: UILabel!
  @IBOutlet weak var processStatusLabel: UILabel!
  
  weak var delegate: SwapProcessPopupDelegate?
  var state: ProcessStatusState! {
    didSet {
      self.updateUIForStateChange(self.state)
    }
  }
  
  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
    super.init(nibName: SwapProcessPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.setupLoadingView()
    self.state = .processing
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
  @objc func transactionStateDidUpdate(_ sender: Notification) {
    guard let transaction = sender.object as? InternalHistoryTransaction else { return }
    if self.transaction.hash == transaction.hash {
      self.updateView(with: transaction)
    }
  }
  
  @IBAction func firstButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.swapProcessPopup(self, action: .close)
    }
  }
  
  @IBAction func secondButtonTapped(_ sender: UIButton) {
    switch state {
    case .processing:
      self.txHashButtonTapped(sender)
    case .success:
      self.delegate?.swapProcessPopup(self, action: .viewToken(sym: self.transaction.toSymbol ?? ""))
    case .failure:
      self.delegate?.swapProcessPopup(self, action: .goToSupport)
    case .none:
      break
    }
  }
  
  @IBAction func txHashButtonTapped(_ sender: UIButton) {
    let urlString = KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(self.transaction.hash)"
    self.delegate?.swapProcessPopup(self, action: .openLink(url: urlString))
  }
  
  func updateUIForStateChange(_ state: ProcessStatusState) {
    switch state {
    case .processing:
      self.loadingIndicatorView.isHidden = false
      self.transactionStateIcon.isHidden = true
      self.statusContainerView.bringSubviewToFront(self.loadingIndicatorView)
      self.loadingIndicatorView.start(beginingValue: 1)
      let buttonTitle = "Open \(KNGeneralProvider.shared.currentChain.customRPC().webScanName)"
      self.secondButton.setTitle(buttonTitle, for: .normal)
      self.sourceTokenInfoContainerView.rounded(color: UIColor.Kyber.buttonBg, width: 1, radius: 16)
      self.destTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
      self.processStatusLabel.text = "Processing Transaction"
      MixPanelManager.track("swap_pending_pop_up_open", properties: ["screenid": "swap_pending_pop_up"])
    case .success:
      self.loadingIndicatorView.isHidden = true
      self.transactionStateIcon.isHidden = false
      self.statusContainerView.bringSubviewToFront(self.transactionStateIcon)
      self.transactionStateIcon.image = UIImage(named: "tx_status_success")
      self.secondButton.setTitle("", for: .normal)
      let buttonTitle = "View \(self.transaction.toSymbol ?? "")"
      self.secondButton.setTitle(buttonTitle, for: .normal)
      self.destTokenInfoContainerView.rounded(color: UIColor.Kyber.buttonBg, width: 1, radius: 16)
      self.sourceTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
      self.processStatusLabel.text = "Swapped Successfully"
      MixPanelManager.track("swap_done_pop_up_open", properties: ["screenid": "swap_done_pop_up", "txn_hash": transaction.hash, "chain_id": AppState.shared.currentChain.getChainId()])
    case .failure:
      self.loadingIndicatorView.isHidden = true
      self.transactionStateIcon.isHidden = false
      self.statusContainerView.bringSubviewToFront(self.transactionStateIcon)
      self.transactionStateIcon.image = UIImage(named: "tx_status_fail")
      let buttonTitle = "Go to support"
      self.secondButton.setTitle(buttonTitle, for: .normal)
      self.destTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
      self.sourceTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
      self.processStatusLabel.text = "Transaction Failed"
      MixPanelManager.track("swap_fail_pop_up_open", properties: ["screenid": "swap_fail_pop_up"])
    }
  }
  
  func setupUI() {
    self.sourceTokenIcon.setSymbolImage(symbol: self.transaction.fromSymbol, size: sourceTokenIcon.frame.size)
    self.destTokenIcon.setSymbolImage(symbol: self.transaction.toSymbol, size: destTokenIcon.frame.size)
    self.txHashLabel.text = self.transaction.hash
    let descriptions = self.transaction.transactionDescription.split(separator: "→").map { String($0) }
    self.sourceTokenAmountLabel.text = descriptions.first ?? ""
    self.destTokenAmountLabel.text = descriptions.last ?? ""
    
  }

  @IBAction func starButtonsTapped(_ sender: UIButton) {
    self.updateRateUI(rate: sender.tag)
    let vc = RateTransactionPopupViewController(currentRate: sender.tag, txHash: "self.transaction.hash")
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }
  
  fileprivate func setupLoadingView() {
    self.loadingIndicatorView.lineWidth = 2
    self.loadingIndicatorView.lineColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingIndicatorView.labelTextColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingIndicatorView.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    self.loadingIndicatorView.isLoadingIndicator = true
    self.loadingIndicatorView.isLabelHidden = true
  }
  
  func updateRateUI(rate: Int) {
    self.oneStarButton.configStarRate(isHighlight: rate >= 1)
    self.twoStarButton.configStarRate(isHighlight: rate >= 2)
    self.threeStarButton.configStarRate(isHighlight: rate >= 3)
    self.fourStarButton.configStarRate(isHighlight: rate >= 4)
    self.fiveStarButton.configStarRate(isHighlight: rate >= 5)
  }
  
  func updateView(with tx: InternalHistoryTransaction) {
    switch tx.state {
    case .pending:
      self.state = .processing
    case .error, .drop:
      state = .failure
    case .done:
      state = .success
    default:
      state = .processing
    }
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true) {
      self.delegate?.swapProcessPopup(self, action: .close)
    }
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
