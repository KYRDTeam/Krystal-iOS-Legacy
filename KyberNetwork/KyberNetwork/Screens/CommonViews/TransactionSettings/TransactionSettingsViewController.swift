//
//  TransactionSettingsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/08/2022.
//

import UIKit
import BigInt
import Result
import FittedSheets

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
    }
  }
  
  let slippageCellModel = SlippageRateCellModel()
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
  var advancedSettingValueChangeHander: () -> Void = {}
  var saveEventHandler: (SwapTransactionSettings) -> Void = { _ in }
  var titleLabelTappedWithIndex: (Int) -> Void = { _ in }
  
  init(gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium, rate: Rate?, defaultOpenAdvancedMode: Bool) {
    self.gasPrice = selectType.getGasValue()
    self.gasLimit = gasLimit
    self.basicSelectedType = selectType
    self.isAdvancedMode = defaultOpenAdvancedMode

    self.basicModeCellModel.gasLimit = gasLimit
    self.basicModeCellModel.rate = rate
    switch self.basicSelectedType {
    case .fast:
      basicModeCellModel.selectedIndex = 3
    case .medium:
      basicModeCellModel.selectedIndex = 2
    case .slow:
      basicModeCellModel.selectedIndex = 1
    default:
      basicModeCellModel.selectedIndex = -1
    }
    self.slippageCellModel.slippageChangedEvent = { value in
      print("[Setting][SlippageChanged] \(value)")
    }
    self.basicAdvancedCellModel = SettingBasicAdvancedFormCellModel(gasLimit: gasLimit, nonce: -1, rate: rate)
    self.advancedModeCellModel = SettingAdvancedModeFormCellModel(gasLimit: gasLimit, nonce: -1, rate: rate)
    
    self.segmentedCellModel.selectedIndex = isAdvancedMode ? 1 : 0
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
      self.advancedSettingValueChangeHander()
    }
    
    self.basicAdvancedCellModel.gasLimitChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.basicAdvancedCellModel.nonceChangedHandler = { value in
      print("[Setting][BasicAdvanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.advancedModeCellModel.maxPriorityFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.advancedModeCellModel.maxFeeChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.advancedModeCellModel.gasLimitChangedHandler = { value in
      print("[Setting][Advanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.advancedModeCellModel.customNonceChangedHander = { value in
      print("[Setting][Advanced] \(value)")
      self.advancedSettingValueChangeHander()
    }
    
    self.slippageCellModel.slippageChangedEvent = { value in
      self.slippageChangedEventHandler(value)
    }
    
    basicAdvancedCellModel.tapTitleWithIndex = { value in
      self.titleLabelTappedWithIndex(value)
    }
    
    advancedModeCellModel.tapTitleWithIndex = { value in
      self.titleLabelTappedWithIndex(value)
    }
    
    switchExpertMode.tapTitleWithIndex = { value in
      self.titleLabelTappedWithIndex(value)
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
  
  func getAdvancedNonce() -> Int {
    if KNGeneralProvider.shared.isUseEIP1559 {
      return advancedModeCellModel.customNonceValue
    } else {
      return basicAdvancedCellModel.customNonceValue
    }
  }
  
  func hasNoError() -> Bool {
    guard isAdvancedMode else {
      
      return slippageCellModel.hasNoError()
    }
    if KNGeneralProvider.shared.isUseEIP1559 {
      return advancedModeCellModel.hasNoError() && slippageCellModel.hasNoError()
    } else {
      return basicAdvancedCellModel.hasNoError() && slippageCellModel.hasNoError()
    }
  }
  
  func getAdvancedNonceString() -> String {
    if KNGeneralProvider.shared.isUseEIP1559 {
      return advancedModeCellModel.customNonceString
    } else {
      return basicAdvancedCellModel.nonceString
    }
  }
  
  func updateNonce(_ value: Int) {
    self.basicAdvancedCellModel.nonce = value
    self.advancedModeCellModel.nonce = value
    self.nonce = value
  }
  
  func resetData() {
    slippageCellModel.resetData()
    basicModeCellModel.resetData()
    basicAdvancedCellModel.resetData()
    advancedModeCellModel.resetData()
    segmentedCellModel.resetData()
    switchExpertMode.resetData()
    basicAdvancedCellModel.nonce = nonce
    advancedModeCellModel.nonce = nonce
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
      basicAdvancedCellModel.nonce = nonceInt
      advancedModeCellModel.nonce = nonceInt
    }
  }
  
  func buildSwapSetting() -> SwapTransactionSettings {
    let slippage = slippageCellModel.currentRate
    var basicSettings: BasicTransactionSettings? = nil
    var advancedSettings: AdvancedTransactionSettings? = nil
    if isAdvancedMode {
      let info = getAdvancedSettingInfo()
      let gasLimit = BigInt(info.gasLimit) ?? .zero
      let maxFee = info.maxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
      let maxPriorityFee = info.maxPriority.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? .zero
      let nonceInt = Int(getAdvancedNonce())
      advancedSettings = AdvancedTransactionSettings(gasLimit: gasLimit, maxFee: maxFee, maxPriorityFee: maxPriorityFee, nonce: nonceInt)
    } else {
      basicSettings = BasicTransactionSettings(gasPriceType: basicSelectedType)
    }
    
    return SwapTransactionSettings(slippage: slippage, basic: basicSettings, advanced: advancedSettings, expertModeOn: isExpertMode)
  }
  
  func saveWithBlock() {
    UserDefaults.standard.set(switchExpertMode.isOn, forKey: Constants.expertModeSaveKey)
    UserDefaults.standard.set(slippageCellModel.currentRate, forKey: Constants.slippageRateSaveKey)
    saveEventHandler(buildSwapSetting())
  }
}

class TransactionSettingsViewController: KNBaseViewController {
  @IBOutlet weak var settingsTableView: UITableView!
  @IBOutlet weak var saveButton: UIButton!
  
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
      self.reloadUI()
    }
    
    self.viewModel.slippageChangedEventHandler = { value in
      self.updateUISaveButton()
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
    let sheet = SheetViewController(controller: warningPopup, sizes: [.fixed(454)], options: SheetOptions(pullBarHeight: 0))
      self.present(sheet, animated: true, completion: nil)
    }
    
    viewModel.advancedSettingValueChangeHander = {
      self.updateUISaveButton()
    }
    
    viewModel.titleLabelTappedWithIndex = { index in
      if index == 8 {
        self.showBottomBannerView(
          message: "expert_i".toBeLocalised(),
          icon: UIImage(named: "help_icon_large") ?? UIImage(),
          time: 10
        )
        return
      }
      if KNGeneralProvider.shared.isUseEIP1559 {
        var message = ""
        switch index {
        case 0:
          message = "priority_fee_i".toBeLocalised()
        case 1:
          message = "max_fee_i".toBeLocalised()
        case 2:
          message = "gas_limit_i".toBeLocalised()
        case 3:
          message = "nonce_i".toBeLocalised()
        default:
          break
        }
        if !message.isEmpty {
          self.showBottomBannerView(
            message: message,
            icon: UIImage(named: "help_icon_large") ?? UIImage(),
            time: 10
          )
        }
      } else {
        var message = ""
        switch index {
        case 0:
          message = "gas_price_i".toBeLocalised()
        case 1:
          message = "gas_limit_i".toBeLocalised()
        case 2:
          message = "nonce_i".toBeLocalised()
        default:
          break
        }
        if !message.isEmpty {
          self.showBottomBannerView(
            message: message,
            icon: UIImage(named: "help_icon_large") ?? UIImage(),
            time: 10
          )
        }
      }
      
    }
    
    getLatestNonce { result in
      if case .success(let nonce) = result {
        self.coordinatorDidUpdateCurrentNonce(nonce)
      }
    }
  }
  
  private func reloadUI() {
    DispatchQueue.main.async {
      self.settingsTableView.reloadData()
      self.updateUISaveButton()
    }
  }
  
  private func updateUISaveButton() {
    if viewModel.hasNoError() {
      saveButton.isEnabled = true
      saveButton.alpha = 1
    } else {
      saveButton.isEnabled = false
      saveButton.alpha = 0.5
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
      
      let customNonce = self.viewModel.getAdvancedNonce()
      if customNonce != -1 && customNonce != self.viewModel.nonce {
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedNonce(nonce: self.viewModel.getAdvancedNonceString()))
      }
      
      self.viewModel.saveWithBlock()
    })
  }
  
  func coordinatorDidUpdateCurrentNonce(_ nonce: Int) {
    viewModel.nonce = nonce
  }
  
  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    web3Service.getTransactionCount(for: AppDelegate.session.address.addressString) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

extension TransactionSettingsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.row {
    case 0:
      let cell = tableView.dequeueReusableCell(SlippageRateCell.self, indexPath: indexPath)!
      cell.cellModel = viewModel.slippageCellModel
      cell.configSlippageUI()
      return cell
    case 1:
      let cell = tableView.dequeueReusableCell(SettingSegmentedCell.self, indexPath: indexPath)!
      cell.cellModel = viewModel.segmentedCellModel
      cell.updateUI()
      return cell
    case 2:
      if self.viewModel.isAdvancedMode {
        if KNGeneralProvider.shared.isUseEIP1559 {
          let cell = tableView.dequeueReusableCell(SettingAdvancedModeFormCell.self, indexPath: indexPath)!
          cell.cellModel = viewModel.advancedModeCellModel
          cell.fillFormUI()
          cell.updateUI()
          return cell
        } else {
          let cell = tableView.dequeueReusableCell(SettingBasicAdvancedFormCell.self, indexPath: indexPath)!
          cell.cellModel = viewModel.basicAdvancedCellModel
          cell.fillFormValues()
          cell.updateUI()
          return cell
        }
      } else {
        let cell = tableView.dequeueReusableCell(SettingBasicModeCell.self, indexPath: indexPath)!
        cell.cellModel = viewModel.basicModeCellModel
        cell.updateUI()
        return cell
      }
    case 3:
      let cell = tableView.dequeueReusableCell(SettingExpertModeSwitchCell.self, indexPath: indexPath)!
      cell.cellModel = self.viewModel.switchExpertMode
      cell.updateUI()
     
      return cell
    default:
      break
    }
    return UITableViewCell()
  }
}
