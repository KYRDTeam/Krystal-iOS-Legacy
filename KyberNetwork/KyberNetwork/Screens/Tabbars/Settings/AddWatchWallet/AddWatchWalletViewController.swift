//
//  AddWatchWalletViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/14/21.
//

import UIKit
import QRCodeReaderViewController
import TrustCore

class AddWatchWalletViewModel {
  fileprivate(set) var addressString: String = ""

  var wallet: KNWalletObject? {
    didSet {
      if let unwrapped = self.wallet {
        self.updateAddress(unwrapped.address.lowercased())
      }
    }
  }
  
  var isAddressValid: Bool {
    guard !self.addressString.isEmpty else { return false }
    if KNGeneralProvider.shared.currentChain == .solana {
      return SolanaUtil.isVaildSolanaAddress(self.addressString)
    } else {
      return Address.isAddressValid(self.addressString)
    }
  }

  func updateAddress(_ address: String) {
    self.addressString = address
  }
  
  var displayAddress: String? {

    if let contact = KNContactStorage.shared.contacts.first(where: { self.addressString.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.addressString)"
    }
    return self.addressString
  }
  
  var displayTitle: String {
    if self.wallet == nil {
      return "Add watched wallet"
    } else {
      return "Edit watched wallet"
    }
  }
  
  var displayAddButtonTitle: String {
    if self.wallet == nil {
      return "Add"
    } else {
      return "Edit"
    }
  }
}

protocol AddWatchWalletViewControllerDelegate: class {
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: String, name: String?)
  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController)
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, wallet: KNWalletObject, address: String, name: String?)
}

class AddWatchWalletViewController: UIViewController {
  @IBOutlet weak var walletLabelTextField: UITextField!
  @IBOutlet weak var walletAddressTextField: UITextField!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var ensAddressLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  
  weak var delegate: AddWatchWalletViewControllerDelegate?

  let transitor = TransitionDelegate()
  let viewModel: AddWatchWalletViewModel
  
  init(viewModel: AddWatchWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: AddWatchWalletViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.cancelButton.rounded(radius: 16)
    self.addButton.rounded(radius: 16)
    self.titleLabel.text = self.viewModel.displayTitle
    self.walletLabelTextField.text = self.viewModel.wallet?.name
    self.walletAddressTextField.text = self.viewModel.wallet?.address
    self.addButton.setTitle(self.viewModel.displayAddButtonTitle, for: .normal)
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.addWatchWalletViewControllerDidClose(self)
    }
  }

  @IBAction func doneButtonTapped(_ sender: Any) {
    guard self.viewModel.isAddressValid else {
      self.showErrorTopBannerMessage(message: "Please enter address".toBeLocalised())
      return
    }
    if self.viewModel.wallet == nil {
      guard !KNWalletStorage.shared.checkAddressExisted(self.viewModel.addressString) else {
        self.showErrorTopBannerMessage(message: "Address existed".toBeLocalised())
        return
      }
    }
    
    self.dismiss(animated: true) {
      if let unwrapped = self.viewModel.wallet {
        self.delegate?.addWatchWalletViewControllerDidEdit(self, wallet: unwrapped.clone(), address: self.viewModel.addressString, name: self.walletLabelTextField.text)
      } else {
        self.delegate?.addWatchWalletViewController(self, didAddAddress: self.viewModel.addressString, name: self.walletLabelTextField.text)
      }
    }
  }

  @IBAction func qrButtonTapped(_ sender: UIButton) {
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

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
      self.delegate?.addWatchWalletViewControllerDidClose(self)
    })
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.contentView.endEditing(true)
  }

  

  func updateUIAddressQRCode(isAddressChanged: Bool = true) {
    self.walletAddressTextField.text = self.viewModel.displayAddress
    self.updateUIEnsMessage()
    self.view.layoutIfNeeded()
  }

  func updateUIEnsMessage() {
    
    self.ensAddressLabel.isHidden = true
  }
}

extension AddWatchWalletViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 379
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension AddWatchWalletViewController: QRCodeReaderDelegate {
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

      self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    }
  }
}

extension AddWatchWalletViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateAddress("")
    self.updateUIAddressQRCode()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.viewModel.updateAddress(text)
    self.updateUIEnsMessage()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.walletAddressTextField.text = self.viewModel.addressString
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateUIAddressQRCode()
  }
}
