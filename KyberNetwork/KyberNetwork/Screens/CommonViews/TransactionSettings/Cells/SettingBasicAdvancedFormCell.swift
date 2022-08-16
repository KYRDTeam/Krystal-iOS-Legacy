//
//  SettingBasicAdvancedFormCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/08/2022.
//

import UIKit
import BigInt

class SettingBasicAdvancedFormCellModel {
  var gasLimit: BigInt
  var nonce: Int {
    didSet {
      self.nonceString = "\(self.nonce)"
    }
  }
  
  var gasPriceChangedHandler: (String) -> Void = { _ in }
  var gasLimitChangedHandler: (String) -> Void = { _ in }
  var nonceChangedHandler: (String) -> Void = { _ in }
  
  var gasPriceString: String = ""
  var gasLimitString: String = ""
  var nonceString: String = ""
  
  init(gasLimit: BigInt, nonce: Int) {
    
    self.gasLimit = gasLimit
    self.nonce = nonce
    self.gasLimitString = gasLimit.description
  }
  
  var displayGasFee: String {
    return "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI ~ 45s"
  }
  
  func resetData() {
    gasPriceString = ""
    gasLimitString = gasLimit.description
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    return ("", gasPriceString, gasLimitString)
  }
}

class SettingBasicAdvancedFormCell: UITableViewCell {
  static let cellID: String = "SettingBasicAdvancedFormCell"
  
  @IBOutlet weak var gasPriceValueLabel: UILabel!
  @IBOutlet weak var gasPriceTextField: UITextField!
  @IBOutlet weak var gasLimitTextField: UITextField!
  @IBOutlet weak var customNonceTextField: UITextField!
  
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
  }
  
}

extension SettingBasicAdvancedFormCell: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.replacingOccurrences(of: ",", with: ".")
    let value: Double? = number.isEmpty ? 0 : Double(number)
    guard value != nil else { return false }
    if textField == self.gasPriceTextField {
      cellModel.gasPriceString = text
      cellModel.gasPriceChangedHandler(text)
      updateUI()
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
}
