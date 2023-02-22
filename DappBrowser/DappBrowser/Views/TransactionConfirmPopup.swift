//
//  DappBrowerTransactionConfirmPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 05/01/2022.
//

import UIKit
import BigInt
import Utilities
import BaseModule
import Services
import AppState
import TransactionModule

class TransactionConfirmPopup: BaseWalletOrientedViewController {
  @IBOutlet weak var siteIconImageView: UIImageView!
  @IBOutlet weak var siteURLLabel: UILabel!
  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var equivalentValueLabel: UILabel!
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var approveMsgLabel: UILabel!
  @IBOutlet weak var valueTitleLabel: UILabel!
  
  private let viewModel: DappBrowerTransactionConfirmViewModel
    
  init(viewModel: DappBrowerTransactionConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: TransactionConfirmPopup.className, bundle: Bundle(for: TransactionConfirmPopup.self))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupUI()
  }

  @IBAction func tapOutsidePopup(_ sender: Any) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel?()
    }
  }

  @IBAction func tapInsidePopup(_ sender: Any) {
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel?()
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onSign?(self.viewModel.settingObject)
    }
  }
  
  @IBAction func transactionFeeHelpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
  
  @IBAction func editSettingButtonTapped(_ sender: UIButton) {
      TransactionSettingPopup.show(on: self, chain: AppState.shared.currentChain, currentSetting: viewModel.settingObject, onConfirmed: { [weak self] settingObject in
          self?.viewModel.settingObject = settingObject
          self?.updateGasFeeUI()
      }, onCancelled: {
          return
      })
  }

  fileprivate func updateGasFeeUI() {
    self.equivalentValueLabel.text = self.viewModel.displayValueUSD
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
  }

  private func setupUI() {
    self.fromAddressLabel.text = self.viewModel.displayFromAddress
    self.valueLabel.text = self.viewModel.displayValue
    self.updateGasFeeUI()
    self.siteURLLabel.text = self.viewModel.webPageInfo.url ?? ""
    self.siteIconImageView.loadImage(viewModel.imageIconURL)
    self.contentView.rounded(radius: 16)
    self.confirmButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)
    let isApprove = self.viewModel.isApproveTx
    self.valueTitleLabel.isHidden = isApprove
    self.valueLabel.isHidden = isApprove
    self.equivalentValueLabel.isHidden = isApprove
    if isApprove {
        let service = EthereumNodeService(chain: AppState.shared.currentChain)
        service.getTokenSymbol(address: self.viewModel.transaction.to ?? "") { (result) in
          switch result {
          case .success(let symbol):
            self.approveMsgLabel.text = self.viewModel.buildApproveMsg(symbol)
            self.approveMsgLabel.isHidden = false
          case .failure(_):
            self.approveMsgLabel.text = self.viewModel.buildApproveMsg("Unknow")
            self.approveMsgLabel.isHidden = false
          }
        }
    }
  }
    
    

}
