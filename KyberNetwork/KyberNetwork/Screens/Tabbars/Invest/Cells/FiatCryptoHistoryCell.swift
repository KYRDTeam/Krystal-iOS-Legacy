//
//  FiatCryptoHistoryCell.swift
//  KyberNetwork
//
//  Created by Com1 on 13/03/2022.
//

import UIKit

class FiatCryptoHistoryCell: UICollectionViewCell {

  static let cellID: String = "kFiatCryptoHistoryCellID"
  static let height: CGFloat = 84.0

  @IBOutlet weak var cryptIcon: UIImageView!
  @IBOutlet weak var fiatIcon: UIImageView!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var networkIcon: UIImageView!
  @IBOutlet weak var statusButton: UIButton!
  var order: BifinityOrder?
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  func updateCell(order: BifinityOrder, indexPath: IndexPath) {
    self.order = order
    self.backgroundColor = indexPath.row % 2 == 0 ? UIColor(named: "innerContainerBgColor") : UIColor(named: "mainViewBgColor")
    self.statusButton.isHidden = !self.isFailOrder()
    self.cryptIcon.setImage(with: order.cryptoLogo, placeholder: UIImage(named: "default_token"))
    self.fiatIcon.setImage(with: order.fiatLogo, placeholder: UIImage(named: "default_token"))
    self.networkIcon.setImage(with: order.networkLogo, placeholder: UIImage(named: "default_token"))
    self.valueLabel.text = "\(order.orderAmount) \(order.fiatCurrency) -> \(order.orderAmount * order.executePrice) \(order.cryptoCurrency)"
    self.rateLabel.text = "1 \(order.cryptoCurrency) = \(order.executePrice) \(order.fiatCurrency)"
    self.addressLabel.text = order.cryptoAddress

    // createdTime get from api in milisecond
    let date = Date(timeIntervalSince1970: TimeInterval(order.createdTime/1000))
    self.timeLabel.text = DateFormatterUtil.shared.rewardDateTimeFormatter.string(from: date)
    
  }
  
  func didTapStatusButton() {
    guard let order = self.order, self.isFailOrder() else {
      return
    }

    showBottomBannerView(with: order.errorCode, message: order.errorReason, icon: UIImage(named: "help_icon_large") ?? UIImage(), time: 5 )
  }
  
  func isFailOrder() -> Bool {
    guard let order = self.order else {
      return true
    }
    
    return order.status == "failure"
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

      guard isUserInteractionEnabled else { return nil }

      guard !isHidden else { return nil }

      guard alpha >= 0.01 else { return nil }

      guard self.point(inside: point, with: event) else { return nil }

      // add one of these blocks for each button in our collection view cell we want to actually work
      if self.statusButton.point(inside: convert(point, to: statusButton), with: event) {
        self.didTapStatusButton()
          return self.statusButton
      }

      return super.hitTest(point, with: event)
  }

}
