//
//  BridgeTransactionStatusPopup.swift
//  KyberNetwork
//
//  Created by Com1 on 03/06/2022.
//

import UIKit
import BigInt
import SafariServices

class BridgeTransactionStatusPopup: KNBaseViewController {
  @IBOutlet weak var fromChainValue: UILabel!
  @IBOutlet weak var fromChainNameLabel: UILabel!
  @IBOutlet weak var fromChainIcon: UIImageView!
  @IBOutlet weak var fromTxHashLabel: UILabel!
  @IBOutlet weak var fromWalletLabel: UILabel!
  @IBOutlet weak var fromStatusView: UIView!
  @IBOutlet weak var fromStatusLabel: UILabel!
  @IBOutlet weak var fromStatusIcon: UIImageView!
  
  @IBOutlet weak var toChainIcon: UIImageView!
  @IBOutlet weak var toChainNameLabel: UILabel!
  @IBOutlet weak var toWalletLabel: UILabel!
  @IBOutlet weak var toTxHashLabel: UILabel!
  @IBOutlet weak var toChainValue: UILabel!
  @IBOutlet weak var toStatusView: UIView!
  @IBOutlet weak var toStatusLabel: UILabel!
  @IBOutlet weak var toStatusIcon: UIImageView!
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var tapOutsideView: UIView!
  @IBOutlet weak var feeLabel: UILabel!
  @IBOutlet weak var contentWidth: NSLayoutConstraint!
  
  @IBOutlet weak var fromValueWidth: NSLayoutConstraint!
  @IBOutlet weak var toValueWidth: NSLayoutConstraint!

  fileprivate(set) var transaction: InternalHistoryTransaction
  let transitor = TransitionDelegate()
  
  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
    super.init(nibName: BridgeTransactionStatusPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  func reloadData() {
    guard let from = transaction.extraData?.from, let to = transaction.extraData?.to else {
      return
    }
    let fromAmount = from.amount.shortString(decimals: from.decimals)
    fromChainNameLabel.text = from.chainName
    fromTxHashLabel.text = from.tx
    fromChainIcon.image = getChainIcon(chainID: from.chainId)
    let fromString = "- " + fromAmount + " " + from.token
    fromChainValue.text = fromString
    fromValueWidth.constant = fromString.width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    fromWalletLabel.text = "\(from.address.prefix(8))...\(from.address.suffix(4))"
    
    let fromStatus = TransactionStatus(status: from.txStatus)
    fromStatusIcon.image = icon(forStatus: fromStatus)
    fromStatusLabel.text = title(forStatus: fromStatus)
    fromStatusLabel.textColor = color(forStatus: fromStatus)
    fromStatusView.backgroundColor = color(forStatus: fromStatus)?.withAlphaComponent(0.2)
    
    let toAmount = to.amount.shortString(decimals: to.decimals)
    toChainNameLabel.text = to.chainName
    toTxHashLabel.text = to.tx
    toChainIcon.image = getChainIcon(chainID: to.chainId)
    let toString = "+ " + toAmount + " " + to.token
    toChainValue.text = toString
    toValueWidth.constant = toString.width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    toWalletLabel.text = "\(to.address.prefix(8))...\(to.address.suffix(4))"
    
    let toStatus = TransactionStatus(status: to.txStatus)
    toStatusIcon.image = icon(forStatus: toStatus)
    toStatusLabel.text = title(forStatus: toStatus)
    toStatusLabel.textColor = color(forStatus: toStatus)
    toStatusView.backgroundColor = color(forStatus: toStatus)?.withAlphaComponent(0.2)
    
    let quoteToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    feeLabel.text = transaction.gasFee.displayRate(decimals: quoteToken.decimals) + " " + quoteToken.symbol
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.tapOutsideView.addGestureRecognizer(tapGesture)
    self.reloadData()
    self.observeTxStatus()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    contentWidth.constant = UIScreen.main.bounds.width
  }
  
  deinit {
    removeObserver()
  }
  
  func removeObserver() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kBridgeExtraDataUpdateNotificationKey),
      object: nil
    )
  }
  
  func observeTxStatus() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onBridgeTxUpdate(_:)),
      name: Notification.Name(kBridgeExtraDataUpdateNotificationKey),
      object: nil
    )
  }
  
  @objc func onBridgeTxUpdate(_ notification: Notification) {
    if let extraData = notification.userInfo?["extraData"] as? InternalHistoryExtraData {
      guard let txHash = notification.userInfo?["txHash"] as? String, txHash == self.transaction.txHash else {
        return
      }
      self.transaction.acceptExtraData(extraData: extraData)
      self.reloadData()
      if extraData.isCompleted {
          MixPanelManager.track("bridge_done_pop_up_open", properties: ["screenid": "bridge_done_pop_up", "source_hash": extraData.from?.tx ?? ""])
      }
    }
  }

  @objc func tapOutside() {
    self.removeObserver()
    self.dismiss(animated: true, completion: nil)
  }
  
  func getChainIcon(chainID: String) -> UIImage? {
    return ChainType.getAllChain()
      .first { chain in
        chain.customRPC().chainID == Int(chainID)
      }?
      .chainIcon()
  }

  @IBAction func openFromTxHashTapped(_ sender: Any) {
    openTxUrl(chainID: transaction.extraData?.from?.chainId, txHash: transaction.extraData?.from?.tx)
  }


  @IBAction func copyFromWalletTapped(_ sender: Any) {
    UIPasteboard.general.string = transaction.extraData?.from?.address
    self.showMessageWithInterval(message: Strings.addressCopied)
  }


  @IBAction func openToTxHashTapped(_ sender: Any) {
    openTxUrl(chainID: transaction.extraData?.to?.chainId, txHash: transaction.extraData?.to?.tx)
  }
  
  
  @IBAction func copyToWalletTapped(_ sender: Any) {
    UIPasteboard.general.string = transaction.extraData?.to?.address
    self.showMessageWithInterval(message: Strings.addressCopied)
  }
  
  private func getChain(chainID: String?) -> ChainType? {
    guard let chainID = chainID else {
      return nil
    }

    return ChainType.getAllChain().first { chain in
      chain.customRPC().chainID == Int(chainID)
    }
  }
  
  func openTxUrl(chainID: String?, txHash: String?) {
    guard let endpoint = getChain(chainID: chainID)?.customRPC().etherScanEndpoint, let hash = txHash else {
      return
    }
    guard let url = URL(string: endpoint + "tx/" + hash) else {
      return
    }
    let vc = SFSafariViewController(url: url)
    present(vc, animated: true, completion: nil)
  }
  
  func color(forStatus status: TransactionStatus) -> UIColor? {
    switch status {
    case .success:
      return UIColor.Kyber.primaryGreenColor
    case .failure:
      return UIColor.Kyber.errorText
    case .pending:
      return UIColor.Kyber.pending
    default:
      return UIColor.Kyber.pending
    }
  }
  
  func icon(forStatus status: TransactionStatus) -> UIImage? {
    switch status {
    case .success:
      return Images.txSuccess
    case .failure:
      return Images.failure
    default:
      return Images.pendingTx
    }
  }
  
  func title(forStatus status: TransactionStatus) -> String? {
    switch status {
    case .success:
      return Strings.success
    case .failure:
      return Strings.failure
    case .pending:
      return Strings.pending
    case .other(let title):
      return title.capitalized
    }
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
