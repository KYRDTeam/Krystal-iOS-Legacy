// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

class SpeedUpCustomGasSelectViewModel {
  fileprivate(set) var selectedType: KNSelectedGasPriceType = .superFast
  fileprivate(set) var fast: BigInt
  fileprivate(set) var medium: BigInt
  fileprivate(set) var slow: BigInt
  fileprivate(set) var superFast: BigInt
  let transaction: InternalHistoryTransaction
  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
    if KNGeneralProvider.shared.isUseEIP1559 {
      self.fast = KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)
      self.medium = KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
      self.slow = KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
      self.superFast = KNGasCoordinator.shared.superFastPriorityFee ?? BigInt(0)
    } else {
      self.fast = KNGasCoordinator.shared.fastKNGas
      self.medium = KNGasCoordinator.shared.standardKNGas
      self.slow = KNGasCoordinator.shared.lowKNGas
      self.superFast = KNGasCoordinator.shared.superFastKNGas
    }
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    self.fast = fast
    self.medium = medium
    self.slow = slow
    self.superFast = superFast
  }

  var fastGasString: NSAttributedString {
    return self.attributedString(
      for: self.fast,
      text: NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    )
  }

  var mediumGasString: NSAttributedString {
    return self.attributedString(
      for: self.medium,
      text: NSLocalizedString("regular", value: "Regular", comment: "").uppercased()
    )
  }

  var slowGasString: NSAttributedString {
    return self.attributedString(
      for: self.slow,
      text: NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
    )
  }

  var superFastGasString: NSAttributedString {
    return self.attributedString(
      for: self.superFast,
      text: NSLocalizedString("super.fast", value: "Super Fast", comment: "").uppercased()
    )
  }

  var estimateFeeSuperFastString: String {
    return self.formatFeeStringFor(gasPrice: self.superFast)
  }

  var estimateFeeFastString: String {
    return self.formatFeeStringFor(gasPrice: self.fast)
  }

  var estimateRegularFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.medium)
  }

  var estimateSlowFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.slow)
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee: BigInt? = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        guard let gasLimit = BigInt(self.transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16) else { return nil }
        return gasPrice * gasLimit
      } else {
        guard let gasLimit = BigInt(self.transaction.transactionObject?.gasLimit ?? "") else { return nil }
        return gasPrice * gasLimit
      }
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "~ \(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      NSAttributedString.Key.font: UIFont.Kyber.latoBold(with: 12),
      NSAttributedString.Key.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 10),
      NSAttributedString.Key.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: " \(text)", attributes: feeAttributes))
    return attributedString
  }

  var currentTransactionFeeETHString: String {
    let fee: BigInt? = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        guard let gasPrice = BigInt(self.transaction.eip1559Transaction?.maxGasFee.drop0x ?? "", radix: 16),
              let gasLimit = BigInt(self.transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16)
          else { return nil }
        return gasPrice * gasLimit
      } else {
        guard let gasPrice = BigInt(self.transaction.transactionObject?.gasPrice ?? ""),
          let gasLimit = BigInt(self.transaction.transactionObject?.gasLimit ?? "")
          else { return nil }
        return gasPrice * gasLimit
      }
      
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getNewTransactionFeeETHString() -> String {
    let fee = getNewTransactionFeeETH()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getNewTransactionGasPriceETH() -> BigInt { //TODO: check again formular 1.2 * current
    let gasPrice: BigInt = {
      switch selectedType {
      case .fast: return fast
      case .medium: return medium
      case .slow: return slow
      case .superFast: return superFast
      default: return BigInt(0)
      }
    }()
    return gasPrice
  }

  func getNewTransactionFeeETH() -> BigInt {
    let gasPrice = getNewTransactionGasPriceETH()
    let fee: BigInt? = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        guard let gasLimit = BigInt(self.transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16) else { return nil }
        return gasPrice * gasLimit
      } else {
        guard let gasLimit = BigInt(self.transaction.transactionObject?.gasLimit ?? "") else { return nil }
        return gasPrice * gasLimit
      }
    }()
    return fee ?? BigInt(0)
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func isNewGasPriceValid() -> Bool {
    let newValue = getNewTransactionGasPriceETH()

    let oldValue: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(self.transaction.eip1559Transaction?.maxGasFee.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(self.transaction.transactionObject?.gasPrice ?? "") ?? BigInt(0)
      }
    }()
    return newValue > ( oldValue * BigInt(11) / BigInt (10) )
  }
  
  var navigationTitle: String {
    return KNGeneralProvider.shared.isUseEIP1559 ? "Customize priority fee" : "Customize Gas".toBeLocalised()
  }
  
  var mainTextTitle: String {
    return KNGeneralProvider.shared.isUseEIP1559 ? "Select higher priority fee to speed up your transaction." : "Select.higher.tx.fee.to.accelerate".toBeLocalised()
  }
  
  var gasPriceWarningText: String {
    return KNGeneralProvider.shared.isUseEIP1559 ? "Your priority fee must be 10% higher than current priority fee" : "your.gas.must.be.10.percent.higher".toBeLocalised()
  }
  
  var currentFeeTitle: String {
    return KNGeneralProvider.shared.isUseEIP1559 ? "Current priority fee" : "Current fee".toBeLocalised()
  }
  
  var newFeeTitle: String {
    return KNGeneralProvider.shared.isUseEIP1559 ? "New priority fee" : "New fee".toBeLocalised()
  }
}
