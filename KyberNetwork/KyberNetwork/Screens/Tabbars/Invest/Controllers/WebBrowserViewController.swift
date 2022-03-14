//
//  WebBrowserViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/03/2022.
//

import UIKit
import WebKit

protocol WebBrowserViewControllerDelegate: class {
  func didClose()
}

class WebBrowserViewController: KNBaseViewController {

  let jsBackToWallet = "backToWallet"

  @IBOutlet weak var webView: WKWebView!
  var urlString: String?
  weak var delegate: WebBrowserViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let urlString = self.urlString, let link = URL(string: urlString) {
      let request = URLRequest(url: link)
      self.webView.load(request)
    }

    self.webView.configuration.userContentController.add(self, name: jsBackToWallet)

  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.webView.configuration.userContentController.removeScriptMessageHandler(forName: jsBackToWallet)

  }
  
  @IBAction func closeButtonTapped(_ sender: Any) {
    self.delegate?.didClose()
  }
  
  @IBAction func optionButtonTapped(_ sender: Any) {

  }
  
  func checkContainOrder() {
    
  }
}

extension WebBrowserViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == jsBackToWallet {
      print("hehehe")
    }
  }
}
