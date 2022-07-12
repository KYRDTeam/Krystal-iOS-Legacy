//
//  TransactionTypeInfoCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import UIKit

class TransactionTypeInfoCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var statusView: UIView!
  
  func configure(type: TransactionHistoryItemType, timestamp: Int, hideStatus: Bool = true) {
    iconImageView.image = icon(forType: type)
    typeLabel.text = title(forType: type)
    timeLabel.text = DateFormatterUtil.shared.MMMddYYYHHmma.string(from: .init(timeIntervalSince1970: TimeInterval(timestamp)))
    statusView.isHidden = hideStatus
  }
  
  func icon(forType type: TransactionHistoryItemType) -> UIImage? {
    switch type {
    case .receive:
      return Images.historyReceive
    case .transfer:
      return Images.historyTransfer
    case .approval:
      return Images.historyApprove
    case .contractInteraction:
      return Images.historyContractInteraction
    case .claimReward:
      return Images.historyClaimReward
    case .bridge:
      return Images.historyBridge
    case .multiSend, .multiReceive:
      return Images.historyMultisend
    default:
      return nil
    }
  }
  
  func title(forType type: TransactionHistoryItemType) -> String? {
    switch type {
    case .receive:
      return Strings.receive
    case .transfer:
      return Strings.transfer
    case .approval:
      return Strings.approval
    case .contractInteraction:
      return Strings.contractExecution
    case .claimReward:
      return Strings.claimReward
    case .bridge:
      return Strings.bridge
    case .multiSend:
      return Strings.multiSend
    case .multiReceive:
      return Strings.multiReceive
    default:
      return nil
    }
  }
  
}
