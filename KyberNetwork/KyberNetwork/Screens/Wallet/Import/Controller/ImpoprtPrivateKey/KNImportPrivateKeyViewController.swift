// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController
import WalletCore
import KrystalWallets

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String, name: String?)
  func importPrivateKeyViewController(controller: KNImportPrivateKeyViewController, send refCode: String)
  func importPrivateKeyControllerDidSelectQRCode(controller: KNImportPrivateKeyViewController)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  private var isSecureText: Bool = true
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!
  @IBOutlet weak var privateKeyNoteLabel: UILabel!
  @IBOutlet weak var privateKeyFieldContainer: UIView!

  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var refCodeField: UITextField!
  @IBOutlet weak var containerRefCodeView: UIView!
  @IBOutlet weak var refCodeTitleLabel: UILabel!
  var importType: ImportWalletChainType = .multiChain
  var privateKey: String = ""
  
  var isValueValid: Bool {
    guard let text = self.enterPrivateKeyTextField.text else { return false }
    if importType == .solana {
      return SolanaUtils.isValidSolanaPrivateKey(text: text)
    } else {
      return text.count == 64
    }
  }
  
  var privateKeyWarningText: String {
    return importType == .solana ? "*Private key has to be 64 bytes" : "*Private key has to be 64 characters"
  }
  
  var getFormattedPrivateKey: String? {
    let text = enterPrivateKeyTextField.text ?? ""
    switch importType {
    case .solana:
      if SolanaUtils.isNormalPrivateKey(text: text) {
        return text
      } else if let privateKey = SolanaUtils.getPrivateKey(numericPrivateKey: text) {
        return WalletUtils.string(fromPrivateKey: privateKey, addressType: .solana)
      }
      return nil
    default:
      return text
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.walletNameTextField.delegate = self
    self.refCodeField.delegate = self
    
    self.enterPrivateKeyTextLabel.text = NSLocalizedString("your.private.key", value: "Your Private Key", comment: "")
    self.enterPrivateKeyTextLabel.addLetterSpacing()
    self.enterPrivateKeyTextField.delegate = self

    self.privateKeyNoteLabel.text = self.privateKeyWarningText
    self.privateKeyNoteLabel.addLetterSpacing()

    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(
      NSLocalizedString("Connect", value: "Connect", comment: ""),
      for: .normal
    )
    self.nextButton.addTextSpacing()
    self.enterPrivateKeyTextField.placeholder = NSLocalizedString("enter.or.scan.private.key", value: "Enter or scan private key", comment: "")
    self.enterPrivateKeyTextField.addPlaceholderSpacing()
    self.walletNameTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.addPlaceholderSpacing()
    
    self.privateKeyFieldContainer.rounded(radius: 8)
    self.walletNameTextField.rounded(radius: 8)
    self.refCodeField.attributedPlaceholder = NSAttributedString(string: "Paste your Referral Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.resetUI()
  }

  func resetUI() {
    self.enterPrivateKeyTextField.text = privateKey
    self.walletNameTextField.text = ""
    self.isSecureText = true
    self.updateSecureTextEntry()

    self.updateNextButton()
  }

  fileprivate func updateSecureTextEntry() {
    let secureTextImage = UIImage(named: !self.isSecureText ? "hide_eye_icon" : "show_eye_icon")
    self.secureTextButton.setImage(secureTextImage, for: .normal)
    self.enterPrivateKeyTextField.isSecureTextEntry = self.isSecureText
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = self.isValueValid
    self.nextButton.isEnabled = enabled
    let noteColor: UIColor = {
      let text = self.enterPrivateKeyTextField.text ?? ""
      if enabled || text.isEmpty { return UIColor(red: 182, green: 186, blue: 185) }
      return UIColor.Kyber.strawberry
    }()
    self.privateKeyNoteLabel.textColor = noteColor
    if enabled {
      self.nextButton.alpha = 1
    } else {
      self.nextButton.alpha = 0.2
    }
  }

  @IBAction func qrCodeButtonPressed(_ sender: Any) {
    guard let navigation = self.navigationController else {
      return
    }
    let acceptedResultTypes: [ScanResultType] = {
      switch importType {
      case .multiChain:
        return []
      case .evm:
        return [.ethPrivateKey]
      case .solana:
        return [.solPrivateKey]
      }
    }()
    let scanModes: [ScanMode] = {
      switch importType {
      case .multiChain:
        return []
      case .evm:
        return [.qr, .text]
      case .solana:
        return [.qr]
      }
    }()
    ScannerModule.start(previousScreen: ScreenName.importWallet,
                        viewController: self,
                        acceptedResultTypes: acceptedResultTypes,
                        defaultScanMode: scanModes.contains(.text) ? .text : .qr,
                        scanModes: scanModes) { [weak self] privateKey, _ in
      self?.enterPrivateKeyTextField.text = privateKey.drop0x
      self?.updateNextButton()
    }
  }
  
  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.isSecureText = !self.isSecureText
    self.updateSecureTextEntry()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    if let text = self.refCodeField.text, !text.isEmpty {
      self.delegate?.importPrivateKeyViewController(controller: self, send: text)
    }
    guard let privateKeyString = self.getFormattedPrivateKey else {
      return
    }
    self.delegate?.importPrivateKeyViewControllerDidPressNext(
      sender: self,
      privateKey: privateKeyString,
      name: self.walletNameTextField.text
    )
    
    MixPanelManager.track("import_wallet_ppk_connect", properties: ["screenid": "import_by_private_key", "name": walletNameTextField.text])
  }
  
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      if sender.tag == 1 {
        self.enterPrivateKeyTextField.text = string.drop0x
        self.updateNextButton()
      } else {
        self.refCodeField.text = string
      }
    }
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.delegate?.importPrivateKeyControllerDidSelectQRCode(controller: self)
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeField.text = refCode
  }
}

extension KNImportPrivateKeyViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    switch textField {
    case enterPrivateKeyTextField:
      let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
      textField.text = text
      if textField == self.enterPrivateKeyTextField {
        if text.hasPrefix("0x") {
          textField.text = string.drop0x
        }
        self.updateNextButton()
      }
      return false
    default:
      return true
    }
  }
}

extension KNImportPrivateKeyViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.enterPrivateKeyTextField.text = result.drop0x
      self.updateNextButton()
    }
  }
}
