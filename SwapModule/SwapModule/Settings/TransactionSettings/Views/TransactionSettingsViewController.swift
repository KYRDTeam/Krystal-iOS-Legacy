//
//  TransactionSettingsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/08/2022.
//

import UIKit
import BigInt
import Result
import SwiftUI
import AppState
import BaseModule
import Services
import FittedSheets
import Utilities

class TransactionSettingsViewController: KNBaseViewController {
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
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
            self.reloadUI()
        }
        
        self.viewModel.slippageChangedEventHandler = { value in
            self.updateUISaveButton()
        }
        
        self.viewModel.expertModeSwitchChangeStatusHandler = { value in
            guard value == true else {
                self.reloadUI()
                return
            }
            let warningPopup = ExpertModeWarningViewController.instantiateFromNib()
            warningPopup.confirmAction = { confirmed in
                if confirmed {
                    warningPopup.dismiss(animated: true)
                } else {
                    self.viewModel.isExpertMode = false
                    self.viewModel.switchExpertMode.isOn = false
                    self.reloadUI()
                }
            }
            let sheet = SheetViewController(controller: warningPopup, sizes: [.intrinsic], options: SheetOptions(pullBarHeight: 0))
            sheet.dismissOnPull = false
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
            if AppState.shared.currentChain.isSupportedEIP1559() {
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
        
        viewModel.onViewLoaded()
        
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
            self.viewModel.saveWithBlock()
        })
    }
    
    func coordinatorDidUpdateCurrentNonce(_ nonce: Int) {
        viewModel.nonce = nonce
    }
    
    fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
        let nodeService = EthereumNodeService(chain: AppState.shared.currentChain)
        nodeService.getTransactionCount(address: AppState.shared.currentAddress.addressString) { result in
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
            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(SettingSegmentedCell.self, indexPath: indexPath)!
            cell.cellModel = viewModel.segmentedCellModel
            cell.updateUI()
            cell.selectionStyle = .none
            return cell
        case 2:
            if self.viewModel.isAdvancedMode {
                if AppState.shared.currentChain.isSupportedEIP1559() {
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
