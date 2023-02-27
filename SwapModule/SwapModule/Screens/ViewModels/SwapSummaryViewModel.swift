//
//  SwapSummaryViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 10/08/2022.
//

import UIKit
import Moya
import JSONRPCKit
import APIKit
import BigInt
import Result
import KrystalWallets
import Utilities
import Services
import AppState
import Dependencies
import TransactionModule

class SwapSummaryViewModel: SwapInfoViewModelProtocol {
    var quoteTokenDetail: TokenDetailInfo?
    
    var settings: SwapTransactionSettings {
        return swapObject.swapSetting
    }
    var selectedRate: Rate? {
        return swapObject.rate
    }
    var swapObject: SwapObject
    
    var rateString: Observable<String?> = .init(nil)
    var slippageString: Observable<String?> = .init(nil)
    var minReceiveString: Observable<String?> = .init(nil)
    var estimatedGasFeeString: Observable<String?> = .init(nil)
    var maxGasFeeString: Observable<String?> = .init(nil)
    var priceImpactString: Observable<String?> = .init(nil)
    var newRate: Observable<Rate?> = .init(nil)
    var error: Observable<String?> = .init(nil)
    var priceImpactState: Observable<PriceImpactState> = .init(.normal)
    var onUpdateRate: ((Rate) -> ())?
    var onTxSendSuccess: ((PendingSwapTxInfo) -> ())?
    var onTxFailed: ((String) -> ())?
    
    var showRevertedRate: Bool {
        didSet {
            self.rateString.value = self.getRateString(sourceToken: swapObject.sourceToken, destToken: swapObject.destToken)
        }
    }
    
    var minRatePercent: Double {
        didSet {
            self.slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
        }
    }
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    var toAmount: BigInt {
        return BigInt(swapObject.rate.amount) ?? BigInt(0)
    }
    
    var minDestQty: BigInt {
        return self.toAmount * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
    }
    
    var leftAmountString: String {
        let amountString = NumberFormatUtils.amount(value: swapObject.sourceAmount, decimals: swapObject.sourceToken.decimals)
        return "\(amountString.prefix(15)) \(swapObject.sourceToken.symbol)"
    }
    
    var rightAmountString: String {
        let receivedAmount = swapObject.rate.amount.bigInt ?? BigInt(0)
        let amountString = NumberFormatUtils.amount(value: receivedAmount, decimals: swapObject.destToken.decimals)
        return "\(amountString.prefix(15)) \(swapObject.destToken.symbol)"
    }
    
    var displayEstimatedRate: String {
        let rateString = swapObject.rate.rate
        return "1 \(swapObject.sourceToken.symbol) = \(rateString) \(swapObject.destToken.symbol)"
    }
    
    fileprivate var updateRateTimer: Timer?
    let swapService = SwapService()
    
    init(swapObject: SwapObject) {
        self.swapObject = swapObject
        self.showRevertedRate = swapObject.showRevertedRate
        self.minRatePercent = swapObject.swapSetting.slippage
    }
    
    func updateData() {
        rateString.value = getRateString(sourceToken: swapObject.sourceToken, destToken: swapObject.destToken)
        minReceiveString.value = calculateMinReceiveString(rate: swapObject.rate)
        estimatedGasFeeString.value = getEstimatedNetworkFeeString(rate: swapObject.rate)
        priceImpactString.value = getPriceImpactString(rate: swapObject.rate)
        priceImpactState.value = getPriceImpactState(change: Double(swapObject.rate.priceImpact) / 100)
        maxGasFeeString.value = getMaxNetworkFeeString(rate: swapObject.rate)
        slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    }
    
    func updateRate() {
        if let newRate = newRate.value {
            swapObject.rate = newRate
            rateString.value = getRateString(sourceToken: swapObject.sourceToken, destToken: swapObject.destToken)
            priceImpactString.value = getPriceImpactString(rate: swapObject.rate)
            priceImpactState.value = getPriceImpactState(change: Double(swapObject.rate.priceImpact) / 100)
            
            updateInfo()
            onUpdateRate?(swapObject.rate)
            self.newRate.value = nil
        }
    }
    
    func updateInfo() {
        self.slippageString.value = "\(String(format: "%.1f", self.settings.slippage))%"
        self.minReceiveString.value = self.getMinReceiveString(destToken: swapObject.destToken, rate: swapObject.rate)
        self.estimatedGasFeeString.value = self.getEstimatedNetworkFeeString(rate: swapObject.rate)
        self.maxGasFeeString.value = self.getMaxNetworkFeeString(rate: swapObject.rate)
    }
    
    func updateSettings(settings: SwapTransactionSettings) {
        self.swapObject.swapSetting = settings
        updateInfo()
    }
    
    private func calculateMinReceiveString(rate: Rate) -> String {
        let amount = BigInt(rate.amount) ?? BigInt(0)
        let minReceivingAmount = amount * BigInt(10000.0 - minRatePercent * 100.0) / BigInt(10000.0)
        return "\(NumberFormatUtils.balanceFormat(value: minReceivingAmount, decimals: self.swapObject.destToken.decimals)) \(self.swapObject.destToken.symbol)"
    }
    
    func getSourceAmountUsdString() -> String {
        let amountUSD = swapObject.sourceAmount * BigInt(swapObject.sourceTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(swapObject.sourceToken.decimals)
        let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
        return "~$\(formattedAmountUSD)"
    }
    
    func getDestAmountString() -> String {
        let receivingAmount = BigInt(swapObject.rate.amount) ?? BigInt(0)
        return NumberFormatUtils.balanceFormat(value: receivingAmount, decimals: swapObject.destToken.decimals)
    }
    
    func getDestAmountUsdString() -> String {
        let receivingAmount = BigInt(swapObject.rate.amount) ?? BigInt(0)
        let amountUSD = receivingAmount * BigInt(swapObject.destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(swapObject.destToken.decimals)
        let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
        return "~$\(formattedAmountUSD)"
    }
    
    func startUpdateRate() {
        self.updateRateTimer?.invalidate()
        self.fetchRate()
        self.updateRateTimer = Timer.scheduledTimer(
            withTimeInterval: 15,
            repeats: true,
            block: { [weak self] _ in
                guard let `self` = self else { return }
                self.fetchRate()
            }
        )
    }
    
    func fetchRate() {
        let chainPath = AppState.shared.currentChain.apiChainPath()
        let srcContract = swapObject.sourceToken.address.lowercased()
        let dstContract = swapObject.destToken.address.lowercased()
        swapService.getAllRates(chainPath: chainPath, address: currentAddress.addressString, srcTokenContract: srcContract, destTokenContract: dstContract, amount: self.swapObject.sourceAmount, focusSrc: true) { [weak self] rates in
            guard let self = self else { return }
            let sortedRates = rates.sorted { lhs, rhs in
                return self.diffInUSD(lhs: lhs, rhs: rhs, destToken: self.swapObject.destToken, destTokenPrice: self.swapObject.destTokenPrice) > 0
            }
            if sortedRates.isEmpty {
                return
            }
            if let foundRate = sortedRates.first(where: { rate in
                rate.hint == self.swapObject.rate.hint
            }) {
                if foundRate.rate != self.swapObject.rate.rate {
                    self.newRate.value = foundRate
                }
                return
            } else {
                self.newRate.value = sortedRates.first!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateRate()
                }
            }
        }
    }
    
    func didConfirmSwap() {
        getLatestNonce { result in
            switch result {
            case .success(let nonce):
                self.buildTx(nonce: nonce)
            case .failure(let error):
                self.onTxFailed?(TxErrorParser.parse(error: error).message)
            }
        }
    }
    
}

// MARK: Tx related
extension SwapSummaryViewModel {
    
    func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
        let nodeService = EthereumNodeService(chain: AppState.shared.currentChain)
        nodeService.getTransactionCount(address: AppState.shared.currentAddress.addressString) { result in
            switch result {
            case .success(let res):
                AppDependencies.nonceStorage.updateNonce(chain: AppState.shared.currentChain, address: self.currentAddress.addressString, value: res)
                completion(.success(res))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func buildTx(nonce: Int) {
        let request = buildTxRequest(latestNonce: nonce)
        
        swapService.buildTx(chainPath: AppState.shared.currentChain.apiChainPath(), request: request) { [weak self] result in
            switch result {
            case .success(let txObject):
                self?.sendTransaction(txObject: txObject)
            case .failure(let error):
                self?.onTxFailed?(TxErrorParser.parse(error: error).message)
            }
        }
    }
    
    func buildTxRequest(latestNonce: Int) -> SwapBuildTxRequest {
        return SwapBuildTxRequest(
            userAddress: currentAddress.addressString,
            src: swapObject.sourceToken.address ,
            dest: swapObject.destToken.address,
            srcQty: swapObject.sourceAmount.description,
            minDesQty: minDestQty.description,
            gasPrice: self.gasPrice.description,
            nonce: latestNonce,
            hint: swapObject.rate.hint,
            useGasToken: false
        )
    }
    
    func sendTransaction(txObject: TxObject) {
        let chain = AppState.shared.currentChain
        TransactionManager.txProcessor.process(address: self.currentAddress, chain: chain, txObject: txObject, setting: self.settings.toCommonTxSettings()) { [weak self] txResult in
            guard let self = self else { return }
            switch txResult {
            case .success(let tx):
                let srcTokenAmount = NumberFormatUtils.amount(value: self.swapObject.sourceAmount, decimals: self.swapObject.sourceToken.decimals).toDouble() ?? 0
                let srcTokenAmountInUsd = srcTokenAmount * self.swapObject.sourceTokenPrice
                let destTokenAmount = NumberFormatUtils.amount(value: self.swapObject.rate.amount.bigInt ?? 0, decimals: self.swapObject.destToken.decimals).toDouble() ?? 0
                let destTokenAmountInUsd = destTokenAmount * self.swapObject.destTokenPrice
                let networkFeeUsd = self.getGasFeeUSD(estGas: BigInt(self.swapObject.rate.estGasConsumed ?? 0), gasPrice: self.gasPrice)
                let networkFeeValue = NumberFormatUtils.gasFee(value: networkFeeUsd).toDouble() ?? 0
                
                let trackingExtraData = SwapTrackingExtraData(srcToken: self.swapObject.sourceToken.symbol,
                                                              srcTokenAmount: srcTokenAmount,
                                                              srcTokenAmountUsd: srcTokenAmountInUsd,
                                                              destToken: self.swapObject.destToken.symbol,
                                                              destTokenAmount: destTokenAmount,
                                                              destTokenAmountUsd: destTokenAmountInUsd,
                                                              networkFee: networkFeeValue,
                                                              platform: self.swapObject.rate.platform)
                let pendingTx = PendingSwapTxInfo(sourceToken: self.swapObject.sourceToken,
                                                  destToken: self.swapObject.destToken,
                                                  rate: self.swapObject.rate,
                                                  sourceAmount: self.leftAmountString,
                                                  destAmount: self.rightAmountString,
                                                  legacyTx: tx.legacyTx,
                                                  eip1559Tx: tx.eip1559Tx,
                                                  chain: chain,
                                                  date: Date(),
                                                  hash: tx.hash,
                                                  detailString: self.displayEstimatedRate,
                                                  trackingExtraData: trackingExtraData)
                TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                self.onTxSendSuccess?(pendingTx)
            case .failure(let error):
                self.onTxFailed?(error.message)
            }
        }
    }
}
