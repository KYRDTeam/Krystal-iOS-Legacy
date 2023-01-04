//
//  SettingBasicAdvancedFormCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/08/2022.
//

import UIKit
import BigInt
import Services
import DesignSystem
import TransactionModule
import Dependencies
import Utilities


class SettingBasicAdvancedFormCell: UITableViewCell {
  @IBOutlet weak var gasPriceValueLabel: UILabel!
  @IBOutlet weak var gasPriceTextField: UITextField!
  @IBOutlet weak var gasLimitTextField: UITextField!
  @IBOutlet weak var customNonceTextField: UITextField!
  
  @IBOutlet weak var gasPriceErrorLabel: UILabel!
  @IBOutlet weak var gasLimitErrorLabel: UILabel!
  @IBOutlet weak var nonceErrorLabel: UILabel!
  @IBOutlet weak var gasLimitRefLabel: UILabel!
  
  @IBOutlet weak var gasPriceContainerView: UIView!
  @IBOutlet weak var gasLimitContainerView: UIView!
  @IBOutlet weak var nonceContainerView: UIView!
  
  var cellModel: SettingBasicAdvancedFormCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.gasPriceTextField.delegate = self
    self.gasLimitTextField.delegate = self
    self.customNonceTextField.delegate = self
  }
  func fillFormValues() {
    self.gasPriceTextField.text = cellModel.gasPriceString
    self.gasLimitTextField.text = cellModel.gasLimitString
    self.customNonceTextField.text = cellModel.nonceString
  }
  
  func updateUI() {
    self.gasPriceValueLabel.text = cellModel.displayGasFee
      self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.rate?.estGasConsumed ?? Int(TransactionConstants.lowestGasLimit))"
    updateValidationUI()
  }
  
  func updateValidationUI() {
    switch cellModel.gasPriceErrorStatus {
    case .low:
      gasPriceErrorLabel.text = "gas.price.low.warning".toBeLocalised()
        gasPriceContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
    case .high:
      gasPriceErrorLabel.text = "gas.price.high.warning".toBeLocalised()
      gasPriceContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
    case .none, .empty:
      gasPriceErrorLabel.text = ""
      gasPriceContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedGasLimitErrorStatus {
    case .low:
      gasLimitErrorLabel.text = "gas.limit.low.warning".toBeLocalised()
      gasLimitContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
    default:
      gasLimitErrorLabel.text = ""
      gasLimitContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedNonceErrorStatus {
    case .low:
      nonceErrorLabel.text = "nonce.low.warning".toBeLocalised()
      nonceContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
    default:
      nonceErrorLabel.text = ""
      nonceContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
  }
  
  
  @IBAction func titleLabelTapped(_ sender: UIButton) {
    cellModel.tapTitleWithIndex(sender.tag)
  }
}

extension SettingBasicAdvancedFormCell: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    var text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    text = text.replacingOccurrences(of: ",", with: ".")
    let value: Double? = text.isEmpty ? 0 : Double(text)
    guard value != nil else { return false }
    if textField == self.gasPriceTextField {
      cellModel.gasPriceString = text
      cellModel.gasPriceChangedHandler(text)
      updateUI()
      if string == "," {
        textField.text = text
        return false
      }
    } else if textField == self.gasLimitTextField {
      cellModel.gasLimitString = text
      cellModel.gasLimitChangedHandler(text)
      updateUI()
    } else if textField == self.customNonceTextField {
      cellModel.nonceString = text
      cellModel.nonceChangedHandler(text)
    }
    
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    updateValidationUI()
  }
}
