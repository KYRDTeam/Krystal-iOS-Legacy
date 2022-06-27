//
//  KDappBrowserViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 24/06/2022.
//

import UIKit
import KrystalJSBridge

class KDappBrowserViewController: UIViewController {
  @IBOutlet weak var navBar: NavigationBar!
  @IBOutlet weak var webView: KWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navBar.setLeftButtonAction { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
    
    webView.load(URLRequest(url: URL(string: "http://localhost:3000")!))
  }
  
}
