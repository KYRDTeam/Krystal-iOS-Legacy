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
  
  var customNonceValue: Int {
    return Int(customNonceString) ?? 0
  }
  let rate: Rate?

  init(gasLimit: BigInt, nonce: Int, rate: Rate?) {
    self.gasLimit = gasLimit
    self.nonce = nonce
    self.gasLimitString = gasLimit.description
    self.rate = rate
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    return (self.maxPriorityFeeString, self.maxFeeString, self.gasLimitString)
  }
  
  func resetData() {
    gasLimitString = gasLimit.description
    maxPriorityFeeString = ""
    maxFeeString = ""
    customNonceString = "\(nonce)"
  }
  
  var maxPriorityErrorStatus: AdvancedInputError {
    guard !maxPriorityFeeString.isEmpty else {
      return .empty
    }

    let lowerLimit = KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
    let maxPriorityBigInt = maxPriorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxPriorityBigInt < lowerLimit {
      return .low
    } else {
      return .none
    }
  }
  
  var maxFeeErrorStatus: AdvancedInputError {
    guard !maxFeeString.isEmpty else {
      return .empty
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? .zero
    let currentPriority = maxPriorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
    let standardFee = KNGasCoordinator.shared.standardKNGas ?? .zero
    
    let lowerLimit = baseFee + currentPriority
    let maxFee = maxFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxFee < lowerLimit {
      return .low
    } else if maxFee < standardFee {
      return .high //This is label for case fee < standard fee
    } else {
      return .none
    }
  }
  
  var advancedGasLimitErrorStatus: AdvancedInputError {
    guard !gasLimitString.isEmpty, let gasLimit = BigInt(gasLimitString) else {
      return .empty
    }
    let estGasUsed = self.rate?.estGasConsumed ?? Constants.lowLimitGas
    if gasLimit < BigInt(estGasUsed) {
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
    return (maxPriorityErrorStatus == .none || maxPriorityErrorStatus == .low) && (maxFeeErrorStatus == .none || maxFeeErrorStatus == .high) && advancedGasLimitErrorStatus == .none && advancedNonceErrorStatus == .none
  }

}

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
    if let est = KNGasCoordinator.shared.estTime?.standard {
      estTimeString = " ~ \(est)s"
    }
    self.baseFeeLabel.text = (KNGasCoordinator.shared.baseFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI"
    self.maxPriorityFeeRefLabel.text = "Standard " + (KNGasCoordinator.shared.defaultPriorityFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "") + " GWEI" + estTimeString
    self.maxFeeRefLabel.text = "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI" + estTimeString
    self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.rate?.estGasConsumed ?? Constants.lowLimitGas)"
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
      maxPriorityFeeErrorLabel.text = String(format: "priority.fee.low.warning".toBeLocalised(), KNGasCoordinator.shared.defaultPriorityFee?.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) ?? "")
      maxPriorityFeeErrorLabel.textColor = UIColor.Kyber.textWarningYellow
      maxPriorityFeeContainerView.rounded(color: UIColor.Kyber.textWarningYellow, width: 1, radius: 16)
    case .none, .empty:
      maxPriorityFeeErrorLabel.text = ""
      maxPriorityFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
    default:
      return
    }
    
    switch cellModel.maxFeeErrorStatus {
    case .low:
      maxFeeErrorLabel.text = "max.fee.low.warning".toBeLocalised()
      maxFeeErrorLabel.textColor = UIColor.Kyber.textRedColor
      maxFeeContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .high:
      maxFeeErrorLabel.text = String(format: "max.fee.high.warning".toBeLocalised(), KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2))
      maxFeeErrorLabel.textColor = UIColor.Kyber.textWarningYellow
      maxFeeContainerView.rounded(color: UIColor.Kyber.textWarningYellow, width: 1, radius: 16)
    case .none, .empty:
      maxFeeErrorLabel.text = ""
      maxFeeContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedGasLimitErrorStatus {
    case .low:
      gasLimitErrorLabel.text = "gas.limit.low.warning".toBeLocalised()
      gasLimitContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    default:
      gasLimitErrorLabel.text = ""
      gasLimitContainerView.rounded(color: .clear, width: 0, radius: 16)
    }
    
    switch cellModel.advancedNonceErrorStatus {
    case .low:
      nonceErrorLabel.text = "nonce.low.warning".toBeLocalised()
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
    let value = text.isEmpty ? 0 : StringFormatter().decimal(with: text)?.doubleValue
    
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
