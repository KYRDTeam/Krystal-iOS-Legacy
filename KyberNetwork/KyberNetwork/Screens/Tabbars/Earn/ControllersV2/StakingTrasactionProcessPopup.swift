//
//  StakingTrasactionProcessPopup.swift
//  KyberNetwork
//
//  Created by Tạ Minh Quân on 02/11/2022.
//

import UIKit

enum StakingProcessPopupEvent {
  case openLink(url: String)
  case goToSupport
  case viewToken(sym: String)
  case close
}

protocol StakingProcessPopupDelegate: class {
  func stakingProcessPopup(_ controller: StakingTrasactionProcessPopup, action: StakingProcessPopupEvent)
}

class StakingTrasactionProcessPopup: KNBaseViewController {
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!
  
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
  
  fileprivate(set) var transaction: InternalHistoryTransaction
  
  weak var delegate: StakingProcessPopupDelegate?
  var state: ProcessStatusState! {
    didSet {
      self.updateUIForStateChange(self.state)
    }
  }
  
  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
    super.init(nibName: StakingTrasactionProcessPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupLoadingView()
    state = .processing
    
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
      self.processStatusLabel.text = "Staking in process"
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
      self.processStatusLabel.text = "Success"
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
  
  fileprivate func setupLoadingView() {
    self.loadingIndicatorView.lineWidth = 2
    self.loadingIndicatorView.lineColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingIndicatorView.labelTextColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingIndicatorView.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    self.loadingIndicatorView.isLoadingIndicator = true
    self.loadingIndicatorView.isLabelHidden = true
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
  
  @IBAction func secondButtonTapped(_ sender: UIButton) {
    switch state {
    case .processing:
      self.txHashButtonTapped(sender)
    case .success:
      self.delegate?.stakingProcessPopup(self, action: .viewToken(sym: self.transaction.toSymbol ?? ""))
    case .failure:
      self.delegate?.stakingProcessPopup(self, action: .goToSupport)
    case .none:
      break
    }
  }
  
  @IBAction func firstButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.stakingProcessPopup(self, action: .close)
    }
  }
  
  @IBAction func txHashButtonTapped(_ sender: UIButton) {
    let urlString = KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(self.transaction.hash)"
    self.delegate?.stakingProcessPopup(self, action: .openLink(url: urlString))
  }
}

extension StakingTrasactionProcessPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 420
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
