//
//  SettingAdvancedModeFormCell.swift
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



class SettingAdvancedModeFormCell: UITableViewCell {
  @IBOutlet weak var maxPriorityFeeTextField: UITextField!
  @IBOutlet weak var maxFeeTextField: UITextField!
  @IBOutlet weak var gasLimitTextField: UITextField!
  @IBOutlet weak var customNonceTextField: UITextField!
  @IBOutlet weak var baseFeeLabel: UILabel!
  
  @IBOutlet weak var maxPriorityFeeRefLabel: UILabel!
  @IBOutlet weak var maxFeeRefLabel: UILabel!
  
  @IBOutlet weak var maxPriorityFeeErrorLabel: UILabel!
  @IBOutlet weak var maxFeeErrorLabel: UILabel!
  
  @IBOutlet weak var gasLimitErrorLabel: UILabel!
  @IBOutlet weak var nonceErrorLabel: UILabel!
  
  @IBOutlet weak var gasLimitRefLabel: UILabel!
  
  @IBOutlet weak var maxPriorityFeeContainerView: UIView!
  @IBOutlet weak var maxFeeContainerView: UIView!
  @IBOutlet weak var gasLimitContainerView: UIView!
  @IBOutlet weak var nonceContainerView: UIView!
  
  var cellModel: SettingAdvancedModeFormCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.maxPriorityFeeTextField.delegate = self
    self.maxFeeTextField.delegate = self
    self.gasLimitTextField.delegate = self
    self.customNonceTextField.delegate = self
  }
  
  func updateUI() {
    var estTimeString = ""
      if let est = AppDependencies.gasConfig.currentChainStandardEstTime {
      estTimeString = " ~ \(est)s"
    }
      self.baseFeeLabel.text = NumberFormatUtils.gwei(value: AppDependencies.gasConfig.getCurrentChainBaseFee ?? .zero) + " GWEI"
      self.maxPriorityFeeRefLabel.text = "Standard " + NumberFormatUtils.gwei(value: AppDependencies.gasConfig.currentChainStandardPriorityFee ?? .zero) + estTimeString
    self.maxFeeRefLabel.text = "Standard " + NumberFormatUtils.gwei(value: AppDependencies.gasConfig.currentChainStandardGasPrice) + " GWEI" + estTimeString
    self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.rate?.estGasConsumed ?? Int(TransactionConstants.lowestGasLimit))"
    self.updateValidationUI()
  }
  
  func fillFormUI() {
    self.maxPriorityFeeTextField.text = cellModel.maxPriorityFeeString
    
    self.maxFeeTextField.text = cellModel.maxFeeString
    
    self.gasLimitTextField.text = cellModel.gasLimitString
    self.customNonceTextField.text = cellModel.customNonceString
  }
  
  func updateValidationUI() {
    switch cellModel.maxPriorityErrorStatus {
    case .low:
        maxPriorityFeeErrorLabel.text = String(format: "priority.fee.low.warning".toBeLocalised(), NumberFormatUtils.gwei(value: AppDependencies.gasConfig.currentChainStandardPriorityFee ?? .zero))
        maxPriorityFeeErrorLabel.textColor = AppTheme.current.warningTextColor
      maxPriorityFeeContainerView.rounded(color: AppTheme.current.warningTextColor, width: 1, radius: 16)
    case .none, .empty:
      maxPriorityFeeErrorLabel.text = ""
      maxPriorityFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
    default:
      return
    }
    
    switch cellModel.maxFeeErrorStatus {
    case .low:
      maxFeeErrorLabel.text = "max.fee.low.warning".toBeLocalised()
      maxFeeErrorLabel.textColor = AppTheme.current.errorTextColor
        maxFeeContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
    case .high:
        maxFeeErrorLabel.text = String(format: "max.fee.high.warning".toBeLocalised(), NumberFormatUtils.gwei(value: AppDependencies.gasConfig.currentChainStandardGasPrice))
        maxFeeErrorLabel.textColor = AppTheme.current.warningTextColor
        maxFeeContainerView.rounded(color: AppTheme.current.warningTextColor, width: 1, radius: 16)
    case .none, .empty:
      maxFeeErrorLabel.text = ""
      maxFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
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

extension SettingAdvancedModeFormCell: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
      let value = text.isEmpty ? 0 : text.toDouble()
    
    guard value != nil else { return false }
    
    if textField == self.maxPriorityFeeTextField {
      cellModel.maxPriorityFeeString = text
      cellModel.maxPriorityFeeChangedHandler(text)
    } else if textField == self.maxFeeTextField {
      cellModel.maxFeeString = text
      cellModel.maxFeeChangedHandler(text)
    } else if textField == self.gasLimitTextField {
      cellModel.gasLimitString = text
      cellModel.gasLimitChangedHandler(text)
    } else if textField == self.customNonceTextField {
      cellModel.customNonceString = text
      cellModel.customNonceChangedHander(text)
    }
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    updateValidationUI()
  }
}
