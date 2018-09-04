// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import QRCodeReaderViewController

enum KNNewContactViewEvent {
  case dismiss
  case send(address: String)
}

protocol KNNewContactViewControllerDelegate: class {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent)
}

class KNNewContactViewModel {

  fileprivate(set) var contact: KNContact
  fileprivate(set) var isEditing: Bool

  init(
    address: String
  ) {
    if let contact = KNContactStorage.shared.get(forPrimaryKey: address.lowercased()) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
  }

  var title: String {
    return isEditing ? "Edit Contact".toBeLocalised() : "Add Contact".toBeLocalised()
  }

  func updateViewModel(address: String) {
    if let contact = KNContactStorage.shared.get(forPrimaryKey: address.lowercased()) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
  }
}

class KNNewContactViewController: KNBaseViewController {

  weak var delegate: KNNewContactViewControllerDelegate?
  fileprivate var viewModel: KNNewContactViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!

  init(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNNewContactViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
  }

  fileprivate func setupUI() {
    self.headerContainerView.backgroundColor = KNAppStyleType.current.walletFlowHeaderColor
    self.saveButton.setTitle("Save".toBeLocalised(), for: .normal)
    self.deleteButton.setTitle("Delete Contact".toBeLocalised(), for: .normal)
    self.sendButton.setTitle("Send", for: .normal)
    self.addressTextField.delegate = self
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.viewModel.title
    self.nameTextField.text = self.viewModel.contact.name
    self.addressTextField.text = self.viewModel.contact.address
    self.deleteButton.isHidden = !self.viewModel.isEditing
  }

  fileprivate func addressTextFieldDidChange() {
    let text = self.addressTextField.text ?? ""
    self.viewModel.updateViewModel(address: text)

    if self.nameTextField.text == nil || self.nameTextField.text?.isEmpty == true {
      self.nameTextField.text = self.viewModel.contact.name
    }
    self.titleLabel.text = self.viewModel.title
    self.deleteButton.isHidden = !self.viewModel.isEditing
  }

  func updateView(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    guard let name = self.nameTextField.text else {
      self.showWarningTopBannerMessage(with: "", message: "Contact should have a name".toBeLocalised())
      return
    }
    guard let address = self.addressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(with: "Invalid address".toBeLocalised(), message: "Please enter a valid address".toBeLocalised())
      return
    }
    let contact = KNContact(address: address.lowercased(), name: name)
    KNContactStorage.shared.update(contacts: [contact])
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    let alertController = UIAlertController(
      title: "",
      message: "Do you want to delete this contact?".toBeLocalised(),
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: "Cancel".toBeLocalised(), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Delete".toBeLocalised(), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [self.viewModel.contact])
      KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
      self.delegate?.newContactViewController(self, run: .dismiss)
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    guard let address = Address(string: self.addressTextField.text ?? "") else {
      self.showErrorTopBannerMessage(
        with: "Invalid address".toBeLocalised(),
        message: "Please enter a valid address to continue".toBeLocalised(),
        time: 2.0
      )
      return
    }
    self.delegate?.newContactViewController(self, run: .send(address: address.description))
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    let qrcodeVC = QRCodeReaderViewController()
    qrcodeVC.delegate = self
    self.present(qrcodeVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.newContactViewController(self, run: .dismiss)
    }
  }
}

extension KNNewContactViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.addressTextField {
      self.addressTextFieldDidChange()
    }
    return false
  }
}

extension KNNewContactViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.addressTextField.text = result
      self.addressTextFieldDidChange()
    }
  }
}
