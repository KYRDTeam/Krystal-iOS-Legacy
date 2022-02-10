//
//  MultiSendCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import UIKit
import SwipeCellKit
import TrustCore

enum MultiSendCellEvent {
  case add
  case searchToken(selectedToken: Token, cellIndex: Int)
}

protocol MultiSendCellDelegate: class {
  func multiSendCell(_ cell: MultiSendCell, run event: MultiSendCellEvent)
}

class MultiSendCellModel {
  var index: Int = 0
  var addButtonEnable: Bool = true
  var amount: String = ""
  var addressString: String = ""
  var address: Address?
  var from: Token = KNGeneralProvider.shared.quoteTokenObject.toToken()
  
  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
  }
  
  func updateAddress(_ address: String) {
    self.addressString = address
    self.address = Address(string: address)
  }
  
  var amountTextColor: UIColor {
    return .white
  }
}

class MultiSendCell: SwipeTableViewCell {
  @IBOutlet weak var currentTokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var separatorView: UIView!
  weak var cellDelegate: MultiSendCellDelegate?

  static let cellHeight: CGFloat = 184
  static let cellID: String = "MultiSendCell"
  
  var cellModel: MultiSendCellModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.amountTextField.delegate = self
    self.addressTextField.delegate = self
    self.separatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }
  
  func updateCellModel(_ model: MultiSendCellModel) {
    if model.addButtonEnable {
      self.addButton.setImage(UIImage(named: "add_send_active_icon"), for: .normal)
    } else {
      self.addButton.setImage(UIImage(named: "add_send_inactive_icon"), for: .normal)
    }
    self.addressTextField.text = model.addressString
    self.amountTextField.text = model.amount
    self.currentTokenButton.setTitle(model.from.symbol, for: .normal)
    self.cellModel = model
  }
  
  @IBAction func addButtonTapped(_ sender: UIButton) {
    guard self.cellModel?.addButtonEnable == true else { return }
    self.cellDelegate?.multiSendCell(self, run: .add)
  }
  
  @IBAction func tokenButtonTapped(_ sender: UIButton) {
    self.cellDelegate?.multiSendCell(self, run: .searchToken(selectedToken: self.cellModel?.from ?? KNGeneralProvider.shared.quoteTokenObject.toToken(), cellIndex: self.cellModel?.index ?? 0))
  }
  
}

extension MultiSendCell: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.cellModel?.updateAmount("")
    } else {
      self.cellModel?.updateAddress("")
    }
    
    return false
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

    let cleanedText = text.cleanStringToNumber()
    if textField == self.amountTextField, cleanedText.amountBigInt(decimals: 18) == nil { return false } //TODO: fix 18
    if textField == self.amountTextField {
      textField.text = cleanedText
      self.cellModel?.updateAmount(cleanedText)
    } else {
      textField.text = text
      self.cellModel?.updateAddress(text)
    }
    
    return false
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.amountTextField.textColor = UIColor.white
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.cellModel?.amountTextColor
  }
}
