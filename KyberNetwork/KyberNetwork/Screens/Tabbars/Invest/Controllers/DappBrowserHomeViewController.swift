//
//  DappBrowserHomeViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import UIKit

enum DappBrowserHomeEvent {
  case enterText(text: String)
}

protocol DappBrowserHomeViewControllerDelegate: class {
  func dappBrowserHomeViewController(_ controller: DappBrowserHomeViewController, run event: DappBrowserHomeEvent)
}


class DappBrowserHomeViewController: UIViewController {
  
  weak var delegate: DappBrowserHomeViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  
}

extension DappBrowserHomeViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: textField.text ?? ""))
    textField.resignFirstResponder()
    return true
  }
}
