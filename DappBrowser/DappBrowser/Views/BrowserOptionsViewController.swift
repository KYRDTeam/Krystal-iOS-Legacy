//
//  BrowserOptionsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 28/12/2021.
//

import UIKit
import UniformTypeIdentifiers
import BaseModule

enum BrowserOptionsViewEvent: Int {
    case back = 1
    case forward
    case refresh
    case share
    case copy
    case favourite
    case switchWallet
}

protocol BrowserOptionsViewControllerDelegate: class {
    func browserOptionsViewController(_ controller: BrowserOptionsViewController, run event: BrowserOptionsViewEvent)
}

class BrowserOptionsViewController: UIViewController {
    
    @IBOutlet weak var favoriteStatusLabel: UILabel!
    @IBOutlet weak var favoriteStatusIcon: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var favoriteContainView: UIView!
    @IBOutlet weak var switchWalletContainView: UIView!
    @IBOutlet weak var switchWalletLabel: UILabel!
    @IBOutlet weak var switchWalletIcon: UIImageView!
    @IBOutlet weak var switchWalletButton: UIButton!
    
    weak var delegate: BrowserOptionsViewControllerDelegate?
    let url: String
    let canGoBack: Bool
    let canForward: Bool
    var isNormalBrowser = false
    
    init(url: String, canGoBack: Bool, canGoForward: Bool) {
        self.url = url
        self.canGoBack = canGoBack
        self.canForward = canGoForward
        super.init(nibName: BrowserOptionsViewController.className, bundle: Bundle(for: BrowserOptionsViewController.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if BrowserStorage.shared.isFaved(url: self.url) {
            self.favoriteStatusIcon.image = UIImage(named: "unfavorite_actionsheet_icon")
            self.favoriteStatusLabel.text = "Unfavorite"
        } else {
            self.favoriteStatusIcon.image = UIImage(named: "favorite_actionsheet_icon")
            self.favoriteStatusLabel.text = "Favorite"
        }
        
        if self.isNormalBrowser {
            self.favoriteButton.isUserInteractionEnabled = false
            self.favoriteStatusLabel.isHidden = true
            self.favoriteStatusIcon.isHidden = true
            self.favoriteContainView.backgroundColor = UIColor.clear
            
            self.switchWalletButton.isUserInteractionEnabled = false
            self.switchWalletIcon.isHidden = true
            self.switchWalletLabel.isHidden = true
            self.switchWalletContainView.backgroundColor = UIColor.clear
        }
        
        if !self.canGoBack {
            self.backButton.isEnabled = false
            self.backButton.backgroundColor = self.view.backgroundColor?.withAlphaComponent(0.4)
        }
        
        if !self.canForward {
            self.forwardButton.isEnabled = false
            self.forwardButton.backgroundColor = self.view.backgroundColor?.withAlphaComponent(0.4)
        }
    }
    
    @IBAction func optionButtonTapped(_ sender: UIButton) {
        guard let option = BrowserOptionsViewEvent(rawValue: sender.tag) else { return }
        self.dismiss(animated: true) {
            self.delegate?.browserOptionsViewController(self, run: option)
        }
    }
}
