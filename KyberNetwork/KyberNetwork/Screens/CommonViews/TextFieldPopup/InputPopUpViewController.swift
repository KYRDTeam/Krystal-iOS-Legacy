//
//  InputPopUpViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/24/20.
//

import UIKit
import IQKeyboardManager

class InputPopUpViewModel {
  let mainTitle: String
  let description: String
  let doneButtonTitle: String
  var value: String
  var completeHandle: ((String) -> Void)?

  init(mainTitle: String, description: String, doneButtonTitle: String, value: String, completeHandle: ((String) -> Void)?) {
    self.mainTitle = mainTitle
    self.description = description
    self.doneButtonTitle = doneButtonTitle
    self.completeHandle = completeHandle
    self.value = value
  }
}

class InputPopUpViewController: KNBaseViewController {
  @IBOutlet weak var mainTitleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var inputTextField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let viewModel: InputPopUpViewModel

  init(viewModel: InputPopUpViewModel) {
    self.viewModel = viewModel
    super.init(nibName: InputPopUpViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.inputTextField.text = self.viewModel.value
    self.inputTextField.inputAccessoryView = UIView()
    self.inputTextField.rounded(radius: 8)
    IQKeyboardManager.shared().keyboardDistanceFromTextField = 100
    self.doneButton.rounded(radius: self.doneButton.frame.size.height / 2)
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.doneButton.removeSublayer(at: 0)
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.inputTextField.becomeFirstResponder()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    IQKeyboardManager.shared().keyboardDistanceFromTextField = 10
  }

  @IBAction func doneButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      guard !(self.inputTextField.text?.isEmpty ?? true), self.inputTextField.text != self.viewModel.value else { return }
      if let handle = self.viewModel.completeHandle {
        handle(self.inputTextField.text ?? "")
      }
    }
  }

  @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension InputPopUpViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 218
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
