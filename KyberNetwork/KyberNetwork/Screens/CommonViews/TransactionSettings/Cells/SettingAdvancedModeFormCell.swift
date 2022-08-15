//
//  SettingAdvancedModeFormCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/08/2022.
//

import UIKit
import BigInt

class SettingAdvancedModeFormCellModel {
  var maxPriorityFeeString: String = ""
  var maxFeeString: String = ""
  var gasLimitString: String
  var customNonceString: String = "" {
    didSet {
      self.nonce = Int(self.customNonceString) ?? 0
    }
  }
  
  var maxPriorityFeeChangedHandler: (String) -> Void = { _ in }
  var maxFeeChangedHandler: (String) -> Void = { _ in }
  var gasLimitChangedHandler: (String) -> Void = { _ in }
  var customNonceChangedHander: (String) -> Void = { _ in }
  
  var gasLimit: BigInt
  var nonce: Int

  init(gasLimit: BigInt, nonce: Int) {
    self.gasLimit = gasLimit
    self.nonce = nonce
    self.gasLimitString = gasLimit.description
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    return (self.maxPriorityFeeString, self.maxFeeString, self.gasLimitString)
  }
  
  func resetData() {
    gasLimitString = gasLimit.description
    maxPriorityFeeString = ""
    maxFeeString = ""
  }
}

class SettingAdvancedModeFormCell: UITableViewCell {

  static let cellID: String = "SettingAdvancedModeFormCell"
  
  @IBOutlet weak var maxPriorityFeeTextField: UITextField!
  @IBOutlet weak var maxFeeTextField: UITextField!
  @IBOutlet weak var gasLimitTextField: UITextField!
  @IBOutlet weak var customNonceTextField: UITextField!
  @IBOutlet weak var baseFeeLabel: UILabel!
  
  @IBOutlet weak var maxPriorityFeeRefLabel: UILabel!
  @IBOutlet weak var maxFeeRefLabel: UILabel!
  var cellModel: SettingAdvancedModeFormCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.maxPriorityFeeTextField.delegate = self
    self.maxFeeTextField.delegate = self
    self.gasLimitTextField.delegate = self
    self.customNonceTextField.delegate = self
  }
  
  
  func updateUI() {
    self.baseFeeLabel.text = (KNGasCoordinator.shared.baseFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI"
    self.maxPriorityFeeRefLabel.text = "Standard " + (KNGasCoordinator.shared.defaultPriorityFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI ~ 45s"
    self.maxFeeRefLabel.text = "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI ~ 45s"
  }
  
  func fillFormUI() {
    self.maxPriorityFeeTextField.text = cellModel.maxPriorityFeeString
    
    self.maxFeeTextField.text = cellModel.maxFeeString
    
    self.gasLimitTextField.text = cellModel.gasLimitString
    self.customNonceTextField.text = "\(cellModel.nonce)"
  }
}

extension SettingAdvancedModeFormCell: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.replacingOccurrences(of: ",", with: ".")
    let value: Double? = number.isEmpty ? 0 : Double(number)
    
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
}
