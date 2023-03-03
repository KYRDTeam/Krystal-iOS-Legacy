//
//  OverviewChangeCurrencyViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 7/13/21.
//

import UIKit

class OverviewChangeCurrencyViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var quoteCurrencyView: UIView!
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  @IBOutlet weak var btcButton: UIButton!
  @IBOutlet weak var quoteTokenLabel: UILabel!
  @IBOutlet weak var tapOutsideBackgroundView: UIView!
  var selected: CurrencyMode = .usd
  var completeHandle: ((CurrencyMode) -> Void)?
  var shouldShowQuote: Bool = true

  init() {
    if let savedCurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) {
      self.selected = savedCurrencyMode
    }
    super.init(nibName: OverviewChangeCurrencyViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.quoteTokenLabel.text = KNGeneralProvider.shared.quoteCurrency.toString().uppercased()
    self.updateUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
  
  fileprivate func updateUI() {
    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0
      
    self.quoteCurrencyView.isHidden = !self.shouldShowQuote
    self.usdButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == .usd ? selectedWidth : normalWidth,
      radius: 8
    )
    
    self.ethButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == KNGeneralProvider.shared.quoteCurrency ? selectedWidth : normalWidth,
      radius: 8
    )
    
    self.btcButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == .btc ? selectedWidth : normalWidth,
      radius: 8
    )
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.tapOutsideBackgroundView.addGestureRecognizer(tapGesture)
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func currencyTypeButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 0:
      self.selected = .usd
    case 1:
      self.selected = KNGeneralProvider.shared.quoteCurrency
    case 2:
      self.selected = .btc
    default:
      self.selected = .usd
    }
    self.updateUI()
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      if let handle = self.completeHandle {
        handle(self.selected)
      }
    })
  }
}

extension OverviewChangeCurrencyViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 300
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
