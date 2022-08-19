//
//  BackUpWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/08/2022.
//

import UIKit

protocol BackUpWalletViewControllerDelegate: class {
  func didFinishBackup(_ controller: BackUpWalletViewController)
}

class BackUpWalletViewModel {
  let seeds: [String]
  init(seeds: [String]) {
    self.seeds = seeds
  }
}

class BackUpWalletViewController: KNBaseViewController {
  @IBOutlet var wordLabels: [UILabel]!
  @IBOutlet weak var revealView: UIView!
  @IBOutlet weak var seedView: UIView!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var infoLabel1: UILabel!
  @IBOutlet weak var infoLabel2: UILabel!
  @IBOutlet weak var infoLabel3: UILabel!
  fileprivate var viewModel: BackUpWalletViewModel
  
  weak var delegate: BackUpWalletViewControllerDelegate?

  init(viewModel: BackUpWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: BackUpWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  func setupUI() {
    for index in 0..<viewModel.seeds.count {
      let label = wordLabels.first(where: { $0.tag == index })
      label?.text = index < 9 ? " \(index + 1). " + viewModel.seeds[index] : "\(index + 1). " + viewModel.seeds[index]
    }
    infoLabel1.attributedText = self.getDescriptionAttributedString(baseString: "Recovery phrase is a list of 12 secret words that back up your wallet.", highlightString: "12 secret words")
    infoLabel2.attributedText = self.getDescriptionAttributedString(baseString: "If you ever lose your device, Recovery Phrase is the only way to recover your wallet and your funds.", highlightString: "the only way")
    infoLabel3.attributedText = self.getDescriptionAttributedString(baseString: "Find a safe and private place to write down the recovery phrase; keep it somewhere safe and do not share with anyone.", highlightString: "do not share")
  }
  
  func getDescriptionAttributedString(baseString: String, highlightString: String) -> NSAttributedString {
    let regularttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 16),
      NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!
    ]
    let highlightAttribute: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 16),
      NSAttributedString.Key.foregroundColor: UIColor(named: "textRedColor")!
    ]
    
    let listOfWords = NSString(string:baseString)
    let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: "\(listOfWords) ", attributes: regularttributes)
    let highlightRange = listOfWords.range(of: highlightString)
    attributedString.setAttributes(highlightAttribute, range: highlightRange)
    return attributedString
  }

  @IBAction func revealButtonTapped(_ sender: Any) {
    revealView.isHidden = true
    seedView.isHidden = false
    continueButton.isHidden = false
  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyButtonTapped(_ sender: Any) {
    UIPasteboard.general.string = viewModel.seeds.joined(separator: " ")
    self.showMessageWithInterval(message: Strings.copied)
  }

  @IBAction func continueButtonTapped(_ sender: Any) {
    let confirmVC = ConfirmBackupViewController()
    confirmVC.delegate = self
    confirmVC.seedStrings = viewModel.seeds
    self.show(confirmVC, sender: nil)
  }
}

extension BackUpWalletViewController: ConfirmBackupViewControllerDelegate {
  func didFinishBackup(_ controller: ConfirmBackupViewController) {
    self.delegate?.didFinishBackup(self)
  }
}
