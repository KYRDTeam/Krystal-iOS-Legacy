//
//  TransactionSettingsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/08/2022.
//

import UIKit
import BigInt

class TransactionSettingsViewModel {
  var isAdvancedMode = false
  var isExpertMode = false
  
  var gasLimit: BigInt
  var selectedType: KNSelectedGasPriceType
  
  let slippageCellModel = SlippageRateCellModel(currentRatePercentage: 0.5)
  let segmentedCellModel = SettingSegmentedCellModel()
  let switchExpertMode = SettingExpertModeSwitchCellModel()
  let basicModeCellModel = SettingBasicModeCellModel()
  
  var switchExpertModeEventHandler: (Bool) -> Void = { _ in }
  var switchAdvancedModeEventHandle: (Bool) -> Void = { _ in }
  
  init(gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium) {
    self.gasLimit = gasLimit
    self.selectedType = selectType
    self.basicModeCellModel.gasLimit = gasLimit
    self.slippageCellModel.slippageChangedEvent = { value in
      print("[Setting][SlippageChanged] \(value)")
    }
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
    }
  }
}

class TransactionSettingsViewController: KNBaseViewController {
  @IBOutlet weak var settingsTableView: UITableView!
  
  let viewModel: TransactionSettingsViewModel
  
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
  }
  
  @IBAction func backBtnTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
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
       
        return cell
      } else {
        if self.viewModel.isAdvancedMode {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingBasicAdvancedFormCell.cellID,
            for: indexPath
          ) as! SettingBasicAdvancedFormCell
         
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
