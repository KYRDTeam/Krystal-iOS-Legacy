//
//  FinishImportViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import UIKit
import KrystalWallets
import DesignSystem
import MBProgressHUD
import AppState

class FinishImportViewModel {
    let solanaAddress: String?
    let evmAddress: String?
    let importType: ImportWalletChainType
    let inputKeyWord: String

    init(solanaAddress: String?, evmAddress: String?, importType: ImportWalletChainType, inputKeyWord: String) {
        self.solanaAddress = solanaAddress
        self.evmAddress = evmAddress
        self.importType = importType
        self.inputKeyWord = inputKeyWord
    }
    
    func numberOfRows() -> Int {
        return importType == .multiChain ? 2 : 1
    }
}

class FinishImportViewController: UIViewController {
    @IBOutlet weak var walletNameTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var termOfUseTextView: UITextView!
    @IBOutlet weak var clearWalletNameButton: UIButton!
    let viewModel: FinishImportViewModel


    lazy var passcodeCoordinator: KNPasscodeCoordinator = {
      let coordinator = KNPasscodeCoordinator(
        navigationController: self.navigationController!,
        type: .setPasscode(cancellable: false)
      )
      coordinator.delegate = self
      return coordinator
    }()

    init(viewModel: FinishImportViewModel) {
      self.viewModel = viewModel
      super.init(nibName: FinishImportViewController.className, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellNib(AddressCell.self)
        if viewModel.numberOfRows() == 2 {
            tableViewHeightConstraint.constant = 272
        } else {
            tableViewHeightConstraint.constant = 136
        }
        let wallets = WalletManager.shared.getAllWallets()
        walletNameTextField.text = "Wallet \(wallets.count + 1)"
        walletNameTextField.delegate = self
        
        let linkAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.positiveTextColor,
          NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 14),
          NSAttributedString.Key.kern: 0.0,
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor,
          NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 14),
          NSAttributedString.Key.kern: 0.0,
        ]
        let string = "By proceeding, you agree to Krystal's Terms and Use and Privacy Policy"
        let attributedString = NSMutableAttributedString(string: string, attributes: normalAttributes)
        attributedString.addAttribute(.link, value: "https://files.krystal.app/terms.pdf", range: NSRange(location: "By proceeding, you agree to Krystal's ".count, length: "Terms and Use".count))
        attributedString.addAttribute(.link, value: "https://files.krystal.app/privacy.pdf", range: NSRange(location: string.count - "Privacy Policy".count, length: "Privacy Policy".count))
        
        termOfUseTextView.linkTextAttributes = linkAttributes
        termOfUseTextView.attributedText = attributedString
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        if !KNGeneralProvider.shared.isCreatedPassCode {
            AppState.shared.updateChain(chain: KNGeneralProvider.shared.defaultChain)
            self.passcodeCoordinator.start()
        } else {
            didFinishImport()
        }
    }

    @IBAction func clearWalletNameButtonTapped(_ sender: Any) {
        walletNameTextField.text = ""
    }

    func didFinishImport() {
        let name = walletNameTextField.text?.trimmed
        switch self.viewModel.importType {
        case .solana:
            self.importWallet(with: .privateKey(privateKey: self.viewModel.inputKeyWord), name: name, importType: .solana, selectedChain: .solana)
        case.evm:
            self.importWallet(with: .privateKey(privateKey: self.viewModel.inputKeyWord), name: name, importType: .evm, selectedChain: KNGeneralProvider.shared.defaultChain)
        case.multiChain:
            var seeds = self.viewModel.inputKeyWord.trimmed.components(separatedBy: " ").map({ $0.trimmed })
            seeds = seeds.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
            self.importWallet(with: .mnemonic(words: seeds, password: ""), name: name, importType: .multiChain, selectedChain: KNGeneralProvider.shared.defaultChain)
        }
    }
}

extension FinishImportViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        clearWalletNameButton.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearWalletNameButton.isHidden = false
    }
}

extension FinishImportViewController {
    func addToContacts(wallet: KWallet) {
      let addresses = WalletManager.shared.getAllAddresses(walletID: wallet.id)
      
      let contacts: [KNContact] = addresses.map { address in
        return KNContact(address: address.addressString,
                         name: wallet.name,
                         chainType: address.addressType.importChainType.rawValue)
      }
      
      KNContactStorage.shared.update(contacts: contacts)
    }

    func showImportSuccessMessage() {
      self.showSuccessTopBannerMessage(
        with: Strings.walletImported,
        message: Strings.importWalletSuccess,
        time: 1
      )
      MixPanelManager.track("import_done_pop_up_open", properties: ["screenid": "import_done_pop_up"])
    }
    
    private func onImportWalletSuccess(wallet: KWallet, chain: ChainType, importType: ImportWalletChainType) {
        self.showImportSuccessMessage()
        self.addToContacts(wallet: wallet)
        let chain: ChainType = importType == .solana ? .solana : KNGeneralProvider.shared.defaultChain
        AppDelegate.shared.coordinator.onAddWallet(wallet: wallet, chain: chain)
        AppState.shared.updateAddress(address: AppState.shared.currentAddress, targetChain: AppState.shared.currentChain)
        self.navigationController?.dismiss(animated: true)
    }

    func importWallet(with type: ImportType, name: String?, importType: ImportWalletChainType, selectedChain: ChainType) {
      if name == nil || name?.isEmpty == true {
        Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_empty"])
      } else {
        Tracker.track(event: .screenImportWallet, customAttributes: ["action": "name_not_empty"])
      }
      
      let addressType: KAddressType = {
        switch importType {
        case .multiChain, .evm:
          return .evm
        case .solana:
          return .solana
        }
      }()
      
      switch type {
      case .privateKey(let privateKey):
        do {
          let wallet = try WalletManager.shared.import(privateKey: privateKey, addressType: addressType, name: name.whenNilOrEmpty("Imported"))
          WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
          Tracker.track(event: .iwPKSuccess)
          onImportWalletSuccess(wallet: wallet, chain: selectedChain, importType: importType)
        } catch {
          self.displayAlert(message: importErrorMessage(error: error))
          Tracker.track(event: .iwPKFail)
        }
      case .mnemonic(let words, _):
        do {
          let wallet = try WalletManager.shared.import(mnemonic: words.joined(separator: " "), name: name.whenNilOrEmpty("Imported"))
          WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
          Tracker.track(event: .iwSeedSuccess)
          onImportWalletSuccess(wallet: wallet, chain: selectedChain, importType: importType)
        } catch {
          self.displayAlert(message: importErrorMessage(error: error))
          Tracker.track(event: .iwSeedFail)
        }
      case .keystore(let key, let password):
        do {
          let wallet = try WalletManager.shared.import(keystore: key, addressType: addressType, password: password, name: name.whenNilOrEmpty("Imported"))
          WalletExtraDataManager.shared.markWalletBackedUp(walletID: wallet.id)
          Tracker.track(event: .iwJSONSuccess)
          onImportWalletSuccess(wallet: wallet, chain: selectedChain, importType: importType)
        } catch {
          self.displayAlert(message: importErrorMessage(error: error))
          Tracker.track(event: .iwJSONFail)
        }

      case .watch(_, _):
        return
      }
    }
    
    func importErrorMessage(error: Error) -> String {
      if let error = error as? WalletManagerError {
        switch error {
        case .invalidJSON:
          return Strings.failedToParseJSON
        case .duplicatedWallet:
          return Strings.alreadyAddedWalletAddress
        case .cannotCreateWallet:
          return Strings.failedToCreateWallet
        case .cannotImportWallet:
          return Strings.failedToImportWallet
        default:
          return Strings.failedToImportWallet
        }
      } else {
        return Strings.failedToImportWallet
      }
    }
}

extension FinishImportViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(AddressCell.self, indexPath: indexPath)!
        
        if viewModel.numberOfRows() == 1 {
            if let solanaAddress = viewModel.solanaAddress {
                cell.configUI(walletType: .solana, address: solanaAddress)
            } else if let evmAddress = viewModel.evmAddress {
                cell.configUI(walletType: .evm, address: evmAddress)
            }
        } else {
            if indexPath.row == 0 {
                let evmAddress = viewModel.evmAddress ?? ""
                cell.configUI(walletType: .evm, address: evmAddress, roundCornerAll: false)
                cell.dashView.dashLine(width: 1, color: AppTheme.current.secondaryTextColor)
            } else {
                let solanaAddress = viewModel.solanaAddress ?? ""
                cell.configUI(walletType: .solana, address: solanaAddress, roundCornerAll: false)
            }
        }

        cell.onCopyButtonTapped = { text in
            UIPasteboard.general.string = text
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = .text
            hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
            hud.hide(animated: true, afterDelay: 1.5)
        }
        return cell
    }
}

extension FinishImportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

extension FinishImportViewController: KNPasscodeCoordinatorDelegate {
    func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
        self.passcodeCoordinator.stop { }
    }

    func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
        self.passcodeCoordinator.stop { }
    }

    func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
        didFinishImport()
    }
}
