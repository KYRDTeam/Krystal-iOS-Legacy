//
//  BridgeSubTransactionCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 18/05/2022.
//

import UIKit
import BigInt

protocol BridgeSubTransactionCellDelegate: AnyObject {
  func openTxDetail(cell: BridgeSubTransactionCell, hash: String, chainID: String)
  func copyTxAddress(cell: BridgeSubTransactionCell, address: String)
}

class BridgeSubTransactionCell: UITableViewCell {
  @IBOutlet weak var resultContainerView: UIView!
  @IBOutlet weak var resultIcon: UIImageView!
  @IBOutlet weak var resultLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var chainIconImageView: UIImageView!
  @IBOutlet weak var chainNameLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var addressTitle: UILabel!
  @IBOutlet weak var linkImageView: UIImageView!
  @IBOutlet weak var copyImageView: UIImageView!
  
  weak var delegate: BridgeSubTransactionCellDelegate?
  
  var tx: ExtraBridgeTransaction!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupActions()
  }
  
  func setupActions() {
    let txHashTap = UITapGestureRecognizer(target: self, action: #selector(onTapTxHash))
    linkImageView.isUserInteractionEnabled = true
    linkImageView.addGestureRecognizer(txHashTap)
    
    let addressTap = UITapGestureRecognizer(target: self, action: #selector(onTapCopyAddress))
    copyImageView.isUserInteractionEnabled = true
    copyImageView.addGestureRecognizer(addressTap)
  }
  
  func configure(isSourceTransaction: Bool, tx: ExtraBridgeTransaction) {
    self.tx = tx
    
    titleLabel.text = isSourceTransaction ? Strings.from : Strings.to

    let status = TransactionStatus(status: tx.txStatus)
    resultIcon.image = icon(forStatus: status)
    resultLabel.text = title(forStatus: status)
    resultContainerView.backgroundColor = color(forStatus: status)?.withAlphaComponent(0.2)
    resultLabel.textColor = color(forStatus: status)
    
    chainNameLabel.text = tx.chainName
    chainIconImageView.image = getChainIcon(chainID: tx.chainId)
    
    let amountString = tx.amount.fullString(decimals: tx.decimals)
    amountLabel.text = amountString + " " + tx.token
    txHashLabel.text = tx.tx
    addressLabel.text = tx.address
    addressTitle.text = isSourceTransaction ? Strings.from : Strings.receive
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
    case .other:
      return Strings.pending
    }
  }
  
  func getChainIcon(chainID: String?) -> UIImage? {
    guard let chainID = chainID else {
      return nil
    }
    return ChainType.getAllChain()
      .first { chain in
        chain.customRPC().chainID == Int(chainID)
      }?
      .chainIcon()
  }
  
  @objc func onTapTxHash() {
    delegate?.openTxDetail(cell: self, hash: tx.tx, chainID: tx.chainId)
  }
  
  @objc func onTapCopyAddress() {
    delegate?.copyTxAddress(cell: self, address: tx.address)
  }
  
}
