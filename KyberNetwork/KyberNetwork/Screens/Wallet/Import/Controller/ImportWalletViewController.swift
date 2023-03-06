//
//  ImportWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import UIKit
import DesignSystem
import KrystalWallets
import AppState
import WalletCore

class ImportWalletViewController: UIViewController {
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var wordCountLabel: UILabel!
    @IBOutlet weak var pasteImageView: UIImageView!
    @IBOutlet weak var pasteInfoView: UILabel!
    @IBOutlet weak var clearTextBtn: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var pasteButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var pasteView: UIView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var inputContainView: UIView!
    let TEXT_VIEW_PADDING = CGFloat(13)

    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pasteView.isHidden = UIPasteboard.general.string == nil
    }
    
    func configUI() {
        continueButton.isEnabled = false
        continueButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
        continueButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .disabled)
        inputTextView.delegate = self
        inputTextView.text = "Input here"
        inputTextView.textColor = .lightGray
        
        
        let attributedString = NSMutableAttributedString()
        let boldAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor,
          NSAttributedString.Key.font: UIFont.karlaBold(ofSize: 16),
          NSAttributedString.Key.kern: 0.0,
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: AppTheme.current.secondaryTextColor,
          NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 16),
          NSAttributedString.Key.kern: 0.0,
        ]
        attributedString.append(NSAttributedString(string: "Enter ", attributes: normalAttributes))
        attributedString.append(NSAttributedString(string: "seed phrase", attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: " or ", attributes: normalAttributes))
        attributedString.append(NSAttributedString(string: "private key", attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: " to import wallet", attributes: normalAttributes))
        
        infoLabel.attributedText = attributedString
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func scanButtonTapped(_ sender: Any) {
        let acceptedResultTypes: [ScanResultType] = [.seed, .ethPrivateKey, .solPrivateKey]
        let scanModes: [ScanMode] = [.qr]
        ScannerModule.start(previousScreen: ScreenName.importWallet, viewController: self, acceptedResultTypes: acceptedResultTypes, scanModes: scanModes) { [weak self] text, type in
            guard let self = self else { return }
            self.updateTextInput(value: text)
        }
    }

    @IBAction func clearTextButtonTapped(_ sender: Any) {
        inputTextView.text = nil
        pasteInfoView.isHidden = true
        inputViewHeightConstraint.constant = 48
        updateWordCount()
    }

    @IBAction func hintButtonTapped(_ sender: Any) {
        let tipVC = TipsViewController.instantiateFromNib()
        tipVC.dataSource = [
            TipModel(title: Strings.seedPhaseTip, detail: Strings.seedPhaseTipDetail),
            TipModel(title: Strings.privateKeyTip, detail: Strings.privateKeyTipDetail)
        ]
        tipVC.title = Strings.securityTips
        navigationController?.pushViewController(tipVC, animated: true)
    }
    
    @IBAction func pasteButtonTapped(_ sender: Any) {
        if let string = UIPasteboard.general.string {
            updateTextInput(value: string)
            showErrorIfNeeded()
            showPasteInfoView()
        }
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        var solanaAddress: String?
        var evmAddress: String?
        var importType: ImportWalletChainType = .multiChain
        
        let inputString = inputTextView.text.trimmed
        var words = inputString.components(separatedBy: " ").map({ $0.trimmed })
        words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
        
        if wordCount() == 1 {
            if ScannerUtils.isValid(text: inputString, forType: .ethPrivateKey) {
                if let data = Data(hexString: inputString), let privateKey = PrivateKey(data: data) {
                    evmAddress = CoinType.ethereum.deriveAddress(privateKey: privateKey).lowercased()
                    importType = .evm
                }
            } else if SolanaUtils.isValidSolanaPrivateKey(text: inputString) {
                if let data = Base58.decodeNoCheck(string: inputString), let key = PrivateKey(data: data[0...31]) {
                    solanaAddress = AnyAddress(publicKey: key.getPublicKeyEd25519(), coin: .solana).description
                    importType = .solana
                }
            }
        } else {
            var seeds = inputTextView.text.trimmed.components(separatedBy: " ").map({ $0.trimmed })
            seeds = seeds.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
            let hdWallet = HDWallet(mnemonic: seeds.joined(separator: " "), passphrase: "")
            evmAddress = hdWallet?.getAddressForCoin(coin: .ethereum)

            if let key = hdWallet?.getKey(coin: .solana, derivationPath: "m/44'/501'/0'/0'") {
                solanaAddress = AnyAddress(publicKey: key.getPublicKeyEd25519(), coin: .solana).description
            }
        }

        let viewModel = FinishImportViewModel(solanaAddress: solanaAddress, evmAddress: evmAddress, importType: importType, inputKeyWord: inputTextView.text.trimmed)
        let finishVC = FinishImportViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(finishVC, animated: true)
    }
    
    func updateTextInput(value: String) {
        inputTextView.text = value
        inputTextView.textColor = AppTheme.current.primaryTextColor
        let height = inputTextView.contentSize.height + TEXT_VIEW_PADDING
        inputViewHeightConstraint.constant = min(height, UIScreen.main.bounds.size.height / 3)
        updateContinueButton()
        updateWordCount()
    }
    
    func wordCount() -> Int {
        if inputTextView.textColor == .lightGray {
            return 0
        }
        var words = inputTextView.text.trimmed.components(separatedBy: " ").map({ $0.trimmed })
        words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
        return words.count
    }
    
    func isValidWordCount() -> Bool {
        let wordCount = wordCount()
        let validWordCount = [12, 15, 18, 21, 24]
        return validWordCount.contains(wordCount)
    }
    
    func isValidPrivateKey() -> Bool {
        guard wordCount() == 1 else { return false }
        let text = inputTextView.text.trimmed
        return ScannerUtils.isValid(text: text, forType: .ethPrivateKey) || ScannerUtils.isValid(text: text, forType: .solPrivateKey)
    }
    
    func isValidInput() -> Bool {
        return isValidWordCount() || isValidPrivateKey()
    }
    
    func updateWordCount() {
        wordCountLabel.text = "Word count: \(wordCount())"
        wordCountLabel.textColor = wordCount() == 0 || isValidInput() ? AppTheme.current.primaryTextColor : AppTheme.current.errorTextColor
    }
    
    func updateContinueButton() {
        continueButton.isEnabled = isValidInput()
    }

    func showErrorIfNeeded() {
        if wordCount() == 0 || isValidInput() {
            pasteButtonTopConstraint.constant = 0
            inputContainView.removeError()
            errorLabel.isHidden = true
        } else {
            inputContainView.shakeViewError()
            pasteButtonTopConstraint.constant = 20
            errorLabel.isHidden = false
        }
    }
    
    func showPasteInfoView() {
        self.view.layoutIfNeeded()
        let oldY = self.pasteInfoView.frame.origin.y
        self.pasteInfoView.frame = CGRect(x: self.pasteInfoView.frame.origin.x, y: 0, width: self.pasteInfoView.frame.size.width, height: self.pasteInfoView.frame.size.height)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.pasteInfoView.isHidden = false
            self.pasteInfoView.frame = CGRect(x: self.pasteInfoView.frame.origin.x, y: oldY, width: self.pasteInfoView.frame.size.width, height: self.pasteInfoView.frame.size.height)
            self.view.layoutIfNeeded()
        }
    }
}

extension ImportWalletViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        clearTextBtn.isHidden = false
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = AppTheme.current.primaryTextColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        clearTextBtn.isHidden = true
        if textView.text.isEmpty {
            textView.text = "Input here"
            textView.textColor = .lightGray
        }
        showErrorIfNeeded()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        pasteInfoView.isHidden = true
        
        let height = inputTextView.contentSize.height + TEXT_VIEW_PADDING
        inputViewHeightConstraint.constant = min(height, UIScreen.main.bounds.size.height / 3)
        updateWordCount()
        updateContinueButton()
    }
}
