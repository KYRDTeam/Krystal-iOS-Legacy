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
import BaseModule

class StakingViewModel: BaseViewModel {
    let pool: EarnPoolModel
    let selectedPlatform: EarnPlatform
    let apiService = EarnServices()
    var optionDetail: Observable<OptionDetailResponse?> = .init(nil)
    var error: Observable<Error?> = .init(nil)
    var amount: Observable<BigInt> = .init(.zero)
    var selectedEarningToken: Observable<EarningToken?> = .init(nil)
    var formState: Observable<FormState> = .init(.empty)
    var gasLimit: Observable<BigInt> = .init(AppDependencies.gasConfig.earnGasLimitDefault)
    var txObject: Observable<TxObject?> = .init(nil)
    var isLoading: Observable<Bool> = .init(false)
    var setting: TxSettingObject = .default
    var isUseReverseRate: Observable<Bool> = .init(false)
    var nextButtonStatus: Observable<NextButtonState> = .init(.notApprove)
    var balance: Observable<BigInt> = .init(0)
    
    var tokenAllowance: BigInt? {
        didSet {
            self.checkNextButtonStatus()
        }
    }
    
    var isExpandProjection: Observable<Bool> = .init(false)
    
    let tokenService = TokenService()
    var quoteTokenDetail: TokenDetailInfo?
    var stakingTokenDetail: TokenDetailInfo?
    var onFetchedQuoteTokenPrice: (() -> ())?
    var onGasSettingUpdated: (() -> ())?
    
    init(pool: EarnPoolModel, platform: EarnPlatform) {
        self.pool = pool
        self.selectedPlatform = platform
        self.balance.value = AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address)
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .kTxStatusUpdated, object: nil)
    }
    
    func observeEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.txStatusUpdated(_:)),
            name: .kTxStatusUpdated,
            object: nil
        )
    }
    
    @objc func txStatusUpdated(_ notification: Notification) {
        getBalance()
    }
    
    func validateAmount() -> StakingValidationError? {
        let amount = self.amount.value
        if amount > balance.value {
            return .insufficient
        } else if let validation = self.optionDetail.value?.validation {
            if let min = validation.minStakeAmount, amount < BigInt(min * pow(10.0, Double(self.pool.token.decimals))) {
                return .notEnoughMin(minValue: min)
            } else if let max = validation.maxStakeAmount, amount > BigInt(max * pow(10.0, Double(self.pool.token.decimals))) {
                return .higherThanMax(maxValue: max)
            } else if let interval = validation.stakeInterval {
                let dividend = amount / BigInt(interval * pow(10.0, Double(self.pool.token.decimals)))
                if dividend * BigInt(interval * pow(10.0, Double(self.pool.token.decimals))) != amount {
                    return .notIntervalOf(interval: interval)
                }
            }
        }
        return nil
    }
    
    var faqInput: FAQInput {
        return (selectedPlatform.name.lowercased(), pool.token.symbol.lowercased(), pool.chainID)
    }
    
    var displayMainHeader: String {
        return "Stake \(pool.token.symbol.uppercased()) on \(selectedPlatform.name.uppercased())"
    }
    
    var displayStakeToken: String {
        return NumberFormatUtils.balanceFormat(value: balance.value, decimals: pool.token.decimals) + " " + pool.token.symbol.uppercased()
    }
    
    var displayAPY: String {
        return StringFormatter.percentString(value: selectedPlatform.apy / 100)
    }
    
    var transactionFee: BigInt {
        if let basic = setting.basic {
            return setting.gasLimit * self.getGasPrice(gasType: basic.gasType)
          } else if let advance = setting.advanced {
            return setting.gasLimit * advance.maxFee
          }
        return BigInt(0)
    }
    
    var feeETHString: String {
        let string: String = NumberFormatUtils.gasFee(value: transactionFee)
        return "\(string) \(AppState.shared.currentChain.quoteToken())"
    }
    
    var quoteTokenUsdPrice: Double {
        return quoteTokenDetail?.markets["usd"]?.price ?? 0
    }
    
    var stakingTokenUsdPrice: Double? {
        return stakingTokenDetail?.markets["usd"]?.price
    }
    
    var feeUSDString: String {
        let usd = self.transactionFee * BigInt(quoteTokenUsdPrice * pow(10, 18)) / BigInt(10).power(18)
        let valueString = NumberFormatUtils.gasFee(value: usd)
        return "(~ $\(valueString))"
    }
    
    var displayFeeString: String {
        return "\(feeETHString) \(feeUSDString)"
    }
  
    func getGasPrice(gasType: GasSpeed) -> BigInt {
        guard let chain = ChainType.make(chainID: pool.chainID) else { return .zero }
        return GasPriceManager.shared.getGasPrice(gasType: gasType, chain: chain)
    }
    
    func getPriority(gasType: GasSpeed) -> BigInt? {
        guard let chain = ChainType.make(chainID: pool.chainID) else { return .zero }
        return GasPriceManager.shared.getPriority(gasType: gasType, chain: chain)
    }

    func checkNextButtonStatus() {
        guard let tokenAllowance = tokenAllowance else {
            self.nextButtonStatus.value = .notApprove
            getAllowance()
            return
        }
        if amount.value > tokenAllowance {
            self.nextButtonStatus.value = .needApprove
        } else {
            self.nextButtonStatus.value = .noNeed
        }
    }
    
    var buildTxRequestParams: JSONDictionary {
        let paramBuilder = EarnParamBuilderFactory.create(platform: .init(name: selectedPlatform.name))
        return paramBuilder.buildStakingTxParam(amount: amount.value, pool: pool, platform: selectedPlatform, earningToken: selectedEarningToken.value)
    }
    
    var displayAmountReceive: String {
        guard let detail = selectedEarningToken.value, amount.value > 0 else { return "---" }
        let receiveAmt = BigInt(rate * pow(10.0, 18.0)) * amount.value / BigInt(10).power(18)
        return NumberFormatUtils.amount(value: receiveAmt, decimals: 18) + " " + detail.symbol
    }
    
    var rate: Double {
        guard let detail = selectedEarningToken.value else { return 0.0 }
        return detail.exchangeRate / pow(10.0, 18.0)
    }
    
    var displayRate: String {
        guard let detail = selectedEarningToken.value else { return "---" }
        let bigIntRate = BigInt(rate * pow(10.0, 18.0))
        if isUseReverseRate.value {
            let revertedRate = bigIntRate.isZero ? 0 : (BigInt(10).power(36) / bigIntRate)
            let rateString = NumberFormatUtils.rate(value: revertedRate, decimals: 18)
            return "1 \(detail.symbol) = \(rateString) \(pool.token.symbol)"
        } else {
            let rateString = NumberFormatUtils.rate(value: bigIntRate, decimals: 18)
            return "1 \(pool.token.symbol) = \(rateString) \(detail.symbol)"
        }
    }
    
    var isAmountTooSmall: Bool {
        return self.amount.value == BigInt(0)
    }
    
    var isAmountTooBig: Bool {
        return self.amount.value > AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address)
    }
    
    var displayProjectionValues: ProjectionValues? {
        guard amount.value > 0 else {
            return nil
        }
        return (calculateReward(dayPeriod: 30), calculateReward(dayPeriod: 60), calculateReward(dayPeriod: 90))
    }
    
    var isChainValid: Bool {
        return currentChain.customRPC().chainID == pool.chainID
    }
    
    func calculateReward(dayPeriod: Int) -> (String, String) {
        let decimal = pool.token.decimals
        let symbol = pool.token.symbol
        
        let periodReward = selectedPlatform.apy / 100.0 * Double(dayPeriod) / 365
        let tokenAmount = amount.value * BigInt(periodReward * pow(10.0, 18.0)) / BigInt(10).power(18)
        let amountString = NumberFormatUtils.amount(value: tokenAmount, decimals: decimal) + " \(symbol)"
        
        var usdAmountString = ""
        if let usdPrice = stakingTokenUsdPrice {
            let usdAmount = tokenAmount * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
            usdAmountString = "≈ $" + NumberFormatUtils.usdAmount(value: usdAmount, decimals: 18)
        }
        return (amountString, usdAmountString)
    }
    
    func reloadData() {
        getBalance()
        requestOptionDetail()
        getAllowance()
    }
    
    func messageFor(validationError: StakingValidationError) -> String {
        switch validationError {
        case .insufficient:
            return Strings.insufficientBalance
        case .notEnoughMin(let minValue):
            let bigIntValue = BigInt(minValue * pow(10.0, 18))
            return String(format: Strings.shouldBeAtLeast, NumberFormatUtils.amount(value: bigIntValue, decimals: 18))
        case .higherThanMax(let maxValue):
            let bigIntValue = BigInt(maxValue * pow(10.0, 18))
            return String(format: Strings.shouldNoMoreThan, NumberFormatUtils.amount(value: bigIntValue, decimals: 18))
        case .notIntervalOf(let interval):
            let bigIntValue = BigInt(interval * pow(10.0, 18))
            return String(format: Strings.shouldBeIntervalOf, NumberFormatUtils.amount(value: bigIntValue, decimals: 18))
        case .empty:
            return ""
        }
    }
    
    func didGetTxGasLimit(gasLimit: BigInt) {
        if setting.advanced != nil {
            return
        }
        setting.basic?.gasLimit = gasLimit
        onGasSettingUpdated?()
    }
}

extension StakingViewModel {
    
    func getBalance() {
        EthereumNodeService(chain: currentChain).getBalance(address: currentAddress.addressString, tokenAddress: pool.token.address) { balance in
            self.balance.value = balance
        }
    }
    
    func getQuoteTokenPrice() {
        tokenService.getTokenDetail(address: currentChain.customRPC().quoteTokenAddress, chainPath: currentChain.customRPC().apiChainPath) { [weak self] tokenDetail in
            self?.quoteTokenDetail = tokenDetail
            self?.onFetchedQuoteTokenPrice?()
        }
    }
    
    func getStakingTokenDetail() {
        tokenService.getTokenDetail(address: pool.token.address, chainPath: currentChain.customRPC().apiChainPath) { [weak self] tokenDetail in
            self?.stakingTokenDetail = tokenDetail
        }
    }
    
    func requestOptionDetail() {
        apiService.getStakingOptionDetail(platform: selectedPlatform.name, earningType: selectedPlatform.type, chainID: "\(pool.chainID)", tokenAddress: pool.token.address) { result in
            switch result {
            case .success(let detail):
                self.optionDetail.value = detail
                self.selectedEarningToken.value = detail.earningTokens.first
            case .failure(let error):
                self.error.value = error
            }
        }
    }
    
    func requestBuildStakeTx(showLoading: Bool = false, completion: @escaping () -> () = {}) {
        if showLoading { isLoading.value = true }
        apiService.buildStakeTx(param: buildTxRequestParams) { [weak self] result in
            switch result {
            case .success(let tx):
                self?.txObject.value = tx
                if let gasLimit = BigInt(tx.gasLimit.drop0x, radix: 16), gasLimit > 0 {
                    self?.didGetTxGasLimit(gasLimit: gasLimit)
                }
                completion()
            case .failure(let error):
                self?.error.value = error
            }
            if showLoading { self?.isLoading.value = false }
        }
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
        let service = EthereumNodeService(chain: currentChain)
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
    
}
