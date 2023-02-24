//
//  MultiSendCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import UIKit
import SwipeCellKit
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

struct MultiSendCellModelStorage: Codable {
  let index: Int
  let addButtonEnable: Bool
  let amount: String
  let addressString: String
  let from: Token
  let availableAmount: String
  let isSendAllBalanace: Bool
  let gasFee: String
}

class MultiSendCellModel {
  var index: Int = 0
  var addButtonEnable: Bool = true
  var amount: String = ""
  var addressString: String = ""
  var from: Token = Token.blankToken()
  var availableAmount: BigInt = BigInt.zero
  var isSendAllBalanace: Bool = false // Use for update amount when change gasfee
  var gasFee: BigInt = BigInt.zero
  var needValidation: Bool = false
  
  init() {}
  
  init(_ object: MultiSendCellModelStorage) {
    self.index = object.index
    self.addButtonEnable = object.addButtonEnable
    self.amount = object.amount
    self.addressString = object.addressString
    self.from = object.from
    self.availableAmount = BigInt(object.availableAmount) ?? BigInt.zero
    self.isSendAllBalanace = object.isSendAllBalanace
    self.gasFee = BigInt(object.gasFee) ?? BigInt.zero
  }
  
  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
  }
  
  func updateAddress(_ address: String) {
    self.addressString = address
  }

  var amountTextColor: UIColor {
    return .white
  }
  
  var storageObject: MultiSendCellModelStorage {
    return MultiSendCellModelStorage(index: self.index, addButtonEnable: self.addButtonEnable, amount: self.amount, addressString: self.addressString, from: self.from, availableAmount: self.availableAmount.description, isSendAllBalanace: self.isSendAllBalanace, gasFee: self.gasFee.description)
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
    guard !self.from.isBlank() else { return "" }
    return "\(self.displayBalance) \(self.from.symbol)"
  }

  var amountBigInt: BigInt {
    return amount.amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var allTokenBalanceString: String {
    if self.from.isQuoteToken() {
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
    guard self.addressString.has0xPrefix else { return false }
    return KNGeneralProvider.shared.isAddressValid(address: self.addressString)
  }
  
  var isBalanceVaild: Bool {
    return self.availableAmount >= 0
  }
  
  var isBalanceTooLow: Bool {
    return self.amountBigInt <= BigInt.zero
  }
  
  var isCellFormValid: ValidStatus {
    if !self.isAddressValid {
      return .error(description: "Invalid address")
    }
    if self.from.address.isEmpty {
      return .error(description: "Please select an token to continue")
    }
    if self.isBalanceTooLow {
      return .error(description: "Please enter an amount to continue")
    }
    if !self.isBalanceVaild {
      return .error(description: "Balance is not be enough to make the transaction.")
    }
    return .success
  }
    
    func buildExtraData() -> [String: String] {
        return [
            "token": from.symbol,
            "destAddress": addressString,
            "amount": displayBalance
        ]
    }
}

class MultiSendCell: SwipeTableViewCell {
  
//  @IBOutlet weak var maxButton: UIButton!
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
  @IBOutlet weak var addressContainerView: UIView!
  @IBOutlet weak var amountContainerView: UIView!
  
  var keyboardTimer: Timer?
  weak var cellDelegate: MultiSendCellDelegate?

  static let cellHeight: CGFloat = 184
  static let cellID: String = "MultiSendCell"
  
  var cellModel: MultiSendCellModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.amountTextField.delegate = self
    self.addressTextField.delegate = self
    self.separatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)

    self.addressTextField.setupCustomDeleteIcon()
    self.amountTextField.setupCustomDeleteIcon()
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
    if model.from.isBlank() {
      self.currentTokenButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
//      self.maxButton.isHidden = true
    } else {
      self.currentTokenButton.setTitleColor(UIColor(named: "textWhiteColor"), for: .normal)
//      self.maxButton.isHidden = false
    }
    self.tokenBalanceLabel.text = model.totalBalanceText
    
    self.cellModel = model
    self.updateUIAddressField()
    self.updateUIForValidation()
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
  
  func updateUIForValidation() {
    guard let unwrap = self.cellModel, unwrap.needValidation else {
      self.addressContainerView.rounded(color: UIColor.clear, radius: 16)
      self.amountContainerView.rounded(color: UIColor.clear, radius: 16)
      return
    }
    if !unwrap.isAddressValid {
      self.addressContainerView.rounded(color: UIColor.Kyber.red, width: 1, radius: 16)
    } else {
      self.addressContainerView.rounded(color: UIColor.clear, radius: 16)
    }
    
    if unwrap.isBalanceTooLow || !unwrap.isBalanceVaild {
      self.amountContainerView.rounded(color: UIColor.Kyber.red, width: 1, radius: 16)
    } else {
      self.amountContainerView.rounded(color: UIColor.clear, radius: 16)
    }
  }

  @IBAction func addButtonTapped(_ sender: UIButton) {
    guard self.cellModel?.addButtonEnable == true else { return }
    self.cellDelegate?.multiSendCell(self, run: .add)
  }
  
  @IBAction func tokenButtonTapped(_ sender: UIButton) {
    self.cellDelegate?.multiSendCell(self, run: .searchToken(selectedToken: self.cellModel?.from ?? KNGeneralProvider.shared.quoteTokenObject.toToken(), cellIndex: self.cellModel?.index ?? 0))
  }
  
//  @IBAction func maxButtonTapped(_ sender: UIButton) {
//    self.cellModel?.isSendAllBalanace = true
//    self.amountTextField.text = self.cellModel?.allTokenBalanceString.removeGroupSeparator()
//    self.cellModel?.updateAmount(self.amountTextField.text ?? "", forSendAllETH: self.cellModel?.from.isQuoteToken ?? false)
//    self.amountTextField.resignFirstResponder()
//    self.amountTextField.textColor = self.cellModel?.amountTextColor
//  }
  
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
    if textField == self.amountTextField, cleanedText.amountBigInt(decimals: self.cellModel?.from.decimals ?? 18) == nil {
      self.showErrorTopBannerMessage(message: "Invalid input amount, please input number with \(self.cellModel?.from.decimals ?? 18) decimal places")
      return false
    }
    if textField == self.amountTextField {
      textField.text = cleanedText
      self.cellModel?.updateAmount(cleanedText)
      return false
    } else {
      self.cellModel?.updateAddress(text)
      
      self.keyboardTimer?.invalidate()
      self.keyboardTimer = Timer.scheduledTimer(
              timeInterval: 1,
              target: self,
              selector: #selector(MultiSendCell.keyboardPauseTyping),
              userInfo: ["textField": textField],
              repeats: false)
      return true
    }
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.amountTextField.textColor = UIColor.white
    self.cellModel?.isSendAllBalanace = false
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.cellModel?.amountTextColor
    self.cellDelegate?.multiSendCell(self, run: .updateAmount(amount: self.cellModel?.amountBigInt ?? BigInt.zero, selectedToken: self.cellModel?.from ?? KNGeneralProvider.shared.quoteTokenObject.toToken()))
    self.updateUIAddressField()
    MixPanelManager.track("multisend_enter_amount", properties: ["screenid": "multi_send", "send_amount": (cellModel?.amount ?? "N/a"), "send_token": (cellModel?.from.symbol ?? "N/a")])
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    self.updateUIAddressField()
  }
}
