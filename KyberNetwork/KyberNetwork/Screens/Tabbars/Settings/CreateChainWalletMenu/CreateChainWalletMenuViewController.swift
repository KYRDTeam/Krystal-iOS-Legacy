//
//  CreateChainWalletViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import UIKit

protocol CreateChainWalletMenuViewProtocol: AnyObject {
  
}

class CreateChainWalletMenuViewController: UIViewController, CreateChainWalletMenuViewProtocol {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  
  var coordinator: CreateChainWalletMenuCoordinator?
  var presenter: CreateChainWalletMenuPresenterProtocol?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  func setupViews() {
    titleLabel.text = presenter?.title
    messageLabel.text = presenter?.subtitle
  }
  
  @IBAction func createNewWasTapped(_ sender: Any) {
    coordinator?.selectCreateNewWallet()
  }
  
  @IBAction func importWasTapped(_ sender: Any) {
    coordinator?.selectImportWallet()
  }
  
  @IBAction func outsideWasTapped(_ sender: Any) {
    dismiss(animated: true) { [weak self] in
      self?.coordinator?.onClose()
    }
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
