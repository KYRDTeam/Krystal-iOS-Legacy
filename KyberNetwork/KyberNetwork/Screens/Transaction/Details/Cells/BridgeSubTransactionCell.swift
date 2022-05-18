//
//  BridgeSubTransactionCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 18/05/2022.
//

import UIKit

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
  
  func configure(tx: ExtraBridgeTransaction) {
    let status = TransactionStatus(status: tx.txStatus) ?? .unknown
    resultIcon.image = icon(forStatus: status)
    resultLabel.text = title(forStatus: status)
    
  }
  
  func color(forStatus status: TransactionStatus) -> UIColor? {
    switch status {
    case .broadcasting:
      <#code#>
    case .broadcastingError:
      <#code#>
    case .pending:
      <#code#>
    case .failed:
      <#code#>
    case .success:
      <#code#>
    case .unknown:
      <#code#>
    }
  }
  
  func icon(forStatus status: TransactionStatus) -> UIImage? {
    switch status {
    case .success:
      return Images.success
    case .failure:
      return Images.failure
    default:
      return Images.pending
    }
  }
  
  func title(forStatus status: KNTransactionStatus) -> String? {
    switch status {
    case .success:
      return Strings.success
    case .failed:
      return Strings.failure
    case .pending:
      return Strings.pending
    case .unknown:
      return Strings.noTransactionFound
    }
  }
  
}
