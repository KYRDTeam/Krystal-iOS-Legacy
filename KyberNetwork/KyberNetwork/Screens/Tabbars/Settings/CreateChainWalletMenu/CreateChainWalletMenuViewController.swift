//
//  CreateChainWalletViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import UIKit

class CreateChainWalletMenuViewController: UIViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  
  var viewModel: CreateChainWalletMenuViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  func setupViews() {
    titleLabel.text = viewModel.title
    messageLabel.text = viewModel.subtitle
  }
  
  @IBAction func createNewWasTapped(_ sender: Any) {
    viewModel.didTapCreateNewWallet()
  }
  
  @IBAction func importWasTapped(_ sender: Any) {
    viewModel.didTapImportWallet()
  }
  
  @IBAction func outsideWasTapped(_ sender: Any) {
    viewModel.didTapClose()
  }
  
}

extension CreateChainWalletMenuViewController: BottomPopUpAbstract {
  
  func setTopContrainConstant(value: CGFloat) {
    topConstraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 360
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
