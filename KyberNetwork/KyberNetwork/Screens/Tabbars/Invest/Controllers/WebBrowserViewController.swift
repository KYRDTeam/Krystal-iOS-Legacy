//
//  WebBrowserViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/03/2022.
//

import UIKit
import WebKit
import MBProgressHUD

protocol WebBrowserViewControllerDelegate: class {
  func didClose()
}

class WebBrowserViewController: KNBaseViewController {

  let jsBackToWallet = "backToWallet"

  @IBOutlet weak var webView: WKWebView!
  var urlString: String?
  weak var delegate: WebBrowserViewControllerDelegate?

  init() {
    super.init(nibName: WebBrowserViewController.className, bundle: nil)
    self.modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
    self.dismiss(animated: true) {
      self.delegate?.didClose()
    }
  }

  @IBAction func optionButtonTapped(_ sender: Any) {
    let controller = BrowserOptionsViewController(
      url: "url",
      canGoBack: true,
      canGoForward: true
    )
    controller.delegate = self
    controller.isNormalBrowser = true
    self.present(controller, animated: true, completion: nil)
  }
}

extension WebBrowserViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == jsBackToWallet {
      self.dismiss(animated: true) {
        self.delegate?.didClose()
      }
    }
  }
}

extension WebBrowserViewController: BrowserOptionsViewControllerDelegate {
  func browserOptionsViewController(_ controller: BrowserOptionsViewController, run event: BrowserOptionsViewEvent) {
    switch event {
    case .back:
      self.webView.goBack()
    case .forward:
      self.webView.goForward()
    case .refresh:
      self.webView.reload()
    case .share:
      guard let text = self.webView.url?.absoluteString else { return }
      let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
      activitiy.popoverPresentationController?.sourceView = self.navigationController?.view!
      self.present(activitiy, animated: true, completion: nil)
    case .copy:
      guard let text = self.webView.url?.absoluteString else { return }
      UIPasteboard.general.string = text
      let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    default:
      return
    }
  }
}
