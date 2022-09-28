// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNSearchTokenTableViewCellDelegate: class {
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didSelect token: TokenObject)
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didAdd token: TokenObject)
}

class KNSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var tickIcon: UIImageView!
  
  weak var delegate: KNSearchTokenTableViewCellDelegate?
  var token: TokenObject?
  
  var tagImage: UIImage? {
    guard let tag = self.token?.tag else { return nil }
      if tag == VERIFIED_TAG {
        return UIImage(named: "blueTick_icon")
      } else if tag == PROMOTION_TAG {
        return UIImage(named: "green-checked-tag-icon")
      } else if tag == SCAM_TAG {
        return UIImage(named: "warning-tag-icon")
      } else if tag == UNVERIFIED_TAG {
        return nil
      }
      return nil
    }
    

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenSymbolLabel.text = ""
    self.addButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.addButton.frame.size.height / 2)
  }

  func updateCell(with token: TokenObject, isExistToken: Bool) {
    self.token = token
    if token.isCustom {
        //If token is a custom one, don't use the icon of supported token (use the default token icon) to prevent scam/trash token
        self.iconImageView.image = UIImage(named: "default_token")!
    } else {
        self.iconImageView.setSymbolImage(symbol: token.symbol, size: iconImageView.frame.size)
    }
    self.tokenSymbolLabel.text = "\(token.symbol.prefix(8))"
    self.tickIcon.isHidden = true
    if let image = self.tagImage {
      self.tickIcon.isHidden = false
      self.tickIcon.image = image
    }

    self.balanceLabel.text = NumberFormatUtils.balanceFormat(value: token.getBalanceBigInt(), decimals: token.decimals)
    self.balanceLabel.addLetterSpacing()
    self.balanceLabel.isHidden = !isExistToken
    self.addButton.isHidden = isExistToken
    self.layoutIfNeeded()
  }
  
  @IBAction func tapCell(_ sender: UIButton) {
    if let notNilToken = self.token {
      self.delegate?.searchTokenTableCell(self, didSelect: notNilToken)
    }
  }
  
  @IBAction func tapAddButton(_ sender: UIButton) {
    if let notNilToken = self.token {
      self.delegate?.searchTokenTableCell(self, didAdd: notNilToken)
    }
  }
  
}
