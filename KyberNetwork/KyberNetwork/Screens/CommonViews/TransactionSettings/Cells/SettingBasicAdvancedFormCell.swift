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
  
  var tapTitleWithIndex: (Int) -> Void = { _ in }
  
  var gasPriceString: String = ""
  var gasLimitString: String = ""
  var nonceString: String = ""
  let rate: Rate?
  
  init(gasLimit: BigInt, nonce: Int, rate: Rate?) {
    self.rate = rate
    self.gasLimit = gasLimit
    self.nonce = nonce
    self.gasLimitString = gasLimit.description
  }
  
  var displayGasFee: String {
    var estTimeString = ""
    if let est = KNGasCoordinator.shared.estTime?.standard {
      estTimeString = " ~ \(est)s"
    }
    return "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI" + estTimeString
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
    let estGasUsed = self.rate?.estGasConsumed ?? Constants.lowLimitGas
    
    if gasLimit < BigInt(estGasUsed) {
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
    self.gasLimitRefLabel.text = "Est.gas consumed: \(cellModel.rate?.estGasConsumed ?? Constants.lowLimitGas)"
    updateValidationUI()
  }
  
  func updateValidationUI() {
    switch cellModel.gasPriceErrorStatus {
    case .low:
      gasPriceErrorLabel.text = "gas.price.low.warning".toBeLocalised()
      gasPriceContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .high:
      gasPriceErrorLabel.text = "gas.price.high.warning".toBeLocalised()
      gasPriceContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
    case .none, .empty:
      gasPriceErrorLabel.text = ""
      gasPriceContainerView.rounded(color: .clear, width: 0, radius: 16)
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
