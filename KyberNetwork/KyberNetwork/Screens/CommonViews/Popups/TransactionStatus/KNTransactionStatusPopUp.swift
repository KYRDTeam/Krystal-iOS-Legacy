// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNTransactionStatusPopUpEvent {
  case dismiss
  case swap
  case transfer
  case tryAgain
  case openLink(url: String)
  case speedUp(tx: Transaction)
  case cancel(tx: Transaction)
  case goToSupport
  case backToInvest
}

protocol KNTransactionStatusPopUpDelegate: class {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent)
}

class KNTransactionStatusPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleIconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!
  @IBOutlet weak var subTitleDetailLabel: UILabel!
  @IBOutlet weak var subTitleLabelCenterContraint: NSLayoutConstraint!
  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var subTitleTopContraint: NSLayoutConstraint!

  // Broadcast
  @IBOutlet weak var loadingImageView: UIImageView!
  // 32 if broadcasting, 104 if done/failed

  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!

  weak var delegate: KNTransactionStatusPopUpDelegate?

  fileprivate(set) var transaction: KNTransaction
  let transitor = TransitionDelegate()
  
  var earnAmountString: String?
  var netAPYEarnString: String?
  var earnPlatform: LendingPlatformData?
  
  var withdrawAmount: String?
  var withdrawTokenSym: String?

  init(transaction: KNTransaction) {
    self.transaction = transaction
    super.init(nibName: KNTransactionStatusPopUp.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    let name = Notification.Name(rawValue: "viewDidBecomeActive")
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.commontSetup()
    let name = Notification.Name(rawValue: "viewDidBecomeActive")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.viewDidBecomeActive(_:)),
      name: name,
      object: nil
    )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateView(with: self.transaction)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if !self.loadingImageView.isHidden {
      self.loadingImageView.stopAnimating()
    }
  }

  fileprivate func commontSetup() {
    self.firstButton.setTitle(NSLocalizedString("transfer", comment: ""), for: .normal)
    self.firstButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.firstButton.frame.size.height / 2)

    self.secondButton.setTitle(NSLocalizedString("swap", comment: ""), for: .normal)
    self.secondButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.secondButton.frame.size.height / 2)
    self.txHashLabel.text = self.transaction.id
    self.view.isUserInteractionEnabled = true
  }

  fileprivate func updateViewTransactionDidChange() {
    let (id, rate) = self.transaction.getNewTxDetails()
    self.txHashLabel.text = id

    if self.transaction.state == .pending {
      self.titleIconImageView.image = UIImage(named: "tx_broadcasted_icon")
      self.titleLabel.text = "Broadcasted!".toBeLocalised().uppercased()
      self.subTitleLabel.text = "Transaction being mined".toBeLocalised()
      self.subTitleLabelCenterContraint.constant = 16
      self.subTitleTopContraint.constant = 29

      self.loadingImageView.isHidden = false
      self.loadingImageView.startRotating()

      self.subTitleDetailLabel.isHidden = true
      self.firstButton.setTitle("speed up".toBeLocalised(), for: .normal)
      self.secondButton.setTitle("cancel".toBeLocalised(), for: .normal)

      self.view.layoutSubviews()
    } else if self.transaction.state == .completed {
      self.titleIconImageView.image = UIImage(named: "tx_success_icon")
      self.titleLabel.text = "Done!".toBeLocalised().uppercased()
      self.subTitleLabel.text = {
        if transaction.type == .cancel {
          return "Your transaction has been cancelled successfully".toBeLocalised()
        } else if transaction.type == .speedup {
          return "Your transaction has been speeded up successfully".toBeLocalised()
        } else if self.transaction.isTransfer {
          return "Transferred successfully".toBeLocalised()
        } else if self.transaction.type == .earn {
          return "Successfully saved".toBeLocalised()
        } else if self.transaction.type == .withdraw {
          return "Successfully withdraw".toBeLocalised()
        }
        return "Swapped successfully".toBeLocalised()
      }()
      self.subTitleLabelCenterContraint.constant = 0
      self.subTitleTopContraint.constant = 20
      var subTitleText = rate
      if self.transaction.type == .earn {
        subTitleText = "\(self.earnAmountString ?? "") \("with".toBeLocalised()) \(self.netAPYEarnString ?? "") APY"
      } else if self.transaction.type == .withdraw {
        subTitleText = "\(self.withdrawAmount ?? "") \(self.withdrawTokenSym ?? "")"
      }
      //TODO: improve status popup with data get for event obj
      self.subTitleDetailLabel.isHidden = true
      self.subTitleDetailLabel.isHidden = false
      self.subTitleDetailLabel.text = subTitleText?.uppercased()
      self.subTitleDetailLabel.font = UIFont.Kyber.latoRegular(with: 16)

      self.loadingImageView.stopRotating()
      self.loadingImageView.isHidden = true

      if self.transaction.type == .earn {
        self.firstButton.setTitle("New save".toBeLocalised().capitalized, for: .normal)
        self.secondButton.setTitle("Back to invest".toBeLocalised().capitalized, for: .normal)
      } else if self.transaction.type == .withdraw {
        self.firstButton.isHidden = true
        self.secondButton.isHidden = true
      } else {
        self.firstButton.setTitle("transfer".toBeLocalised().capitalized, for: .normal)
        self.secondButton.setTitle("New swap".toBeLocalised().capitalized, for: .normal)
      }

      self.view.layoutSubviews()
    } else if self.transaction.state == .error || self.transaction.state == .failed {
      self.titleIconImageView.image = UIImage(named: "tx_failed_icon")
      self.titleLabel.text = "Failed!".toBeLocalised().uppercased()
      if self.transaction.state == .error {
        var errorTitle = ""
        switch transaction.type {
        case .cancel:
          errorTitle = "Your cancel transaction might be lost".toBeLocalised()
        case .speedup:
          errorTitle = "Your speedup transaction might be lost".toBeLocalised()
        default:
          errorTitle = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
        }
        self.subTitleLabel.text = errorTitle
      } else {
        self.subTitleLabel.text = "Transaction error".toBeLocalised()
      }
      self.subTitleLabelCenterContraint.constant = 0
      self.subTitleTopContraint.constant = 20
      self.subTitleDetailLabel.isHidden = true

      self.loadingImageView.stopRotating()
      self.loadingImageView.isHidden = true

      self.firstButton.setTitle("cancel".toBeLocalised(), for: .normal)
      self.secondButton.setTitle("Go to support".toBeLocalised(), for: .normal) //TODO: request localized text

      self.view.layoutSubviews()
    }
  }

  func updateView(with transaction: KNTransaction?) {
    if let trans = transaction {
      self.transaction = trans
    } else {
      self.transaction.internalState = TransactionState.error.rawValue
    }
    self.updateViewTransactionDidChange()
  }

  @objc func viewDidBecomeActive(_ sender: Any?) {
    if !self.loadingImageView.isHidden {
      self.loadingImageView.startRotating()
    }
  }

  @IBAction func openTransactionDetailsPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      let urlString = KNEnvironment.default.etherScanIOURLString + "tx/\(self.transaction.id)"
      self.delegate?.transactionStatusPopUp(self, action: .openLink(url: urlString))
    }
  }

  @IBAction func firstButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      if self.transaction.state == .pending {
        self.delegate?.transactionStatusPopUp(self, action: .speedUp(tx: self.transaction.toTransaction()))
      } else if self.transaction.state == .completed {
        guard self.transaction.type != .earn else { return }
        self.delegate?.transactionStatusPopUp(self, action: .transfer)
      } else if self.transaction.state == .error || self.transaction.state == .failed {
        self.delegate?.transactionStatusPopUp(self, action: .dismiss)
      }
    }
  }

  @IBAction func secondButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      if self.transaction.state == .pending {
        self.delegate?.transactionStatusPopUp(self, action: .cancel(tx: self.transaction.toTransaction()))
      } else if self.transaction.state == .completed {
        if self.transaction.type == .earn {
          self.delegate?.transactionStatusPopUp(self, action: .backToInvest)
        } else {
          self.delegate?.transactionStatusPopUp(self, action: .swap)
        }
      } else if self.transaction.state == .error || self.transaction.state == .failed {
        self.delegate?.transactionStatusPopUp(self, action: .goToSupport)
      }
    }
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension KNTransactionStatusPopUp: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 292
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
