//
//  SettingBasicAdvancedFormCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/08/2022.
//

import UIKit
import BigInt

class SettingBasicAdvancedFormCellModel {
  var gasPrice: BigInt
  var gasLimit: BigInt
  var selectedType: KNSelectedGasPriceType
  var nonce: Int
  
  var gasPriceChangedHandler: (String) -> Void = { _ in }
  var gasLimitChangedHandler: (String) -> Void = { _ in }
  var nonceChangedHandler: (String) -> Void = { _ in }
  
  var gasPriceString: String = "" {
    didSet {
      guard !gasPriceString.isEmpty else { return }
      self.gasPrice = gasPriceString.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
      self.selectedType = .custom
    }
  }
  var gasLimitString: String = "" {
    didSet {
      guard !gasLimitString.isEmpty else { return }
      self.gasLimit = BigInt(gasLimitString) ?? .zero
      self.selectedType = .custom
    }
  }
  var nonceString: String = "" {
    didSet {
      guard !nonceString.isEmpty else { return }
      self.nonce = Int(nonceString) ?? -1
    }
  }
  
  init(gasPrice: BigInt, gasLimit: BigInt, nonce: Int, selectedType: KNSelectedGasPriceType) {
    self.gasPrice = gasPrice
    self.gasLimit = gasLimit
    self.selectedType = selectedType
    self.nonce = nonce
  }
  
  var displayGasFee: String {
    return "Standard " + KNGasCoordinator.shared.standardKNGas.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2) + " GWEI ~ 45s"
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
    self.gasPriceTextField.text = cellModel.gasPrice.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2)
    self.gasLimitTextField.text = cellModel.gasLimit.description
    self.customNonceTextField.text = "\(cellModel.nonce)"
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
