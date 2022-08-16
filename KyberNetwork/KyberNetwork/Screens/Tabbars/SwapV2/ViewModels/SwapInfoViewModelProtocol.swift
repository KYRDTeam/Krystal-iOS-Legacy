//
//  SwapInfoViewModelProtocol.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/08/2022.
//

import Foundation
import BigInt

protocol SwapInfoViewModelProtocol {
  var settings: SwapTransactionSettings { get }
  var selectedRate: Rate? { get }
  var showRevertedRate: Bool { get }
}

extension SwapInfoViewModelProtocol {
  
  var isEIP1559: Bool {
    return KNGeneralProvider.shared.currentChain.isSupportedEIP1559()
  }
  
  var estimatedGas: BigInt {
    if let advanced = settings.advanced {
      return advanced.gasLimit
    } else if let rate = selectedRate {
      return BigInt(rate.estimatedGas)
    } else {
      return KNGasConfiguration.exchangeTokensGasLimitDefault
    }
  }
  
  var gasPrice: BigInt {
    if let basic = settings.basic {
      if isEIP1559 {
        let baseFee = KNGasCoordinator.shared.baseFee ?? .zero
        let priorityFee = self.getPriorityFee(forType: basic.gasPriceType) ?? .zero
        return baseFee + priorityFee
      } else {
        return self.getGasPrice(forType: basic.gasPriceType)
      }
    } else if let advanced = settings.advanced {
      if isEIP1559 {
        return advanced.maxFee + advanced.maxPriorityFee
      } else {
        return advanced.maxFee
      }
    }
    return KNGasCoordinator.shared.defaultKNGas
  }
  
  func getGasPrice(forType type: KNSelectedGasPriceType) -> BigInt {
    switch type {
    case .fast:
      return KNGasCoordinator.shared.fastKNGas
    case .medium:
      return KNGasCoordinator.shared.standardKNGas
    case .slow:
      return KNGasCoordinator.shared.lowKNGas
    case .superFast:
      return KNGasCoordinator.shared.superFastKNGas
    default: // No need to handle case .custom
      return KNGasCoordinator.shared.standardKNGas
    }
  }
  
  func getPriorityFee(forType type: KNSelectedGasPriceType) -> BigInt? {
    switch type {
    case .fast:
      return KNGasCoordinator.shared.fastPriorityFee
    case .medium:
      return KNGasCoordinator.shared.standardPriorityFee
    case .slow:
      return KNGasCoordinator.shared.lowPriorityFee
    case .superFast:
      return KNGasCoordinator.shared.superFastPriorityFee
    default: // No need to handle case .custom
      return KNGasCoordinator.shared.standardPriorityFee
    }
  }
  
  func getPriceImpactString(rate: Rate) -> String {
    let change = Double(rate.priceImpact) / 10000
    return StringFormatter.percentString(value: change)
  }
  
  func getMinReceiveString(destToken: Token, rate: Rate) -> String {
    let amount = BigInt(rate.amount) ?? BigInt(0)
    let minReceivingAmount = amount * BigInt(10000.0 - settings.slippage * 100.0) / BigInt(10000.0)
    return "\(NumberFormatUtils.amount(value: minReceivingAmount, decimals: destToken.decimals)) \(destToken.symbol)"
  }
  
  func getEstimatedNetworkFeeString(rate: Rate) -> String {
    let feeInUSD = self.getGasFeeUSD(estGas: BigInt(rate.estGasConsumed ?? 0), gasPrice: self.gasPrice)
    if let basic = settings.basic {
      let typeString: String = {
        switch basic.gasPriceType {
        case .superFast:
          return Strings.superFast
        case .fast:
          return Strings.fast
        case .medium:
          return Strings.regular
        case .slow:
          return Strings.slow
        case .custom:
          return Strings.custom
        }
      }()
      return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18)) • \(typeString)"
    }
    let typeString = Strings.custom
    return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18)) • \(typeString)"
  }
  
  func getMaxNetworkFeeString(rate: Rate) -> String {
    if settings.basic != nil {
      let feeInUSD = self.getGasFeeUSD(estGas: estimatedGas, gasPrice: gasPrice)
      return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18))"
    } else if let advanced = settings.advanced {
      let feeInUSD = self.getGasFeeUSD(estGas: estimatedGas, gasPrice: advanced.maxFee)
      return "$\(NumberFormatUtils.usdAmount(value: feeInUSD, decimals: 18))"
    }
    return ""
  }
  
  func getGasFeeUSD(estGas: BigInt, gasPrice: BigInt) -> BigInt {
    let decimals = KNGeneralProvider.shared.quoteTokenObject.decimals
    let rateUSDDouble = KNGeneralProvider.shared.quoteTokenPrice?.usd ?? 0
    let rateBigInt = BigInt(rateUSDDouble * pow(10.0, Double(decimals)))
    let feeUSD = (estGas * gasPrice * rateBigInt) / BigInt(10).power(decimals)
    return feeUSD
  }
  
  func getPriceImpactState(change: Double) -> PriceImpactState {
    if -5 < change && change <= 100 {
      return .normal
    }
    if -15 < change && change <= -5 {
      return .high
    }
    return .veryHigh
  }
  
  func getRateString(sourceToken: Token, destToken: Token) -> String? {
    guard let selectedPlatform = selectedRate else {
      return nil
    }
    if showRevertedRate {
      let rate = BigInt(selectedPlatform.rate) ?? .zero
      let revertedRate = rate.isZero ? 0 : (BigInt(10).power(36) / rate)
      let rateString = NumberFormatUtils.rate(value: revertedRate, decimals: 18)
      return "1 \(destToken.symbol) = \(rateString) \(sourceToken.symbol)"
    } else {
      let rateString = NumberFormatUtils.rate(value: BigInt(selectedPlatform.rate) ?? .zero, decimals: 18)
      return "1 \(sourceToken.symbol) = \(rateString) \(destToken.symbol)"
    }
  }
  
}
