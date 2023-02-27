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
import Services
import AppState
import TransactionModule

class SwapSummaryViewModel: SwapInfoViewModelProtocol {
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
  var internalHistoryTransaction: Observable<InternalHistoryTransaction?> = .init(nil)
  var newRate: Observable<Rate?> = .init(nil)
  var error: Observable<String?> = .init(nil)
  var shouldDiplayLoading: Observable<Bool?> = .init(nil)
  var priceImpactState: Observable<PriceImpactState> = .init(.normal)
  var onUpdateRate: ((Rate) -> ())?

  var showRevertedRate: Bool {
    didSet {
      self.rateString.value = self.getRateString(sourceToken: swapObject.sourceToken, destToken: swapObject.destToken)
    }
  }
    
    var l1Fee: BigInt = BigInt(0) {
        didSet {
            self.updateInfo()
        }
    }
  
  var minRatePercent: Double {
    didSet {
      self.slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    }
  }
  
  var session: KNSession {
    return AppDelegate.session
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
    
  var currentChain: ChainType {
    return AppState.shared.currentChain
  }
  
  var toAmount: BigInt {
    return BigInt(swapObject.rate.amount) ?? BigInt(0)
  }
  
  var minDestQty: BigInt {
    return self.toAmount * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }
    
    var leftAmountValueString: String {
        let amountString = NumberFormatUtils.amount(value: swapObject.sourceAmount, decimals: swapObject.sourceToken.decimals)
        return String(amountString.prefix(15))
    }

  var leftAmountString: String {
    return "\(leftAmountValueString) \(swapObject.sourceToken.symbol)"
  }
    
    var rightAmountValueString: String {
        let receivedAmount = swapObject.rate.amount.bigInt ?? BigInt(0)
        let amountString = NumberFormatUtils.amount(value: receivedAmount, decimals: swapObject.destToken.decimals)
        return String(amountString.prefix(15))
    }
    
  var rightAmountString: String {
    
    return "\(rightAmountValueString) \(swapObject.destToken.symbol)"
  }
  
  var displayEstimatedRate: String {
    let rateString = swapObject.rate.rate
    return "1 \(swapObject.sourceToken.symbol) = \(rateString) \(swapObject.destToken.symbol)"
  }
  
  fileprivate var updateRateTimer: Timer?
  let swapRepository = SwapRepository()

  init(swapObject: SwapObject) {
    self.swapObject = swapObject
    self.showRevertedRate = swapObject.showRevertedRate
    self.minRatePercent = swapObject.swapSetting.slippage
  }
  
  func updateData() {
    rateString.value = getRateString(sourceToken: swapObject.sourceToken, destToken: swapObject.destToken)
    minReceiveString.value = calculateMinReceiveString(rate: swapObject.rate)
    estimatedGasFeeString.value = getEstimatedNetworkFeeString(rate: swapObject.rate, l1Fee: l1Fee)
    priceImpactString.value = getPriceImpactString(rate: swapObject.rate)
    priceImpactState.value = getPriceImpactState(change: Double(swapObject.rate.priceImpact) / 100)
    maxGasFeeString.value = getMaxNetworkFeeString(rate: swapObject.rate, l1Fee: l1Fee)
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
    self.estimatedGasFeeString.value = self.getEstimatedNetworkFeeString(rate: swapObject.rate, l1Fee: l1Fee)
    self.maxGasFeeString.value = self.getMaxNetworkFeeString(rate: swapObject.rate, l1Fee: l1Fee)
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
    
    var sourceAmountUsd: String {
        let amountUSD = swapObject.sourceAmount * BigInt(swapObject.sourceTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(swapObject.sourceToken.decimals)
        let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
        return formattedAmountUSD
    }

  func getSourceAmountUsdString() -> String {
    return "~$\(sourceAmountUsd)"
  }
  
  func getDestAmountString() -> String {
    let receivingAmount = BigInt(swapObject.rate.amount) ?? BigInt(0)
    return NumberFormatUtils.balanceFormat(value: receivingAmount, decimals: swapObject.destToken.decimals)
  }
    
    
    var destAmountUsd: String {
        let receivingAmount = BigInt(swapObject.rate.amount) ?? BigInt(0)
        let amountUSD = receivingAmount * BigInt(swapObject.destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(swapObject.destToken.decimals)
        let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
        return formattedAmountUSD
    }
    
  func getDestAmountUsdString() -> String {
    return "~$\(destAmountUsd)"
  }
  
  func startUpdateRate() {
    self.updateRateTimer?.invalidate()
    self.fetchData()
    self.updateRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds15,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.fetchData()
      }
    )
  }

  func fetchData() {
    swapRepository.getAllRates(address: currentAddress.addressString, srcTokenContract: self.swapObject.sourceToken.address.lowercased(), destTokenContract: self.swapObject.destToken.address.lowercased(), amount: self.swapObject.sourceAmount, focusSrc: true) { [weak self] rates in
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
    updateTxData { _ in
    }
  }
  
  func didConfirmSwap() {
    self.updateTxData { txObject in
        if KNGeneralProvider.shared.isUseEIP1559 {
            guard let signTx = self.buildEIP1559Tx(txObject) else { return }
            self.getEstimateGasLimit(txEIP1559: signTx, tx: nil)
        } else {
            guard let signTx = self.buildSignSwapTx(txObject) else { return }
            self.getEstimateGasLimit(txEIP1559: nil, tx: signTx)
        }
    }
  }

  func showError(errorMsg: String) {
    UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.showErrorTopBannerMessage(message: errorMsg)
  }
  
  func showLoading() {
    self.shouldDiplayLoading.value = true
  }
}

extension SwapSummaryViewModel {

  fileprivate func updateTxData(completion: @escaping (TxObject) -> Void) {
    TransactionManager.txProcessor.getLatestNonce(address: currentAddress, chain: currentChain) { nonce in
      guard let nonce = nonce else {
          return
      }
      self.buildTx(latestNonce: nonce, completion: completion)
    }
  }
  
  func buildTx(latestNonce: Int, completion: @escaping (TxObject) -> Void) {
    guard let tx = buildRawSwapTx(latestNonce: latestNonce) else {
      self.showError(errorMsg: Strings.buildRawTxFailed)
      return
    }
    self.swapRepository.buildTx(tx: tx) { data in
        self.swapRepository.getL1FeeForTxIfHave(object: data.txObject) { l1Fee, object in
            self.l1Fee = l1Fee
            completion(object)
        }
    }
  }
  
  func buildRawSwapTx(latestNonce: Int) -> RawSwapTransaction? {
    return RawSwapTransaction(
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
  
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    self.internalHistoryTransaction.value = transaction
  }
  
  func sendSignedTransactionDataToNode(data: Data, nonce: Int, internalHistoryTransaction: InternalHistoryTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    self.showLoading()
    KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
      DispatchQueue.main.async {
        self.shouldDiplayLoading.value = false
      }
      switch sendResult {
      case .success(let hash):
        provider.minTxCount += 1

        internalHistoryTransaction.hash = hash
        internalHistoryTransaction.nonce = nonce
        internalHistoryTransaction.time = Date()

        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
        self.openTransactionStatusPopUp(transaction: internalHistoryTransaction)
      case .failure(let error):
        var errorMessage = error.description
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.showError(errorMsg: errorMessage)
      }
    })
  }

  func getEstimateGasLimit(txEIP1559: EIP1559Transaction?, tx: SignTransaction?) {
    if let txEIP1559 = txEIP1559 {
      self.showLoading()
      KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: txEIP1559) { (result) in
        DispatchQueue.main.async {
          self.shouldDiplayLoading.value = false
        }
        switch result {
        case .success:
          let internalHistory = InternalHistoryTransaction(type: .swap, state: .pending, fromSymbol: self.swapObject.sourceToken.symbol, toSymbol: self.swapObject.destToken.symbol, transactionDescription: "\(self.leftAmountString) → \(self.rightAmountString)", transactionDetailDescription: self.displayEstimatedRate, transactionObj: nil, eip1559Tx: txEIP1559)
          internalHistory.transactionSuccessDescription = "\(self.leftAmountString) → \(self.rightAmountString)"
          if let data = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: txEIP1559) {
            let nonce = Int(txEIP1559.nonce, radix: 16) ?? 0
            self.sendSignedTransactionDataToNode(data: data, nonce: nonce, internalHistoryTransaction: internalHistory)
          }
            
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          self.showError(errorMsg: errorMessage)
        }
      }
    } else if let tx = tx {
      self.showLoading()
      KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { (result) in
        DispatchQueue.main.async {
          self.shouldDiplayLoading.value = false
        }
        switch result {
        case .success:
          let internalHistory = InternalHistoryTransaction(type: .swap, state: .pending, fromSymbol: self.swapObject.sourceToken.symbol, toSymbol: self.swapObject.destToken.symbol, transactionDescription: "\(self.leftAmountString) → \(self.rightAmountString)", transactionDetailDescription: self.displayEstimatedRate, transactionObj: tx.toSignTransactionObject(), eip1559Tx: nil)
          internalHistory.transactionSuccessDescription = "\(self.leftAmountString) → \(self.rightAmountString)"
          let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: tx)
          switch signResult {
          case .success(let signedData):
            let nonce = tx.nonce
            self.sendSignedTransactionDataToNode(data: signedData, nonce: nonce, internalHistoryTransaction: internalHistory)
          case .failure:
            self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
          }
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
            
            if case let JSONRPCKit.JSONRPCError.missingBothResultAndError(errDic as [String: Any]) = apiKitError {
              if let errData = errDic["error"] as? [String: Any], let errMsg = errData["message"] as? String {
                errorMessage = errMsg
              }
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          if errorMessage.lowercased().contains("gas required exceeds allowance".lowercased()) {
            errorMessage = String(format: Strings.insufficientTokenForNetworkFee, KNGeneralProvider.shared.quoteTokenObject.symbol)
          }
            self.showError(errorMsg: errorMessage)
        }
      }
    }
  }
  
  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      var gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      var nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    if let advance = swapObject.swapSetting.advanced {
      gasLimit = advance.gasLimit
      gasPrice = advance.maxFee
      nonce = advance.nonce
    }

    if currentAddress.isWatchWallet {
      return nil
    }
    return SignTransaction(
      value: value,
      address: currentAddress.addressString,
      to: object.to,
      nonce: nonce,
      data: Data(hex: object.data.drop0x),
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
  
  func buildEIP1559Tx(_ object: TxObject) -> EIP1559Transaction? {
    let gasLimitDefault = BigInt(object.gasLimit.drop0x, radix: 16) ?? self.gasLimit
    let gasPrice = BigInt(object.gasPrice.drop0x, radix: 16) ?? self.gasPrice
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = object.nonce.hexSigned2Complement
    if let nonceInt = swapObject.swapSetting.advanced?.nonce {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    if let advance = swapObject.swapSetting.advanced {
      let gasLimit = advance.gasLimit
      let priorityFee = advance.maxPriorityFee
      let maxGasFee = advance.maxFee
      
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    } else if let basic = swapObject.swapSetting.basic {
      let priorityFeeBigIntDefault = getPriorityFee(forType: basic.gasPriceType) ?? BigInt(0)
      
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    }
    return nil
  }
}
