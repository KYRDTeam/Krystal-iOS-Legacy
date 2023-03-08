//
//  WelcomeViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 08/03/2023.
//

import UIKit
import DesignSystem

protocol WelcomeViewControllerDelegate: class {
    func didTapCreate(controller: UIViewController)
    func didTapImport(controller: UIViewController)
    func didTapExplore(controller: UIViewController)
}

class WelcomeViewController: UIViewController {
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var termOfUseTextView: UITextView!
    @IBOutlet weak var shadowView: UIView!
    
    weak var delegate: WelcomeViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        shadowView.layer.shadowColor = AppTheme.current.primaryColor.cgColor
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 70
        shadowView.layer.shadowOffset = .zero
    }
    
    func configUI() {
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
        
        importButton.layer.borderColor = AppTheme.current.primaryColor.cgColor
        importButton.layer.borderWidth = 1.0
    }

    @IBAction func createWalletButtonTapped(_ sender: Any) {
        delegate?.didTapCreate(controller: self)
    }
    
    @IBAction func exploreButtonTapped(_ sender: Any) {
        delegate?.didTapExplore(controller: self)
    }
    
    @IBAction func importButtonTapped(_ sender: Any) {
        delegate?.didTapImport(controller: self)
    }
    
}
