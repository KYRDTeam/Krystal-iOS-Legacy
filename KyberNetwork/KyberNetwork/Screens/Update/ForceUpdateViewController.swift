//
//  ForceUpdateViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/03/2023.
//

import UIKit
import DesignSystem

class ForceUpdateViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseNoteLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var versionConfig: VersionConfig?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messageLabel.attributedText = createMessageText()
        releaseNoteLabel.text = versionConfig?.releaseNote
    }
    
    func createMessageText() -> NSAttributedString {
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.karlaReguler(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
        let highlightAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.karlaReguler(ofSize: 16),
            .foregroundColor: AppTheme.current.primaryColor
        ]
        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "To use Krystal, download the latest version: ", attributes: normalAttrs))
        string.append(NSAttributedString(string: "Version " + (versionConfig?.name ?? ""), attributes: highlightAttrs))
        return string
    }
    
    @IBAction func updateTapped(_ sender: UIButton) {
        
    }
    
}
