//
//  BrowserOptionsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 28/12/2021.
//

import UIKit
import UniformTypeIdentifiers

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

class BrowserOptionsViewController: KNBaseViewController {
  
  @IBOutlet weak var favoriteStatusLabel: UILabel!
  @IBOutlet weak var favoriteStatusIcon: UIImageView!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var forwardButton: UIButton!
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  weak var delegate: BrowserOptionsViewControllerDelegate?
  let url: String
  let canGoBack: Bool
  let canForward: Bool
  
  init(url: String, canGoBack: Bool, canGoForward: Bool) {
    self.url = url
    self.canGoBack = canGoBack
    self.canForward = canGoForward
    super.init(nibName: BrowserOptionsViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
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
    
    if !self.canGoBack {
      self.backButton.isEnabled = false
      self.backButton.backgroundColor = .white.withAlphaComponent(0.5)
    }
    
    if !self.canForward {
      self.forwardButton.isEnabled = false
      self.forwardButton.backgroundColor = .white.withAlphaComponent(0.5)
    }
  }
  
  @IBAction func optionButtonTapped(_ sender: UIButton) {
    guard let option = BrowserOptionsViewEvent(rawValue: sender.tag) else { return }
    self.dismiss(animated: true) {
      self.delegate?.browserOptionsViewController(self, run: option)
    }
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension BrowserOptionsViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 430
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
