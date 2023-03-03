//
//  ImportWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 27/02/2023.
//

import UIKit
import DesignSystem
import KrystalWallets

class ImportWalletViewController: UIViewController {
    @IBOutlet weak var wordCountLabel: UILabel!
    @IBOutlet weak var pasteImageView: UIImageView!
    @IBOutlet weak var pasteInfoView: UILabel!
    @IBOutlet weak var clearTextBtn: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var pasteButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pasteView: UIView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButton: UIButton!
    
    let TEXT_VIEW_PADDING = CGFloat(13)

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.isEnabled = false
        continueButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
        continueButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .disabled)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configUI()
    }
    
    func configUI() {
        pasteView.isHidden = UIPasteboard.general.string == nil
        inputTextView.delegate = self
        inputTextView.text = "Input here"
        inputTextView.textColor = .lightGray
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func scanButtonTapped(_ sender: Any) {
        var acceptedResultTypes: [ScanResultType] = [ .ethPublicKey, .ethPrivateKey, .solPublicKey, .solPrivateKey]
        var scanModes: [ScanMode] = [.qr]
        ScannerModule.start(previousScreen: ScreenName.importWallet, viewController: self, acceptedResultTypes: acceptedResultTypes, scanModes: scanModes) { [weak self] text, type in
            guard let self = self else { return }
            self.updateTextInput(value: text)
        }
    }

    @IBAction func clearTextButtonTapped(_ sender: Any) {
        inputTextView.text = nil
        inputViewHeightConstraint.constant = 48
        updateWordCount()
    }

    @IBAction func hintButtonTapped(_ sender: Any) {
        let tipVC = SecurityTipsViewController.instantiateFromNib()
        self.navigationController?.pushViewController(tipVC, animated: true)
    }
    
    @IBAction func pasteButtonTapped(_ sender: Any) {
        if let string = UIPasteboard.general.string {
            updateTextInput(value: string)
        }
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        
    }
    
    func updateTextInput(value: String) {
        inputTextView.text = value
        inputTextView.textColor = AppTheme.current.primaryTextColor
        inputViewHeightConstraint.constant = inputTextView.contentSize.height + TEXT_VIEW_PADDING
    }
    
    func wordCount() -> Int {
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
        return text.count == 64 || SolanaUtils.isValidSolanaPrivateKey(text: text)
    }
    
    func isValidInput() -> Bool {
        return isValidWordCount() || isValidPrivateKey()
    }
    
    func updateWordCount() {
        wordCountLabel.text = "Word count: \(wordCount())"
        wordCountLabel.textColor = isValidInput() ? AppTheme.current.primaryTextColor : AppTheme.current.errorTextColor
    }
    
    func updateContinueButton() {
        continueButton.isEnabled = isValidInput()
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
    }
    
    func textViewDidChange(_ textView: UITextView) {
        inputViewHeightConstraint.constant = textView.contentSize.height + TEXT_VIEW_PADDING
        updateWordCount()
        updateContinueButton()
    }
}
