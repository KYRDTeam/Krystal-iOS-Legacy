//
//  TransactionSettingsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/08/2022.
//

import UIKit
import BigInt

typealias BasicSettingsInfo = (type: KNSelectedGasPriceType, value: BigInt)
typealias AdvancedSettingsInfo = (maxPriority: String, maxFee: String, gasLimit: String)

class TransactionSettingsViewModel {
  var isAdvancedMode = false
  var isExpertMode = false
  
  var gasLimit: BigInt
  var gasPrice: BigInt
  
  
  var selectedType: KNSelectedGasPriceType {
    didSet {
      self.basicAdvancedCellModel.selectedType = self.selectedType
      self.advancedModeCellModel.selectedType = self.selectedType
    }
  }
  var nonce: Int = -1 {
    didSet {
      self.basicAdvancedCellModel.nonce = self.nonce
      self.advancedModeCellModel.nonce = self.nonce
      self.customNonceChangedHandler(self.nonce)
    }
  }
  
  let slippageCellModel = SlippageRateCellModel(currentRatePercentage: 0.5)
  let segmentedCellModel = SettingSegmentedCellModel()
  let switchExpertMode = SettingExpertModeSwitchCellModel()
  let basicModeCellModel = SettingBasicModeCellModel()
  let basicAdvancedCellModel: SettingBasicAdvancedFormCellModel
  let advancedModeCellModel: SettingAdvancedModeFormCellModel
  
  var switchExpertModeEventHandler: (Bool) -> Void = { _ in }
  var switchAdvancedModeEventHandle: (Bool) -> Void = { _ in }
  var customNonceChangedHandler: (Int) -> Void = { _ in }
  var slippageChangedEventHandler: (Double) -> Void = { _ in }
  
  init(gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium) {
    self.gasPrice = selectType.getGasValue()
    self.gasLimit = gasLimit
    self.selectedType = selectType
    self.basicModeCellModel.gasLimit = gasLimit
    self.slippageCellModel.slippageChangedEvent = { value in
      print("[Setting][SlippageChanged] \(value)")
    }
    self.basicAdvancedCellModel = SettingBasicAdvancedFormCellModel(gasPrice: gasPrice, gasLimit: gasLimit, nonce: -1, selectedType: selectType)
    self.advancedModeCellModel = SettingAdvancedModeFormCellModel(gasLimit: gasLimit, nonce: -1, selectedType: selectType)
    
    self.segmentedCellModel.valueChangeHandler = { value in
      self.isAdvancedMode = value == 1
      self.switchAdvancedModeEventHandle(self.isAdvancedMode)
    }
    self.switchExpertMode.switchValueChangedHandle = { value in
      self.isExpertMode = value
      self.switchExpertModeEventHandler(value)
    }

    self.basicModeCellModel.actionHandler = { value in
      switch value {
      case 3:
        self.selectedType = .fast
      case 2:
        self.selectedType = .medium
      case 1:
        self.selectedType = .slow
      default:
        break
      }
      self.gasPrice = self.selectedType.getGasValue()
     
      let valueString = self.selectedType.getGasValueString()
      self.basicAdvancedCellModel.gasPriceString = valueString
      self.advancedModeCellModel.maxFeeString = valueString
    }
    
    self.basicAdvancedCellModel.gasPriceChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      self.advancedModeCellModel.maxFeeString = value
      self.selectedType = .custom
    }
    
    self.basicAdvancedCellModel.gasLimitChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      self.advancedModeCellModel.gasLimitString = value
      self.selectedType = .custom
    }
    
    self.basicAdvancedCellModel.nonceChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      let nonceValue = Int(value) ?? 0
      self.nonce = nonceValue
      self.selectedType = .custom
    }
    
    self.advancedModeCellModel.maxPriorityFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.selectedType = .custom
    }
    
    self.advancedModeCellModel.maxFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.basicAdvancedCellModel.gasPriceString = value
      self.selectedType = .custom
    }
    
    self.advancedModeCellModel.gasLimitChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.basicAdvancedCellModel.gasLimitString = value
      self.selectedType = .custom
    }
    
    self.advancedModeCellModel.customNonceChangedHander = { value in
      print("[Setting][Advanced] \(value)")
      let nonceValue = Int(value) ?? 0
      self.nonce = nonceValue
      self.selectedType = .custom
    }
    
    self.slippageCellModel.slippageChangedEvent = { value in
      self.slippageChangedEventHandler(value)
    }
    
  }
  
  func getBasicSettingInfo() -> BasicSettingsInfo {
    return (type: self.selectedType, value: self.selectedType.getGasValue())
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    return self.advancedModeCellModel.getAdvancedSettingInfo()
  }
}

class TransactionSettingsViewController: KNBaseViewController {
  @IBOutlet weak var settingsTableView: UITableView!
  
  let viewModel: TransactionSettingsViewModel
  weak var delegate: GasFeeSelectorPopupViewControllerDelegate?
  
  init(viewModel: TransactionSettingsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: TransactionSettingsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.settingsTableView.registerCellNib(SlippageRateCell.self)
    self.settingsTableView.registerCellNib(SettingSegmentedCell.self)
    self.settingsTableView.registerCellNib(SettingBasicModeCell.self)
    self.settingsTableView.registerCellNib(SettingExpertModeSwitchCell.self)
    self.settingsTableView.registerCellNib(SettingAdvancedModeFormCell.self)
    self.settingsTableView.registerCellNib(SettingBasicAdvancedFormCell.self)
    
    self.viewModel.switchExpertModeEventHandler = { value in
      self.settingsTableView.reloadData()
    }
    
    self.viewModel.switchAdvancedModeEventHandle = { value in
      self.settingsTableView.reloadData()
    }
    
    self.viewModel.slippageChangedEventHandler = { value in
      self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: CGFloat(value)))
    }
  }
  
  @IBAction func backBtnTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func resetButtonTapped(_ sender: UIButton) {
    
  }
  
  @IBAction func saveButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: {
      let basicInfo = self.viewModel.getBasicSettingInfo()
      let advancedInfo = self.viewModel.getAdvancedSettingInfo()
      if KNGeneralProvider.shared.isUseEIP1559 {
        if self.viewModel.selectedType == .custom {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: advancedInfo.gasLimit, maxPriorityFee: advancedInfo.maxPriority, maxFee: advancedInfo.maxFee))
        } else {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: basicInfo.type, value: basicInfo.value))
        }
      } else {
        if self.viewModel.selectedType == .custom {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: advancedInfo.gasLimit, maxPriorityFee: "", maxFee: advancedInfo.maxFee))
        } else {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: basicInfo.type, value: basicInfo.value))
        }
      }
    })
  }
  
  func coordinatorDidUpdateCurrentNonce(_ nonce: Int) {
    viewModel.nonce = nonce
    
  }
}

extension TransactionSettingsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.row {
    case 0:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: SlippageRateCell.cellID,
        for: indexPath
      ) as! SlippageRateCell
      cell.cellModel = viewModel.slippageCellModel
      cell.configSlippageUI()
      return cell
    case 1:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: SettingSegmentedCell.cellID,
        for: indexPath
      ) as! SettingSegmentedCell
      cell.cellModel = viewModel.segmentedCellModel
      return cell
    case 2:
      if self.viewModel.isExpertMode {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: SettingAdvancedModeFormCell.cellID,
          for: indexPath
        ) as! SettingAdvancedModeFormCell
        cell.cellModel = viewModel.advancedModeCellModel
        cell.fillFormUI()
        cell.updateUI()
        return cell
      } else {
        if self.viewModel.isAdvancedMode {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingBasicAdvancedFormCell.cellID,
            for: indexPath
          ) as! SettingBasicAdvancedFormCell
          cell.cellModel = viewModel.basicAdvancedCellModel
          cell.fillFormValues()
          cell.updateUI()
          return cell
        } else {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingBasicModeCell.cellID,
            for: indexPath
          ) as! SettingBasicModeCell
          cell.cellModel = viewModel.basicModeCellModel
          cell.updateUI()
          return cell
        }
      }
    case 3:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: SettingExpertModeSwitchCell.cellID,
        for: indexPath
      ) as! SettingExpertModeSwitchCell
      cell.cellModel = self.viewModel.switchExpertMode
      cell.updateUI()
     
      return cell
    default:
      break
    }
    return UITableViewCell()
  }
}
