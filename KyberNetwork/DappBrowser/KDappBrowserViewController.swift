//
//  KDappBrowserViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 24/06/2022.
//

import UIKit
import KrystalJSBridge
import WebKit

class KDappBrowserViewController: UIViewController {
  @IBOutlet weak var navBar: NavigationBar!
  @IBOutlet weak var webView: KWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navBar.setLeftButtonAction { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
    injectJS()
    webView.load(URLRequest(url: URL(string: "http://localhost:3000")!))
  }
  
  func injectJS() {
    loadJS(fileName: "krystal-common.min")
    loadJS(fileName: "krystal-webbridge.min")
    loadJS(fileName: "krystal-solana.min")
  }
  
  func loadJS(fileName: String) {
    let path = Bundle.main.path(forResource: fileName, ofType: "js")!
    let content = try! String(contentsOfFile: path)
    webView.evaluateJavaScript(content, completionHandler: nil)
  }
  
}
