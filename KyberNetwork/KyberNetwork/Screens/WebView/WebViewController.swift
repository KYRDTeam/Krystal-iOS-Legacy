//
//  WebViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import UIKit
import WebKit

enum WebType {
  case link(url: URL)
  case htmlContent(content: String)
}

class WebViewController: KNBaseViewController {
  
  @IBOutlet weak var navigationBar: NavigationBar!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var webView: WKWebView!

  let refreshControl = UIRefreshControl()
  
  private var progressObservation: NSKeyValueObservation?
  private var pageTitleObservation: NSKeyValueObservation?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupNavigationBar()
    setupRefreshControl()
    setupObservations()
  }
  
  func setupNavigationBar() {
    
  }
  
  func setupRefreshControl() {
    refreshControl.addTarget(self, action: #selector(reloadWeb), for: .valueChanged)
    webView.scrollView.addSubview(refreshControl)
  }
  
  @objc func reloadWeb(_ sender: UIRefreshControl) {
    webView.reload()
    sender.endRefreshing()
  }
  
  func setupObservations() {
    progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { _, _ in
      let estimatedProgress = self.webView.estimatedProgress
      UIView.animate(withDuration: 0.2) {
        self.progressView.progress = Float(estimatedProgress)
      }
      if estimatedProgress >= 1.0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.progressView.isHidden = true
        }
      } else {
        DispatchQueue.main.async {
          self.progressView.isHidden = false
        }
      }
    }
    pageTitleObservation = webView.observe(\.title, options: [.new]) { _, _ in
      self.navigationBar.title = self.webView.title
    }
  }
  
  func load(webType: WebType) {
    switch webType {
    case .link(let url):
      webView.load(URLRequest(url: url))
    case .htmlContent(let content):
      webView.loadHTMLString(content, baseURL: nil)
    }
  }
  
  deinit {
    progressObservation = nil
    pageTitleObservation = nil
  }
  
}
