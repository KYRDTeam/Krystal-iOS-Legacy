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
  var isExpertMode = false {
    didSet {
      self.expertModeSwitchChangeStatusHandler(self.isExpertMode)
    }
  }
  
  var gasLimit: BigInt
  var gasPrice: BigInt

  var basicSelectedType: KNSelectedGasPriceType

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
  var expertModeSwitchChangeStatusHandler: (Bool) -> Void = { _ in }
  
  init(gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium) {
    self.gasPrice = selectType.getGasValue()
    self.gasLimit = gasLimit
    self.basicSelectedType = selectType
    self.basicModeCellModel.gasLimit = gasLimit
    self.slippageCellModel.slippageChangedEvent = { value in
      print("[Setting][SlippageChanged] \(value)")
    }
    self.basicAdvancedCellModel = SettingBasicAdvancedFormCellModel(gasLimit: gasLimit, nonce: -1)
    self.advancedModeCellModel = SettingAdvancedModeFormCellModel(gasLimit: gasLimit, nonce: -1)
    
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
        self.basicSelectedType = .fast
      case 2:
        self.basicSelectedType = .medium
      case 1:
        self.basicSelectedType = .slow
      default:
        break
      }
      self.gasPrice = self.basicSelectedType.getGasValue()
    }
    
    self.basicAdvancedCellModel.gasPriceChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
    }
    
    self.basicAdvancedCellModel.gasLimitChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
    }
    
    self.basicAdvancedCellModel.nonceChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      let nonceValue = Int(value) ?? 0
      self.nonce = nonceValue
    }
    
    self.advancedModeCellModel.maxPriorityFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
    }
    
    self.advancedModeCellModel.maxFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
    }
    
    self.advancedModeCellModel.gasLimitChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
    }
    
    self.advancedModeCellModel.customNonceChangedHander = { value in
      print("[Setting][Advanced] \(value)")
      let nonceValue = Int(value) ?? 0
      self.nonce = nonceValue
    }
    
    self.slippageCellModel.slippageChangedEvent = { value in
      self.slippageChangedEventHandler(value)
    }
    
  }
  
  func getBasicSettingInfo() -> BasicSettingsInfo {
    return (type: self.basicSelectedType, value: self.basicSelectedType.getGasValue())
  }
  
  func getAdvancedSettingInfo() -> AdvancedSettingsInfo {
    if KNGeneralProvider.shared.isUseEIP1559 {
      return self.advancedModeCellModel.getAdvancedSettingInfo()
    } else {
      return basicAdvancedCellModel.getAdvancedSettingInfo()
    }
    
  }
  
  func resetData() {
    slippageCellModel.resetData()
    basicModeCellModel.resetData()
    basicAdvancedCellModel.resetData()
    advancedModeCellModel.resetData()
    segmentedCellModel.resetData()
    switchExpertMode.resetData()
  }
  
  func update(priorityFee: String?, maxGas: String?, gasLimit: String?, nonceString: String?) {
    if let notNil = priorityFee {
      advancedModeCellModel.maxPriorityFeeString = notNil
    }
    
    if let notNil = maxGas {
      basicAdvancedCellModel.gasPriceString = notNil
      advancedModeCellModel.maxFeeString = notNil
    }
    
    if let notNil = gasLimit {
      advancedModeCellModel.gasLimitString = notNil
      basicAdvancedCellModel.gasLimitString = notNil
    }
    
    if let notNil = nonceString, let nonceInt = Int(notNil) {
      nonce = nonceInt
    }
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
    
    self.viewModel.expertModeSwitchChangeStatusHandler = { value in
      self.delegate?.gasFeeSelectorPopupViewController(self, run: .expertModeEnable(status: value))
      guard value == true else {

        self.reloadUI()
        return
      }
      let warningPopup = ExpertModeWarningViewController()
      warningPopup.confirmAction = { confirmed in
        if confirmed {
          warningPopup.dismiss(animated: true)
        } else {
          self.viewModel.isExpertMode = false
          self.viewModel.switchExpertMode.isOn = false
          self.reloadUI()
        }
        
      }
      self.present(warningPopup, animated: true, completion: nil)
    }
  }
  
  private func reloadUI() {
    DispatchQueue.main.async {
      self.settingsTableView.reloadData()
    }
  }
  
  @IBAction func backBtnTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func resetButtonTapped(_ sender: UIButton) {
    viewModel.resetData()
    viewModel.isAdvancedMode = false
    viewModel.isExpertMode = false
    settingsTableView.reloadData()
  }
  
  @IBAction func saveButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: {
      let basicInfo = self.viewModel.getBasicSettingInfo()
      let advancedInfo = self.viewModel.getAdvancedSettingInfo()
      if KNGeneralProvider.shared.isUseEIP1559 {
        if self.viewModel.isAdvancedMode {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: advancedInfo.gasLimit, maxPriorityFee: advancedInfo.maxPriority, maxFee: advancedInfo.maxFee))
        } else {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: basicInfo.type, value: basicInfo.value))
        }
      } else {
        if self.viewModel.isAdvancedMode {
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
      cell.updateUI()
      return cell
    case 2:
      if self.viewModel.isAdvancedMode {
        if KNGeneralProvider.shared.isUseEIP1559 {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingAdvancedModeFormCell.cellID,
            for: indexPath
          ) as! SettingAdvancedModeFormCell
          cell.cellModel = viewModel.advancedModeCellModel
          cell.fillFormUI()
          cell.updateUI()
          return cell
        } else {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingBasicAdvancedFormCell.cellID,
            for: indexPath
          ) as! SettingBasicAdvancedFormCell
          cell.cellModel = viewModel.basicAdvancedCellModel
          cell.fillFormValues()
          cell.updateUI()
          return cell
        }
      } else {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: SettingBasicModeCell.cellID,
          for: indexPath
        ) as! SettingBasicModeCell
        cell.cellModel = viewModel.basicModeCellModel
        cell.updateUI()
        return cell
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
