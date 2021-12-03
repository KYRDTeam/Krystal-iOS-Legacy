//
//  SendNFTViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 26/08/2021.
//

import UIKit
import QRCodeReaderViewController
import TrustCore
import BigInt

class SendNFTViewModel {
  fileprivate(set) var addressString: String = ""
  var address: Address?
  fileprivate(set) var isUsingEns: Bool = false

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault
  fileprivate(set) var baseGasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault
  
  var advancedGasLimit: String? {
    didSet {
      if self.advancedGasLimit != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxPriorityFee: String? {
    didSet {
      if self.advancedMaxPriorityFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxFee: String? {
    didSet {
      if self.advancedMaxFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedNonce: String? {
    didSet {
      if self.advancedNonce != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }
  
  let item: NFTItem
  let category: NFTSection
  var selectedBalance: Int = 0
  let isSupportERC721: Bool

  init(item: NFTItem, category: NFTSection, supportERC721: Bool) {
    self.item = item
    self.category = category
    self.isSupportERC721 = supportERC721
  }

  func updateAddress(_ address: String) {
    self.addressString = address
    self.address = Address(string: address)
    if self.address != nil {
      self.isUsingEns = false
    }
  }

  func updateAddressFromENS(_ ens: String, ensAddr: Address?) {
    if ens == self.addressString {
      self.address = ensAddr
      self.isUsingEns = ensAddr != nil
    }
  }

  var displayAddress: String? {
    if self.address == nil { return self.addressString }
    if let contact = KNContactStorage.shared.contacts.first(where: { self.addressString.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.addressString)"
    }
    return self.addressString
  }

  var displayEnsMessage: String? {
    if self.addressString.isEmpty { return nil }
    if self.address == nil { return "Invalid address or your ens is not mapped yet" }
    if Address(string: self.addressString) != nil { return nil }
    let address = self.address?.description ?? ""
    return "\(address.prefix(12))...\(address.suffix(10))"
  }

  var displayEnsMessageColor: UIColor {
    if self.address == nil { return UIColor.Kyber.strawberry }
    return UIColor.Kyber.blueGreen
  }
  
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    case .custom:
      if let customGasPrice = self.advancedMaxFee?.shortBigInt(units: UnitConfiguration.gasPriceUnit),
          let customGasLimitString = self.advancedGasLimit,
          let customGasLimit = BigInt(customGasLimitString) {
        self.gasPrice = customGasPrice
        self.gasLimit = customGasLimit
      }
    default: return
    }
  }
  
  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
    self.gasLimit = self.baseGasLimit
  }
  
  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    var typeString = ""
    switch self.selectedGasPriceType {
    case .superFast:
      typeString = "super.fast".toBeLocalised().uppercased()
    case .fast:
      typeString = "fast".toBeLocalised().uppercased()
    case .medium:
      typeString = "regular".toBeLocalised().uppercased()
    case .slow:
      typeString = "slow".toBeLocalised().uppercased()
    case .custom:
      typeString = "custom".toBeLocalised().uppercased()
    }
    return "\(feeString) \(sourceToken) (\(typeString))"
  }
  
  var ethFeeBigInt: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var isHavingEnoughETHForFee: Bool {
    let fee = self.ethFeeBigInt
    let ethBal = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBal >= fee
  }
  
  var isAddressValid: Bool {
    return self.address != nil
  }
  
  func updateEstimatedGasLimit(_ gasLimit: BigInt) {
    if self.selectedGasPriceType == .custom {
      self.baseGasLimit = gasLimit
    } else {
      self.gasLimit = gasLimit
      self.baseGasLimit = gasLimit
    }
  }
  
  var displayTotalBalance: String {
    return "NFT Balance: \(self.item.balanceInt)"
  }
  
  var displayEstGas: String {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return ""
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = (baseFee + self.selectedPriorityFee) * self.gasLimit
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(sourceToken) "
  }
  
  var selectedPriorityFee: BigInt {
    switch self.selectedGasPriceType {
    case .slow:
      return KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
    case .medium:
      return KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
    case .fast:
      return KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)
    case .superFast:
      return KNGasCoordinator.shared.superFastPriorityFee ?? BigInt(0)
    case .custom:
      if let unwrap = self.advancedMaxPriorityFee, let fee = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        return fee
      } else {
        return BigInt(0)
      }
    }
  }
}

class SendNFTViewController: KNBaseViewController {
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var moreContactButton: UIButton!
  @IBOutlet weak var recentContactView: UIView!
  @IBOutlet weak var recentContactLabel: UILabel!
  @IBOutlet weak var recentContactTableView: KNContactTableView!
  @IBOutlet weak var recentContactHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var recentContactTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var ensAddressLabel: UILabel!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var bottomPaddingConstraintForScrollView: NSLayoutConstraint!
  @IBOutlet weak var selectedGasFeeLabel: UILabel!
  @IBOutlet weak var nftImageView: UIImageView!
  @IBOutlet weak var nftNameLabel: UILabel!
  @IBOutlet weak var nftIDLabel: UILabel!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var amountContainerView: UIView!
  @IBOutlet weak var amountTitleView: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var addressTitleTopContraint: NSLayoutConstraint!
  @IBOutlet weak var estGasFeeTitleLabel: UILabel!
  @IBOutlet weak var estGasFeeValueLabel: UILabel!
  @IBOutlet weak var gasFeeTittleLabelTopContraint: NSLayoutConstraint!
  
  fileprivate let viewModel: SendNFTViewModel
  weak var delegate: KSendTokenViewControllerDelegate?

  init(viewModel: SendNFTViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SendNFTViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.updateGasFeeUI()
    self.updateUIEnsMessage()
    self.setupRecentContact()
    self.updateUINFTItem()
    self.updateAmountViews()
  }

  func updateAmountViews() {
    if self.viewModel.isSupportERC721 {
      self.addressTitleTopContraint.constant = 40
      self.amountContainerView.isHidden = true
      self.amountTitleView.isHidden = true
      self.balanceLabel.isHidden = true
    } else {
      self.addressTitleTopContraint.constant = 150
      self.amountContainerView.isHidden = false
      self.amountTitleView.isHidden = false
      self.balanceLabel.isHidden = false
      self.balanceLabel.text = self.viewModel.displayTotalBalance
    }
  }

  func updateUINFTItem() {
    self.nftImageView.setImage(with: self.viewModel.item.externalData.image, placeholder: UIImage(named: "placeholder_nft_item")!, size: nil, applyNoir: false)
    self.nftNameLabel.text = self.viewModel.item.externalData.name
    self.nftIDLabel.text = "#" + self.viewModel.item.tokenID
  }

  func updateUIAddressQRCode(isAddressChanged: Bool = true) {
    self.addressTextField.text = self.viewModel.displayAddress
    self.updateUIEnsMessage()
    if isAddressChanged { self.shouldUpdateEstimatedGasLimit(nil) }
    self.view.layoutIfNeeded()
  }

  func updateUIEnsMessage() {
    self.ensAddressLabel.isHidden = false
    self.ensAddressLabel.text = self.viewModel.displayEnsMessage
    self.ensAddressLabel.textColor = self.viewModel.displayEnsMessageColor
  }
  
  fileprivate func shouldUpdateEstimatedGasLimit(_ sender: Any?) {
    if self.viewModel.address == nil { return }

    let event = KSendTokenViewEvent.estimateGasLimitTransferNFT(to: self.viewModel.addressString,item: self.viewModel.item, category: self.viewModel.category , gasPrice: self.viewModel.gasPrice, gasLimit: self.viewModel.gasLimit, amount: self.viewModel.selectedBalance, isERC721: self.viewModel.isSupportERC721)
    self.delegate?.kSendTokenViewController(self, run: event)
  }
  
  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
    if KNGeneralProvider.shared.isUseEIP1559 {
      self.estGasFeeTitleLabel.isHidden = false
      self.estGasFeeValueLabel.isHidden = false
      self.gasFeeTittleLabelTopContraint.constant = 54
    } else {
      self.estGasFeeTitleLabel.isHidden = true
      self.estGasFeeValueLabel.isHidden = true
      self.gasFeeTittleLabelTopContraint.constant = 20
    }
    self.estGasFeeValueLabel.text = self.viewModel.displayEstGas
  }
  
  fileprivate func setupRecentContact() {
    self.recentContactView.isHidden = true
    self.recentContactTableView.delegate = self
    self.recentContactTableView.updateScrolling(isEnabled: false)
    self.recentContactTableView.shouldUpdateContacts(nil)
    self.moreContactButton.setTitle(
      "more".toBeLocalised().uppercased(),
      for: .normal
    )
  }
  
  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming { return false }
    if isConfirming {
      guard self.viewModel.isHavingEnoughETHForFee else {
        let quoteToken = KNGeneralProvider.shared.quoteToken
        let fee = self.viewModel.ethFeeBigInt
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("Insufficient \(quoteToken) for transaction", value: "Insufficient \(quoteToken) for transaction", comment: ""),
          message: String(format: "Deposit more \(quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 6))
        )
        return true
      }
      guard EtherscanTransactionStorage.shared.isContainInsternalSendTransaction() == false else {
        self.showWarningTopBannerMessage(
          with: "",
          message: "Please wait for transaction is completed"
        )
        return true
      }
      guard self.viewModel.selectedBalance <= self.viewModel.item.balanceInt else {
        self.showWarningTopBannerMessage(
          with: "",
          message: "Amount is too big"
        )
        return true
      }
    }

    return false
  }

  fileprivate func showWarningInvalidAddressIfNeeded() -> Bool {
    guard self.viewModel.isAddressValid else {
      self.showWarningTopBannerMessage(
        with: "Invalid Address/ENS".toBeLocalised(),
        message: "Please enter a valid address/ens to transfer".toBeLocalised()
      )
      return true
    }
    return false
  }
  
  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt) {
    self.viewModel.updateEstimatedGasLimit(gasLimit)
    self.updateGasFeeUI()
  }
  
  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.updateGasFeeUI()
  }

  func coordinatorFailedToUpdateEstimateGasLimit() {
    DispatchQueue.main.asyncAfter(deadline: .now() + KNLoadingInterval.seconds60) {
      self.shouldUpdateEstimatedGasLimit(nil)
    }
  }
  
  func coordinatorDidSelectContact(_ contact: KNContact) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != contact.address.lowercased()
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }
  
  func coordinatorSend(to address: String) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
    self.viewModel.updateAddress(address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    if let contact = KNContactStorage.shared.contacts.first(where: { return address.lowercased() == $0.address.lowercased() }) {
      KNContactStorage.shared.updateLastUsed(contact: contact)
    }
  }
  
  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.present(qrcodeReaderVC, animated: true, completion: nil)
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.delegate?.kSendTokenViewController(self, run: .openGasPriceSelect(
      gasLimit: self.viewModel.gasLimit,
      baseGasLimit: self.viewModel.baseGasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      advancedGasLimit: self.viewModel.advancedGasLimit,
      advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
      advancedMaxFee: self.viewModel.advancedMaxFee,
      advancedNonce: self.viewModel.advancedNonce
    ))
  }

  @IBAction func recentContactMoreButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .contactSelectMore)
  }
  
  @IBAction func sendButtonPressed(_ sender: Any) {
    if self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) { return }
    if self.showWarningInvalidAddressIfNeeded() { return }
    
    if KNGeneralProvider.shared.isUseEIP1559 {
      let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
      let priorityFeeBigIntDefault = self.viewModel.selectedPriorityFee
      
      let event = KSendTokenViewEvent.sendNFT(
        item: self.viewModel.item,
        category: self.viewModel.category,
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.gasLimit,
        to: self.viewModel.addressString,
        amount: self.viewModel.selectedBalance,
        ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil,
        isERC721: self.viewModel.isSupportERC721,
        advancedGasLimit: self.viewModel.advancedGasLimit,
        advancedPriorityFee: self.viewModel.advancedMaxPriorityFee != nil ? self.viewModel.advancedMaxPriorityFee : priorityFeeBigIntDefault.shortString(units: UnitConfiguration.gasPriceUnit) ,
        advancedMaxFee: self.viewModel.advancedMaxFee != nil ? self.viewModel.advancedMaxFee : self.viewModel.gasPrice.shortString(units: UnitConfiguration.gasPriceUnit),
        advancedNonce: self.viewModel.advancedNonce
      )
      self.delegate?.kSendTokenViewController(self, run: event)
    } else {
      let event = KSendTokenViewEvent.sendNFT(
        item: self.viewModel.item,
        category: self.viewModel.category,
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.gasLimit,
        to: self.viewModel.addressString,
        amount: self.viewModel.selectedBalance,
        ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil,
        isERC721: self.viewModel.isSupportERC721,
        advancedGasLimit: nil,
        advancedPriorityFee: nil,
        advancedMaxFee: nil,
        advancedNonce: nil
      )
      self.delegate?.kSendTokenViewController(self, run: event)
    }
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    self.viewModel.selectedBalance = self.viewModel.item.balanceInt
    self.amountTextField.text = "\(self.viewModel.selectedBalance)"
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }
}

extension SendNFTViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
      self.viewModel.updateAddress(address)
      self.getEnsAddressFromName(address)
      self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    }
  }

  fileprivate func getEnsAddressFromName(_ name: String) {
    if Address(string: name) != nil { return }
    if !name.contains(".") {
      self.viewModel.updateAddressFromENS(name, ensAddr: nil)
      self.updateUIAddressQRCode()
      return
    }
    DispatchQueue.main.async {
      KNGeneralProvider.shared.getAddressByEnsName(name.lowercased()) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if name != self.viewModel.addressString { return }
          if case .success(let addr) = result, let address = addr, address != Address(string: "0x0000000000000000000000000000000000000000") {
            self.viewModel.updateAddressFromENS(name, ensAddr: address)
          } else {
            self.viewModel.updateAddressFromENS(name, ensAddr: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + KNLoadingInterval.seconds30) {
              self.getEnsAddressFromName(self.viewModel.addressString)
            }
          }
          self.updateUIAddressQRCode()
        }
      }
    }
  }
}

extension SendNFTViewController: KNContactTableViewDelegate {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent) {
    switch event {
    case .update(let height):
      self.updateContactTableView(height: height)
    case .select(let contact):
      self.contactTableView(select: contact)
    case .edit(let contact):
      self.delegate?.kSendTokenViewController(self, run: .addContact(address: contact.address, ens: nil))
    case .delete(let contact):
      self.contactTableView(delete: contact)
    case .send(let address):
      if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
        self.contactTableView(select: contact)
      } else {
        let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
        self.viewModel.updateAddress(address)
        self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
      }
    case .copiedAddress:
      self.showMessageWithInterval(
        message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
      )
    case .addContact:
     break
    }
  }

  fileprivate func updateContactTableView(height: CGFloat) {
    UIView.animate(
    withDuration: 0.25) {
      self.recentContactView.isHidden = (height == 0)
      self.recentContactHeightConstraint.constant = height == 0 ? 0 : height + 34.0
      self.recentContactTableViewHeightConstraint.constant = height
      self.updateUIAddressQRCode(isAddressChanged: false)
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func contactTableView(select contact: KNContact) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != contact.address.lowercased()
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }

  fileprivate func contactTableView(delete contact: KNContact) {
    let alertController = UIAlertController(
      title: NSLocalizedString("do.you.want.to.delete.this.contact", value: "Do you want to delete this contact?", comment: ""),
      message: "",
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [contact])
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }
}

extension SendNFTViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if textField == amountTextField {
      self.viewModel.selectedBalance = 0
    } else {
      self.viewModel.updateAddress("")
      self.updateUIAddressQRCode()
      self.getEnsAddressFromName("")
    }

    self.shouldUpdateEstimatedGasLimit(nil)
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if textField == amountTextField {
      if let number = Int(text), number > 0 {
        textField.text = "\(number)"
        self.viewModel.selectedBalance = number
      } else {
        textField .text = ""
        self.viewModel.selectedBalance = 0
      }
    } else {
      textField.text = text
      self.viewModel.updateAddress(text)
      self.updateUIEnsMessage()
      self.getEnsAddressFromName(text)
    }
    
    self.view.layoutIfNeeded()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == amountTextField {
      self.amountTextField.text = self.viewModel.selectedBalance == 0 ? "" : "\(self.viewModel.selectedBalance)"
    } else {
      self.addressTextField.text = self.viewModel.addressString
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == amountTextField {
      
    } else {
      self.updateUIAddressQRCode()
      self.getEnsAddressFromName(self.viewModel.addressString)
    }
    self.shouldUpdateEstimatedGasLimit(nil)
  }
}
