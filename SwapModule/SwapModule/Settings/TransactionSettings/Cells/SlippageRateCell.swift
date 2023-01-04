//
//  SlippageRateCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit
import Utilities
import DesignSystem

enum KAdvancedSettingsMinRateType {
  case zeroPointOne
  case zeroPointFive
  case onePercent
  case anyRate
  case custom(value: Double)
}

class SlippageRateCellModel {
  let defaultSlippageText = "0.5"
  let defaultSlippageInputValue = 0.5
  var currentRate: Double
  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .zeroPointFive
  var slippageChangedEvent: (Double) -> Void = { _ in }

  init() {
    let savedValue = UserDefaults.standard.double(forKey: Constants.slippageRateSaveKey)
    self.currentRate = savedValue > 0 ? savedValue : 0.5
    switch currentRate {
    case 0.1:
      self.minRateType = .zeroPointOne
    case 0.5:
      self.minRateType = .zeroPointFive
    case 1.0:
      self.minRateType = .onePercent
    default:
      self.minRateType = .custom(value: currentRate)
    }
  }
  
  func updateCurrentMinRate(_ value: Double) {
    self.currentRate = value
  }
  
  func updateMinRateType(_ type: KAdvancedSettingsMinRateType) {
    self.minRateType = type
    switch type {
    case .zeroPointOne:
      self.currentRate = 0.1
    case .zeroPointFive:
      self.currentRate = 0.5
    case .onePercent:
      self.currentRate = 1
    default:
      break
    }
  }
  
  var minRatePercent: Double {
    switch self.minRateType {
    case .zeroPointOne: return 0.1
    case .zeroPointFive: return 0.5
    case .onePercent: return 1.0
    case .anyRate: return 100.0
    case .custom(let value): return value
    }
  }
  
  func resetData() {
    minRateType = .zeroPointFive
    currentRate = 0.5
  }
  
  func hasNoError() -> Bool {
    return currentRate >= 0 && currentRate <= 50.0
  }
}

class SlippageRateCell: UITableViewCell {
  
  @IBOutlet weak var firstOptionSlippageButton: UIButton!
  @IBOutlet weak var secondOptionSippageButton: UIButton!
  @IBOutlet weak var thirdOptionSlippageButton: UIButton!
  @IBOutlet weak var warningSlippageLabel: UILabel!
  @IBOutlet weak var advancedCustomRateTextField: UITextField!
  
  var cellModel: SlippageRateCellModel!
  
  
  static let cellHeight: CGFloat = 60
  
  override func awakeFromNib() {
    super.awakeFromNib()

    setupButtonTitles()
    self.advancedCustomRateTextField.delegate = self
      self.advancedCustomRateTextField.setPlaceholder(text: Strings.custom, color: AppTheme.current.navigationButtonBackgroundColor)
  }
  
  func setupButtonTitles() {
    firstOptionSlippageButton.setTitle(NumberFormatUtils.percent(value: 0.1), for: .normal)
    secondOptionSippageButton.setTitle(NumberFormatUtils.percent(value: 0.5), for: .normal)
    thirdOptionSlippageButton.setTitle(NumberFormatUtils.percent(value: 1), for: .normal)
  }
  
  func updateFocusForView(view: UIView, isFocus: Bool) {
    if view == advancedCustomRateTextField, isFocus {
      if cellModel.hasNoError() {
        view.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1.0, radius: 14.0)
        view.backgroundColor = UIColor(named: "innerContainerBgColor")!
      } else {
        view.rounded(color: UIColor(named: "textRedColor")!, width: 1.0, radius: 14.0)
        view.backgroundColor = UIColor(named: "innerContainerBgColor")!
      }
      return
    }
    if isFocus {
        view.rounded(color: AppTheme.current.primaryColor, width: 1.0, radius: 14.0)
      view.backgroundColor = UIColor(named: "innerContainerBgColor")!
    } else {
        view.rounded(color: AppTheme.current.navigationButtonBackgroundColor, width: 1.0, radius: 14.0)
      view.backgroundColor = .clear
    }
    
    
  }
    
  func configSlippageUIByType(_ type: KAdvancedSettingsMinRateType) {
    self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: false)
    
    switch type {
    case .zeroPointOne:
      self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: true)
    case .zeroPointFive:
      self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: true)
    case .onePercent:
      self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: true)
    default:
      self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: true)
    }
    self.updateSlippageHintLabel()
  }
  
  func configSlippageUI() {
    
    self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: false)

    switch self.cellModel.minRatePercent {
    case 0.1:
      self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: true)
    case 0.5:
      self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: true)
    case 1.0:
      self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: true)
    default:
      self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: true)
      advancedCustomRateTextField.text = NumberFormatUtils.percent(value: cellModel.currentRate)
    }
    self.updateSlippageHintLabel()
  }
  
  func updateSlippageHintLabel() {
    var warningText = ""
    var warningColor = UIColor(named: "warningColor")!
    if self.cellModel.minRatePercent <= 0.1 {
      warningText = "Your transaction may fail".toBeLocalised()
    } else if self.cellModel.minRatePercent > 50.0 {
      warningText = "Enter a valid slippage percentage".toBeLocalised()
      warningColor = UIColor(named: "textRedColor")!
    } else if self.cellModel.minRatePercent >= 10 {
      warningText = "Your transaction may be frontrun".toBeLocalised()
    }
    self.warningSlippageLabel.text = warningText
    self.warningSlippageLabel.textColor = warningColor
  }
  
  @IBAction func customRateButtonTapped(_ sender: UIButton) {
    var minRateType = KAdvancedSettingsMinRateType.custom(value: self.cellModel.currentRate)
    switch sender.tag {
    case 0:
      minRateType = KAdvancedSettingsMinRateType.zeroPointOne
    case 1:
      minRateType = KAdvancedSettingsMinRateType.zeroPointFive
    default:
      minRateType = KAdvancedSettingsMinRateType.onePercent
    }
    self.cellModel.updateMinRateType(minRateType)
    self.cellModel.slippageChangedEvent(self.cellModel.minRatePercent)
    self.configSlippageUI()
    self.advancedCustomRateTextField.text = ""
    self.advancedCustomRateTextField.setPlaceholder(text: "Custom", color: UIColor(named: "navButtonBgColor")!)
  }
}

extension SlippageRateCell: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    
    if let text = textField.text {
      textField.text = text.replacingOccurrences(of: "%", with: "")
    }
      textField.setPlaceholder(text: "\(self.cellModel.minRatePercent)", color: AppTheme.current.navigationButtonBackgroundColor)
    self.cellModel.updateMinRateType(.custom(value: self.cellModel.currentRate))
    self.configSlippageUIByType(.custom(value: self.cellModel.currentRate))

    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    var text = textField.text ?? self.cellModel.defaultSlippageText
    if text.isEmpty {
      text = self.cellModel.defaultSlippageText
    }
    let shouldFocus = !text.isEmpty
    self.updateFocusForView(view: textField, isFocus: shouldFocus)
    
    let val = text.doubleValue
    self.cellModel.updateCurrentMinRate(val)
    self.cellModel.updateMinRateType(.custom(value: val))
    self.configSlippageUIByType(.custom(value: val))
    textField.text = text + "%"
    updateSlippageHintLabel()
    self.cellModel.slippageChangedEvent(val)
    
  }
}
