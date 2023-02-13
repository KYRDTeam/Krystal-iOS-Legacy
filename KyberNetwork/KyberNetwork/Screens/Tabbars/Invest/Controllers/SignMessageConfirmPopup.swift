//
//  SignMessageConfirmPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/01/2022.
//

import UIKit

struct SignMessageConfirmViewModel {
  let url: String
  let address: String
  let message: String
  let onConfirm: (() -> Void)
  let onCancel: (() -> Void)
  
  var imageIconURL: String {
    return "https://www.google.com/s2/favicons?sz=128&domain=\(self.url)"
  }
  
  var displayMessage: String {
    let data = Data(Array<UInt8>(hex: self.message))
    
    if let str = String(data: data, encoding: .utf8) {
      return str
    } else {
      return self.message
    }
   
  }
}

class SignMessageConfirmPopup: UIViewController {

  @IBOutlet weak var siteIconImageView: UIImageView!
  @IBOutlet weak var siteURLLabel: UILabel!
  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  
  private let transitor = TransitionDelegate()
  private let viewModel: SignMessageConfirmViewModel
  
  init(viewModel: SignMessageConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SignMessageConfirmPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupUI()
  }
  
  private func setupUI() {
    self.fromAddressLabel.text = self.viewModel.address
    self.valueLabel.text = self.viewModel.displayMessage
    self.siteURLLabel.text = self.viewModel.url
    UIImage.loadImageIconWithCache(viewModel.imageIconURL) { image in
      self.siteIconImageView.image = image
    }
    self.confirmButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)
  }

  @IBAction func tapOutsidePopup(_ sender: Any) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel()
    }
  }

  @IBAction func tapInsidePopup(_ sender: Any) {
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel()
    }
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onConfirm()
    }
  }
}


extension SignMessageConfirmPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
