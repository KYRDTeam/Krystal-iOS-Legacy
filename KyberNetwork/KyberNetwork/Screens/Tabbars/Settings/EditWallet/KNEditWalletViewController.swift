// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

enum KNEditWalletViewEvent {
  case back
  case update(wallet: KWallet, name: String)
  case backup(wallet: KWallet, addressType: KAddressType)
  case delete(wallet: KWallet)
}

protocol KNEditWalletViewControllerDelegate: class {
  func editWalletViewController(_ controller: KNEditWalletViewController, run event: KNEditWalletViewEvent)
}

struct KNEditWalletViewModel {
  
  let wallet: KWallet
  let addressType: KAddressType
  var actions: Actions

  init(wallet: KWallet, addressType: KAddressType, actions: Actions) {
    self.wallet = wallet
    self.addressType = addressType
    self.actions = actions
  }
  
  struct Actions {
    var goBack: () -> ()
    var updateName: (String) -> ()
    var backup: () -> ()
    var delete: () -> ()
  }
}

class KNEditWalletViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var nameWalletTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!

  @IBOutlet weak var showBackupPhraseButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var doneButton: UIButton!
  
  fileprivate let viewModel: KNEditWalletViewModel
  weak var delegate: KNEditWalletViewControllerDelegate?

  init(viewModel: KNEditWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNEditWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = NSLocalizedString("edit.wallet", value: "Edit Wallet", comment: "")
    self.nameWalletTextLabel.text = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.placeholder = NSLocalizedString("give.your.wallet.a.name", value: "Give your wallet a name", comment: "")
    self.walletNameTextField.text = self.viewModel.wallet.name
    self.showBackupPhraseButton.setTitle(NSLocalizedString("show.backup.phrase", value: "Show Backup Phrase", comment: ""), for: .normal)
    self.deleteButton.setTitle(NSLocalizedString("delete.wallet", value: "Delete Wallet", comment: ""), for: .normal)
    self.doneButton.rounded(radius: 16)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.walletNameTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.viewModel.actions.goBack()
  }

  @IBAction func showBackUpPhraseButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.viewModel.actions.backup()
    MixPanelManager.track("edit_wallet_export", properties: ["screenid": "edit_wallet"])
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.viewModel.actions.delete()
    MixPanelManager.track("edit_wallet_delete", properties: ["screenid": "edit_wallet"])
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    let newName = self.walletNameTextField.text ?? Strings.untitled
    self.viewModel.actions.updateName(newName)
    MixPanelManager.track("edit_wallet_done", properties: ["screenid": "edit_wallet"])
  }

  @IBAction func edgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.viewModel.actions.goBack()
    }
  }
}
