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
  var customNonceString: String = ""
  
  var maxPriorityFeeChangedHandler: (String) -> Void = { _ in }
  var maxFeeChangedHandler: (String) -> Void = { _ in }
  var gasLimitChangedHandler: (String) -> Void = { _ in }
  var customNonceChangedHander: (String) -> Void = { _ in }
  var tapTitleWithIndex: (Int) -> Void = { _ in }
  
  var gasLimit: BigInt
  var nonce: Int {
    didSet {
      self.customNonceString = "\(self.nonce)"
    }
  }

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
  
  var maxPriorityErrorStatus: AdvancedInputError {
    guard !maxPriorityFeeString.isEmpty else {
      return .empty
    }

    let lowerLimit = KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
    let upperLimit = (KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)) * BigInt(2)
    let maxPriorityBigInt = maxPriorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxPriorityBigInt < lowerLimit {
      return .low
    } else if maxPriorityBigInt > (BigInt(2) * upperLimit) {
      return .high
    } else {
      return .none
    }
  }
  
  var maxFeeErrorStatus: AdvancedInputError {
    guard !maxFeeString.isEmpty else {
      return .empty
    }
    let lowerLimit = KNSelectedGasPriceType.slow.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let upperLimit = KNSelectedGasPriceType.superFast.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let maxFeeDouble = maxFeeString.doubleValue

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
    guard !customNonceString.isEmpty else {
      return .empty
    }

    let nonceInt = Int(customNonceString) ?? 0
    if nonceInt < 0 {
      return .low
    } else {
      return .none
    }
  }
  
  func hasNoError() -> Bool {
    return maxPriorityErrorStatus == .none && maxFeeErrorStatus == .none && advancedGasLimitErrorStatus == .none && advancedNonceErrorStatus == .none
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
    self.baseFeeLabel.text = (KNGasCoordinator.shared.baseFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI"
    self.maxPriorityFeeRefLabel.text = "Standard " + (KNGasCoordinator.shared.defaultPriorityFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI ~ 45s"
    self.maxFeeRefLabel.text = "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI ~ 45s"
    self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.gasLimit.description)"
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
      maxPriorityFeeErrorLabel.text = "Max Priority Fee is low for current network conditions"
      maxPriorityFeeContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .high:
      maxPriorityFeeErrorLabel.text = "Max Priority Fee is higher than necessary"
      maxPriorityFeeContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .none, .empty:
      maxPriorityFeeErrorLabel.text = ""
      maxPriorityFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.maxFeeErrorStatus {
    case .low:
      maxFeeErrorLabel.text = "Max Fee is low for current network conditions"
      maxFeeContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .high:
      maxFeeErrorLabel.text = "Max Fee is higher than necessary"
      maxFeeContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .none, .empty:
      maxFeeErrorLabel.text = ""
      maxFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedGasLimitErrorStatus {
    case .low:
      gasLimitErrorLabel.text = "Gas limit must be at least \(Constants.lowLimitGas)"
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
  
  @IBAction func titleLabelTapped(_ sender: UIButton) {
    cellModel.tapTitleWithIndex(sender.tag)
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
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    updateValidationUI()
  }
}
