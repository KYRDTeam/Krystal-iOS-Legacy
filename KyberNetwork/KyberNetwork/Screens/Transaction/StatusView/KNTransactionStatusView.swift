// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNTransactionStatus: String {
  case broadcasting = "Broadcasting"
  case broadcastingError = "Error"
  case pending = "Pending"
  case failed = "Failed"
  case success = "Success"
  case unknown = "Unknown"

  var statusDetails: String {
    switch self {
    case .broadcasting:
      return Strings.transactionBroadcasted
    case .broadcastingError:
      return Strings.cannotCreateTransaction
    case .pending:
      return Strings.transactionBeingMined
    case .failed:
      return Strings.transactionFailed
    case .success:
      return Strings.transactionSuccess
    default:
      return Strings.noTransactionFound
    }
  }

  var imageName: String {
    switch self {
    case .broadcasting, .pending: return "loading_icon"
    case .failed, .broadcastingError: return "fail"
    case .success: return "success"
    default: return ""
    }
  }
}

protocol KNTransactionStatusViewDelegate: class {
  func transactionStatusDidPressClose()
  func transactionStatusDidPressView()
}

class KNTransactionStatusView: XibLoaderView {

  fileprivate var txHash: String?
  fileprivate var isAnimating: Bool = false

  @IBOutlet weak var loadingContainerView: UIView!
  @IBOutlet weak var loadingImageView: UIImageView!
  @IBOutlet weak var txStatusLabel: UILabel!
  @IBOutlet weak var txStatusDetailsLabel: UILabel!

  weak var delegate: KNTransactionStatusViewDelegate?
  fileprivate var status: KNTransactionStatus = .unknown

  override var isHidden: Bool {
    didSet {
      self.txHash = nil
    }
  }

  override func commonInit() {
    super.commonInit()
    self.loadingImageView.tintColor = .white
    self.loadingImageView.image = self.loadingImageView.image?.withRenderingMode(.alwaysTemplate)
    self.txStatusLabel.text = ""
    self.txStatusDetailsLabel.text = ""
    self.isUserInteractionEnabled = true
    let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.viewDidSwipeDown(_:)))
    swipeDownGesture.direction = .down
    self.addGestureRecognizer(swipeDownGesture)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDidTap(_:)))
    self.addGestureRecognizer(tapGesture)
  }

  func updateView(with status: KNTransactionStatus, txHash: String?, details: String? = nil) {
    self.status = status
    self.txHash = txHash
    self.txStatusLabel.text = status.rawValue
    self.txStatusDetailsLabel.text = details ?? status.statusDetails
    self.loadingImageView.image = UIImage(named: status.imageName)?.withRenderingMode(.alwaysTemplate)
    if status == .broadcasting || status == .pending {
      self.isAnimating = true
      self.loadingImageView.startRotating()
    } else {
      self.isAnimating = false
      self.loadingImageView.stopRotating()
    }
    if status == .broadcastingError || status == .success || status == .failed {
      KNNotificationUtil.localPushNotification(
        title: status.rawValue,
        body: details ?? status.statusDetails,
        userInfo: ["transaction_hash": txHash ?? ""]
      )
    }
    self.layoutIfNeeded()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.transactionStatusDidPressClose()
  }

  @objc func viewDidSwipeDown(_ sender: Any) {
    self.delegate?.transactionStatusDidPressClose()
  }

  @objc func viewDidTap(_ sender: Any) {
    self.delegate?.transactionStatusDidPressView()
  }

  func updateViewWillAppear() {
    if self.isAnimating {
      self.loadingImageView.startRotating()
    } else {
      self.loadingImageView.stopRotating()
    }
  }
}
