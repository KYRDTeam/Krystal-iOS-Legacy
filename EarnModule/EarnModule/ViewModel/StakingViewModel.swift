//
//  StakingViewModel.swift
//  EarnModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import BigInt
import Utilities
import AppState
import Services
import Dependencies
import TransactionModule

class StakingViewModel {
  let pool: EarnPoolModel
  let selectedPlatform: EarnPlatform
  let apiService = EarnServices()
  var optionDetail: Observable<[EarningToken]?> = .init(nil)
  var error: Observable<Error?> = .init(nil)
  var amount: Observable<String> = .init("")
  var selectedEarningToken: Observable<EarningToken?> = .init(nil)
  var formState: Observable<FormState> = .init(.empty)
  var gasPrice: Observable<BigInt> = .init(AppDependencies.gasConfig.getStandardGasPrice(chain: AppState.shared.currentChain))
  var gasLimit: Observable<BigInt> = .init(AppDependencies.gasConfig.earnGasLimitDefault)
  var baseGasLimit: BigInt = AppDependencies.gasConfig.earnGasLimitDefault
  var txObject: Observable<TxObject?> = .init(nil)
  var isLoading: Observable<Bool> = .init(false)
  
  
  var setting: TxSettingObject = .default
  
  
//  var basicSetting: BasicTransactionSettings = BasicTransactionSettings(gasPriceType: .medium) {
//    didSet {
//      let gas = self.basicSetting.gasPriceType.getGasValue()
//      self.gasPrice.value = gas
//    }
//  }
//  var advancedSetting: AdvancedTransactionSettings? = nil {
//    didSet {
//      guard let setting = self.advancedSetting else { return }
//      self.gasPrice.value = setting.maxFee
//      self.gasLimit.value = setting.gasLimit
//    }
//  }
  
  
  
  
  
  var isUseReverseRate: Observable<Bool> = .init(false)
  
  var nextButtonStatus: Observable<NextButtonState> = .init(.notApprove)
  
  var tokenAllowance: BigInt? {
    didSet {
      self.checkNextButtonStatus()
    }
  }
  
  var isExpandProjection: Observable<Bool> = .init(false)
  
  init(pool: EarnPoolModel, platform: EarnPlatform) {
    self.pool = pool
    self.selectedPlatform = platform
  }
  
  var displayMainHeader: String {
    return "Stake \(pool.token.symbol.uppercased()) on \(selectedPlatform.name.uppercased())"
  }
  
  var displayStakeToken: String {
    return AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address).shortString(decimals: pool.token.decimals) + " " + pool.token.symbol.uppercased()
  }
  
  var displayAPY: String {
    return StringFormatter.percentString(value: selectedPlatform.apy / 100)
  }
  
  var amountBigInt: BigInt {
    return self.amount.value.amountBigInt(decimals: pool.token.decimals) ?? BigInt(0)
  }
  
  var transactionFee: BigInt {
    return self.gasPrice.value * self.gasLimit.value
  }
  
  var feeETHString: String {
    let string: String = self.transactionFee.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "\(string) \(AppState.shared.currentChain.quoteToken())"
  }

  var feeUSDString: String {
    let quoteUSD = AppDependencies.priceStorage.getQuoteUsdRate(chain: AppState.shared.currentChain) ?? 0
    let usd = self.transactionFee * BigInt(quoteUSD * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String =  usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "(~ \(valueString) USD)"
  }
  
  var displayFeeString: String {
    return "\(feeETHString) \(feeUSDString)"
  }
  
  func requestOptionDetail() {
    apiService.getStakingOptionDetail(platform: selectedPlatform.name, earningType: selectedPlatform.type, chainID: "\(pool.chainID)", tokenAddress: pool.token.address) { result in
      switch result {
      case .success(let detail):
        self.optionDetail.value = detail
        self.selectedEarningToken.value = detail.first
      case .failure(let error):
        self.error.value = error
      }
    }
  }
  
  func checkNextButtonStatus() {
    guard let tokenAllowance = tokenAllowance else {
      self.nextButtonStatus.value = .notApprove
      getAllowance()
      return
    }
    if amountBigInt > tokenAllowance {
      self.nextButtonStatus.value = .needApprove
    } else {
      self.nextButtonStatus.value = .noNeed
    }
  }
  
  var buildTxRequestParams: JSONDictionary {
    
    var params: JSONDictionary = [
      "tokenAmount": amountBigInt.description,
      "chainID": pool.chainID,
      "earningType": selectedPlatform.type,
      "platform": selectedPlatform.name,
      "userAddress": AppState.shared.currentAddress.addressString,
      "tokenAddress": pool.token.address
    ]
    if selectedPlatform.name.lowercased() == "ankr" {
      var useC = false
      if selectedEarningToken.value?.name.suffix(1).description.lowercased() == "c" {
        useC = true
      }
      
      params["extraData"] = ["ankr": ["useTokenC": useC]]
    }
    return params
  }
  
  func requestBuildStakeTx(showLoading: Bool = false, completion: @escaping () -> () = {}) {
    if showLoading { isLoading.value = true }
    apiService.buildStakeTx(param: buildTxRequestParams) { result in
      switch result {
      case .success(let tx):
        self.txObject.value = tx
        self.gasLimit.value = BigInt(tx.gasLimit.drop0x, radix: 16) ?? AppDependencies.gasConfig.earnGasLimitDefault
        completion()
      case .failure(let error):
        self.error.value = error
      }
      if showLoading { self.isLoading.value = false }
    }
  }
  
  var displayAmountReceive: String {
    guard let detail = selectedEarningToken.value, !amount.value.isEmpty, let amountDouble = Double(amount.value) else { return "---" }
    let receiveAmt = rate * amountDouble
    return receiveAmt.description + " " + detail.symbol
  }
  
  var rate: Double {
    guard let detail = selectedEarningToken.value else { return 0.0 }
    return detail.exchangeRate / pow(10.0, 18.0)
  }
  
  var displayRate: String {
    guard let detail = selectedEarningToken.value else { return "---" }
    if isUseReverseRate.value {
      return "1 \(detail.symbol) = \(1 / rate) \(pool.token.symbol)"
    } else {
      return "1 \(pool.token.symbol) = \(rate) \(detail.symbol)"
    }
  }
  
  var isAmountTooSmall: Bool {
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return self.amountBigInt > AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address)
  }
  
  var displayProjectionValues: ProjectionValues? {
    guard !amount.value.isEmpty else {
      return nil
    }
    let amt = amountBigInt
    let apy = selectedPlatform.apy
    let decimal = pool.token.decimals
    let symbol = pool.token.symbol
    
    let p30Param = apy * 30.0 / 365
    let p60Param = apy * 60.0 / 365
    let p90Param = apy * 90.0 / 365
    
    let p30 = amt * BigInt(p30Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    let p60 = amt * BigInt(p60Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    let p90 = amt * BigInt(p90Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    
    let displayP30 = p30.shortString(decimals: decimal) + " \(symbol)"
    let displayP60 = p60.shortString(decimals: decimal) + " \(symbol)"
    let displayP90 = p90.shortString(decimals: decimal) + " \(symbol)"
    
    var displayP30USD = ""
    var displayP60USD = ""
    var displayP90USD = ""
    
    if let usdPrice = AppDependencies.priceStorage.getUsdPrice(address: pool.token.address) {
      let usd30 = p30 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      let usd60 = p60 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      let usd90 = p90 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      
      displayP30USD = "≈ " + usd30.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
      displayP60USD = "≈ " + usd60.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
      displayP90USD = "≈ " + usd90.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
    }
    
    return ( (displayP30, displayP30USD), (displayP60, displayP60USD), (displayP90, displayP90USD) )
    
  }
  
  func getAllowance() {
    guard !pool.token.isQuoteToken() else {
      nextButtonStatus.value = .noNeed
      return
    }
    guard let tx = txObject.value else {
      requestBuildStakeTx(showLoading: false, completion: {
        self.getAllowance()
      })
      return
    }
    
    let contractAddress = tx.to
    let service = EthereumNodeService(chain: AppState.shared.currentChain)
    service.getAllowance(for: AppState.shared.currentAddress.addressString, networkAddress: contractAddress, tokenAddress: pool.token.address) { result in
      switch result {
      case .success(let number):
        self.tokenAllowance = number
      case .failure(let error):
        self.error.value = error
        self.tokenAllowance = nil
      }
    }
  }
  
  var isChainValid: Bool {
    return AppState.shared.currentChain.customRPC().chainID == pool.chainID
  }
    
    func reloadData() {
        requestOptionDetail()
        getAllowance()
        amount.value = AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address).fullString(decimals: pool.token.decimals)
    }
}
