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
  
  var gasPriceErrorStatus: AdvancedInputError {
    guard !gasPriceString.isEmpty else {
      return .empty
    }
    let lowerLimit = KNSelectedGasPriceType.slow.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let upperLimit = KNSelectedGasPriceType.superFast.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let maxFeeDouble = gasPriceString.doubleValue

    if maxFeeDouble < lowerLimit {
      return .low
    } else if maxFeeDouble > upperLimit {
      return .high
    } else {
      return .none
    }
  }
  
  var advancedGasLimitErrorStatus: AdvancedInputError {
    guard !gasLimitString.isEmpty, let gasLimit = BigInt(gasLimitString) else {
      return .empty
    }
    
    if gasLimit < BigInt(21000) {
      return .low
    } else {
      return .none
    }
  }
  
  var advancedNonceErrorStatus: AdvancedInputError {
    guard !nonceString.isEmpty else {
      return .empty
    }

    let nonceInt = Int(nonceString) ?? 0
    if nonceInt < 0 {
      return .low
    } else {
      return .none
    }
  }
  
  func hasNoError() -> Bool {
    return gasPriceErrorStatus == .none && advancedGasLimitErrorStatus == .none && advancedNonceErrorStatus == .none
  }
}

class SettingBasicAdvancedFormCell: UITableViewCell {
  static let cellID: String = "SettingBasicAdvancedFormCell"
  
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
    self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.gasLimit.description)"
    updateValidationUI()
  }
  
  func updateValidationUI() {
    switch cellModel.gasPriceErrorStatus {
    case .low:
      gasPriceErrorLabel.text = "Max Fee is low for current network conditions"
      gasPriceContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .high:
      gasPriceErrorLabel.text = "Max Fee is higher than necessary"
      gasPriceContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .none, .empty:
      gasPriceErrorLabel.text = ""
      gasPriceContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedGasLimitErrorStatus {
    case .low:
      gasLimitErrorLabel.text = "Gas limit must be at least 21000"
      gasLimitContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    default:
      gasLimitErrorLabel.text = ""
      gasLimitContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedNonceErrorStatus {
    case .low:
      nonceErrorLabel.text = "Nonce is too low"
      nonceContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    default:
      nonceErrorLabel.text = ""
      nonceContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
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
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    updateValidationUI()
  }
}
