//
//  PendingHistoryTransactonViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit

class PendingHistoryTransactonViewModel: AbstractHistoryTransactionViewModel {
  let transaction: Transaction
  let ownerAddress: String
  let ownerWalletName: String

  init(
    transaction: Transaction,
    ownerAddress: String,
    ownerWalletName: String,
  ) {
    self.transaction = transaction
    self.ownerAddress = ownerAddress
    self.ownerWalletName = ownerWalletName
  }
  
  var isSwap: Bool { return self.transaction.localizedOperations.first?.type == "exchange" }
  var isSent: Bool {
    if self.isSwap { return false }
    return self.transaction.from.lowercased() == self.ownerAddress.lowercased()
  }

  var isAmountTransactionHidden: Bool {
    return self.transaction.state == .error || self.transaction.state == .failed
  }

  var isError: Bool {
    if self.transaction.state == .error || self.transaction.state == .failed {
      return true
    }
    return false
  }

  var isContractInteraction: Bool {
    if !self.transaction.input.isEmpty && self.transaction.input != "0x" {
      return true
    }
    return false
  }

  var isSelf: Bool {
    return self.transaction.from.lowercased() == self.transaction.to.lowercased()
  }

  var transactionStatusString: String {
    if isError { return NSLocalizedString("failed", value: "Failed", comment: "") }
    return ""
  }

  var transactionTypeString: String {
    let typeString: String = {
      if self.isSelf { return "Self" }
      if self.isContractInteraction && self.isError { return "Contract Interaction".toBeLocalised() }
      if self.isSwap { return NSLocalizedString("swap", value: "Swap", comment: "") }
      return self.isSent ? NSLocalizedString("transfer", value: "Transfer", comment: "") : NSLocalizedString("receive", value: "Receive", comment: "")
    }()
    return typeString
  }

  var transactionTypeImage: UIImage {
    let typeImage: UIImage = {
      if self.isSelf { return UIImage(named: "history_send_icon")! }
      if self.isContractInteraction && self.isError { return UIImage(named: "history_contract_interaction_icon")! }
      if self.isSwap { return UIImage() }
      return self.isSent ? UIImage(named: "history_send_icon")! : UIImage(named: "history_receive_icon")!
    }()
    return typeImage
  }

  var transactionDetailsString: String {
    if self.isSwap { return self.displayedExchangeRate ?? "" }
    if self.isSent {
      return NSLocalizedString("To", value: "To", comment: "") + ": \(self.transaction.to.prefix(12))...\(self.transaction.to.suffix(8))"
    }
    return NSLocalizedString("From", value: "From", comment: "") + ": \(self.transaction.from.prefix(12))...\(self.transaction.from.suffix(8))"
  }

  let normalTextAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.foregroundColor: UIColor(red: 182, green: 186, blue: 185),
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.kern: 0.0,
  ]

  let highlightedTextAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.kern: 0.0,
  ]

  var descriptionLabelAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    if self.isSwap {
      let name: String = self.ownerWalletName.formatName(maxLen: 10)
      attributedString.append(NSAttributedString(string: name, attributes: highlightedTextAttributes))
      attributedString.append(NSAttributedString(string: "\n\(self.ownerAddress.prefix(6))....\(self.ownerAddress.suffix(4))", attributes: normalTextAttributes))
      return attributedString
    }

    let fromText: String = {
      if self.isSent { return self.ownerWalletName }
      return "\(self.transaction.from.prefix(8))....\(self.transaction.from.suffix(6))"
    }()
    let toText: String = {
      if self.isSent {
        return "\(self.transaction.to.prefix(8))....\(self.transaction.to.suffix(6))"
      }
      return self.ownerWalletName.formatName(maxLen: 32)
    }()
    attributedString.append(NSAttributedString(string: "\(NSLocalizedString("from", value: "From", comment: "")) ", attributes: normalTextAttributes))
    attributedString.append(NSAttributedString(string: fromText, attributes: highlightedTextAttributes))
    attributedString.append(NSAttributedString(string: "\n\(NSLocalizedString("to", value: "To", comment: "")) ", attributes: normalTextAttributes))
    attributedString.append(NSAttributedString(string: toText, attributes: highlightedTextAttributes))
    return attributedString
  }

  var displayedAmountString: String {
    return self.transaction.displayedAmountString(curWallet: self.ownerAddress)
  }

  var displayedExchangeRate: String? {
    return self.transaction.displayedExchangeRate
  }

  var fromIconSymbol: String {
    guard let from = self.transaction.localizedOperations.first?.from, let fromToken = KNSupportedTokenStorage.shared.getTokenWith(address: from) else {
      return ""
    }
    return fromToken.symbol
  }

  var toIconSymbol: String {
    guard let to = self.transaction.localizedOperations.first?.to, let toToken = KNSupportedTokenStorage.shared.getTokenWith(address: to) else {
      return ""
    }
    return toToken.symbol
  }
  
  var displayTime: String {
    return ""
  }
}
