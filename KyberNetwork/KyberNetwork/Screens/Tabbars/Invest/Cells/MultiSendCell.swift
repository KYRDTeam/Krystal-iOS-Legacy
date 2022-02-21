//
//  MultiSendCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import UIKit
import SwipeCellKit
import TrustCore
import BigInt

enum MultiSendCellEvent {
  case add
  case searchToken(selectedToken: Token, cellIndex: Int)
  case updateAmount(amount: BigInt, selectedToken: Token)
  case qrCode(cellIndex: Int)
  case openContact(cellIndex: Int)
  case addContact(address: String)
}

protocol MultiSendCellDelegate: class {
  func multiSendCell(_ cell: MultiSendCell, run event: MultiSendCellEvent)
}

class MultiSendCellModel {
  var index: Int = 0
  var addButtonEnable: Bool = true
  var amount: String = ""
  var addressString: String = ""
  var address: Address?
  var from: Token = KNGeneralProvider.shared.quoteTokenObject.toToken()
  var availableAmount: BigInt = BigInt.zero
  var isSendAllBalanace: Bool = false // Use for update amount when change gasfee
  var gasFee: BigInt = BigInt.zero
  
  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
  }
  
  func updateAddress(_ address: String) {
    self.addressString = address
    self.address = Address(string: address)
  }

  var amountTextColor: UIColor {
    return .white
  }

  var displayBalance: String {
    let balance = self.availableAmount
    let string = balance.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 5)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var totalBalanceText: String {
    return "\(self.displayBalance) \(self.from.symbol)"
  }

  var amountBigInt: BigInt {
    return amount.amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var allTokenBalanceString: String {
    if self.from.isQuoteToken {
      let balance = availableAmount
      let availableValue = max(BigInt(0), balance - self.gasFee)
      let string = availableValue.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance.removeGroupSeparator()
  }

  var isContractExist: Bool {
    let contact = KNContactStorage.shared.contacts.first(where: { return self.addressString.lowercased() == $0.address.lowercased() })
    return contact != nil
  }

  var isAddressValid: Bool {
    let address = Address(string: self.addressString)
    return address != nil
  }
  
  var isBalanceVaild: Bool {
    return self.amountBigInt <= self.availableAmount
  }
  
  var isCellFormValid: ValidStatus {
    if !self.isAddressValid {
      return .error(description: "Address isn't correct")
    }
    if !self.isBalanceVaild {
      return .error(description: "Balance is not be enough to make the transaction.")
    }
    return .success
  }
}

class MultiSendCell: SwipeTableViewCell {
  
  @IBOutlet weak var addContactButton: UIButton!
  @IBOutlet weak var contactButton: UIButton!
  @IBOutlet weak var qrButton: UIButton!
  @IBOutlet weak var addressFieldRightSpaceContraint: NSLayoutConstraint!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var currentTokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var separatorView: UIView!
  weak var cellDelegate: MultiSendCellDelegate?

  static let cellHeight: CGFloat = 184
  static let cellID: String = "MultiSendCell"
  
  var cellModel: MultiSendCellModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.amountTextField.delegate = self
    self.addressTextField.delegate = self
    self.separatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }
  
  func updateCellModel(_ model: MultiSendCellModel) {
    if model.addButtonEnable {
      self.addButton.setImage(UIImage(named: "add_send_active_icon"), for: .normal)
    } else {
      self.addButton.setImage(UIImage(named: "add_send_inactive_icon"), for: .normal)
    }
    self.addressTextField.text = model.addressString
    self.amountTextField.text = model.amount
    self.currentTokenButton.setTitle(model.from.symbol, for: .normal)
    self.tokenBalanceLabel.text = model.totalBalanceText
    
    self.cellModel = model
    self.updateUIAddressField()
  }
  
  private func updateUIAddressField() {
    let isEmpty = self.addressTextField.text?.isEmpty ?? true
    self.qrButton.isHidden = !isEmpty
    self.contactButton.isHidden = !isEmpty
    self.addressFieldRightSpaceContraint.constant = isEmpty ? 72 : 8
    if isEmpty {
      self.addContactButton.isHidden = true
    } else {
      if self.cellModel?.isAddressValid == true {
        self.addContactButton.isHidden = (self.cellModel?.isContractExist ?? false)
      } else {
        self.addContactButton.isHidden = true
      }
    }
  }
  
  @IBAction func addButtonTapped(_ sender: UIButton) {
    guard self.cellModel?.addButtonEnable == true else { return }
    self.cellDelegate?.multiSendCell(self, run: .add)
  }
  
  @IBAction func tokenButtonTapped(_ sender: UIButton) {
    self.cellDelegate?.multiSendCell(self, run: .searchToken(selectedToken: self.cellModel?.from ?? KNGeneralProvider.shared.quoteTokenObject.toToken(), cellIndex: self.cellModel?.index ?? 0))
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    self.cellModel?.isSendAllBalanace = true
    self.amountTextField.text = self.cellModel?.allTokenBalanceString.removeGroupSeparator()
    self.cellModel?.updateAmount(self.amountTextField.text ?? "", forSendAllETH: self.cellModel?.from.isQuoteToken ?? false)
    self.amountTextField.resignFirstResponder()
    self.amountTextField.textColor = self.cellModel?.amountTextColor
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.cellDelegate?.multiSendCell(self, run: .qrCode(cellIndex: self.cellModel?.index ?? 0))
  }
  
  @IBAction func contactButtonTapped(_ sender: UIButton) {
    self.cellDelegate?.multiSendCell(self, run: .openContact(cellIndex: self.cellModel?.index ?? 0))
  }
  
  @IBAction func addContactButtonTapped(_ sender: UIButton) {
    guard let address = self.cellModel?.addressString, !address.isEmpty else { return }
    self.cellDelegate?.multiSendCell(self, run: .addContact(address: address))
  }
  
}

extension MultiSendCell: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.cellModel?.updateAmount("")
    } else {
      self.cellModel?.updateAddress("")
    }
    self.cellModel?.isSendAllBalanace = false
    return false
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

    let cleanedText = text.cleanStringToNumber()
    if textField == self.amountTextField, cleanedText.amountBigInt(decimals: self.cellModel?.from.decimals ?? 18) == nil { return false }
    if textField == self.amountTextField {
      textField.text = cleanedText
      self.cellModel?.updateAmount(cleanedText)
    } else {
      textField.text = text
      self.cellModel?.updateAddress(text)
    }
    
    return false
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.amountTextField.textColor = UIColor.white
    self.cellModel?.isSendAllBalanace = false
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.cellModel?.amountTextColor
    self.cellDelegate?.multiSendCell(self, run: .updateAmount(amount: self.cellModel?.amountBigInt ?? BigInt.zero, selectedToken: self.cellModel?.from ?? KNGeneralProvider.shared.quoteTokenObject.toToken()))
    self.updateUIAddressField()
  }
}
