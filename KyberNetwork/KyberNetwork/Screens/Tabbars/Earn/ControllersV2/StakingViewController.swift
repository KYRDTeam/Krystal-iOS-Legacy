//
//  StakingViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 26/10/2022.
//

import UIKit

class StakingViewModel {
  let pool: EarnPoolModel
  let selectedPlatform: EarnPlatform
  let apiService = KrystalService()
  var optionDetail: Observable<EarningToken?> = .init(nil)
  var error: Observable<Error?> = .init(nil)
  var amount: String = ""
  
  init(pool: EarnPoolModel, platform: EarnPlatform) {
    self.pool = pool
    self.selectedPlatform = platform
  }
  
  var displayMainHeader: String {
    return "Stake \(pool.token.name.uppercased()) on \(selectedPlatform.name.uppercased())"
  }
  
  var displayStakeToken: String {
    return pool.token.getBalanceBigInt().shortString(decimals: pool.token.decimals) + " " + pool.token.symbol.uppercased()
  }
  
  func requestOptionDetail() {
    apiService.getStakingOptionDetail(platform: selectedPlatform.name, earningType: selectedPlatform.type, chainID: "\(pool.chainID)", tokenAddress: pool.token.address) { result in
      switch result {
      case .success(let detail):
        self.optionDetail.value = detail.first
      case .failure(let error):
        self.error.value = error
      }
    }
  }
  
  var displayAmountReceive: String {
    guard let detail = optionDetail.value, !amount.isEmpty, let amountDouble = Double(amount) else { return "---" }
    let receiveAmt = detail.exchangeRate * amountDouble
    return receiveAmt.description + " " + detail.symbol
  }
  
  var displayRate: String {
    guard let detail = optionDetail.value else { return "---" }
    return "1 \(pool.token.symbol) = \(detail.exchangeRate) \(detail.symbol)"
  }
}

class StakingViewController: InAppBrowsingViewController {
  
  @IBOutlet weak var stakeMainHeaderLabel: UILabel!
  @IBOutlet weak var stakeTokenLabel: UILabel!
  @IBOutlet weak var stakeTokenImageView: UIImageView!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var apyInfoView: SwapInfoView!
  @IBOutlet weak var amountReceiveInfoView: SwapInfoView!
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var networkFeeInfoView: SwapInfoView!
  var viewModel: StakingViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindingViewModel()
    viewModel.requestOptionDetail()
  }
  
  private func setupUI() {
    apyInfoView.setTitle(title: "APY (Est. Yield", underlined: false)
    apyInfoView.iconImageView.isHidden = true
    
    amountReceiveInfoView.setTitle(title: "You will receive", underlined: false)
    amountReceiveInfoView.iconImageView.isHidden = true
    
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.iconImageView.isHidden = true
    
    networkFeeInfoView.setTitle(title: "Network Fee", underlined: false)
    networkFeeInfoView.iconImageView.isHidden = true
  }
  
  private func bindingViewModel() {
    stakeMainHeaderLabel.text = viewModel.displayMainHeader
    stakeTokenLabel.text = viewModel.displayStakeToken
    stakeTokenImageView.setImage(urlString: viewModel.pool.token.logo, symbol: viewModel.pool.token.symbol)
    apyInfoView.setValue(value: viewModel.selectedPlatform.apy.description, highlighted: true)
    viewModel.optionDetail.observeAndFire(on: self) { _ in
      self.amountReceiveInfoView.setValue(value: self.viewModel.displayAmountReceive)
      self.rateInfoView.setValue(value: self.viewModel.displayRate)
      
    }
    
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
  
}
