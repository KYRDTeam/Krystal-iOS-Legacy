//
//  BrowserViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 22/12/2021.
//

import UIKit
import WebKit
import TrustKeystore
import MBProgressHUD

///Reason for this class: https://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {

    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(
            userContentController, didReceive: message)
    }
}

enum BrowserViewEvent {
  case openOption
  case switchChain
}

protocol BrowserViewControllerDelegate: class {
  func browserViewController(_ controller: BrowserViewController, run event: BrowserViewEvent)
  func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: BrowserViewController)
}

class BrowserViewModel {
  var url: URL
  var account: Account
  
  init(url: URL, account: Account) {
    self.url = url
    self.account = account
  }
}

class BrowserViewController: KNBaseViewController {
  
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var webViewContainerView: UIView!
  
  
  let viewModel: BrowserViewModel
  weak var delegate: BrowserViewControllerDelegate?
  
  lazy var config: WKWebViewConfiguration = {
    let config = WKWebViewConfiguration.make(forType: .dappBrowser, address: self.viewModel.account.address, in: ScriptMessageProxy(delegate: self))
      config.websiteDataStore = WKWebsiteDataStore.default()
      return config
  }()
  
  lazy var webView: WKWebView = {
    let webView = WKWebView(
      frame: .zero,
      configuration: config
    )
    webView.allowsBackForwardNavigationGestures = true
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.navigationDelegate = self
    if isDebug {
      webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    }
    webView.navigationDelegate = self
    return webView
  }()
  
  init(viewModel: BrowserViewModel) {
    self.viewModel = viewModel
    super.init(nibName: BrowserViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = self.viewModel.url.absoluteString
    webView.translatesAutoresizingMaskIntoConstraints = false
    self.webViewContainerView.addSubview(self.webView)
    self.webView.topAnchor.constraint(equalTo: self.webViewContainerView.topAnchor).isActive = true
    self.webView.bottomAnchor.constraint(equalTo: self.webViewContainerView.bottomAnchor).isActive = true
    self.webView.leftAnchor.constraint(equalTo: self.webViewContainerView.leftAnchor).isActive = true
    self.webView.rightAnchor.constraint(equalTo: self.webViewContainerView.rightAnchor).isActive = true
    
    webView.load(URLRequest(url: self.viewModel.url))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
  
  @IBAction func dismissButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func optionsButtonTapped(_ sender: UIButton) {
    self.delegate?.browserViewController(self, run: .openOption)
  }
  
  func coordinatorNotifyFinish(callbackID: Int, value: Result<DappCallback, DAppError>) {
    print("[Dapp] \(callbackID) \(value)")
      let script: String = {
          switch value {
          case .success(let result):
              return "executeCallback(\(callbackID), null, \"\(result.value.object)\")"
          case .failure(let error):
              return "executeCallback(\(callbackID), \"\(error.message)\", null)"
          }
      }()
      webView.evaluateJavaScript(script, completionHandler: nil)
  }
  
  func coodinatorDidReceiveBackEvent() {
    self.webView.goBack()
  }

  func coodinatorDidReceiveForwardEvent() {
    self.webView.goForward()
  }

  func coodinatorDidReceiveRefreshEvent() {
    self.webView.reload()
  }
  
  func coodinatorDidReceiveShareEvent() {
    let text = NSLocalizedString(
      self.viewModel.url.absoluteString,
      value: self.viewModel.url.absoluteString,
      comment: ""
    )
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.navigationController?.view!
    self.navigationController?.present(activitiy, animated: true, completion: nil)
  }
  
  func coodinatorDidReceiveCopyEvent() {
    UIPasteboard.general.string = self.viewModel.url.absoluteString
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func coodinatorDidReceiveFavoriteEvent() {
    
  }
  
  func coodinatorDidReceiveSwitchWalletEvent() {
    
  }
}

extension BrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let command = DappAction.fromMessage(message) else {
            
            return
        }
        let action = DappAction.fromCommand(command)
        delegate?.didCall(action: action, callbackID: command.id, inBrowserViewController: self)
    }
}

extension BrowserViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    //        recordURL()
    //        hideErrorView()
  }
  
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    //        hideErrorView()
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    //        handleError(error: error)
  }
  
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    //        handleError(error: error)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = navigationAction.request.url, let scheme = url.scheme else {
      
      return decisionHandler(.allow)
    }

    self.navTitleLabel.text = webView.title
    self.viewModel.url = url
    let app = UIApplication.shared
    if ["tel", "mailto"].contains(scheme), app.canOpenURL(url) {
      app.open(url)
      return decisionHandler(.cancel)
    }
    
    decisionHandler(.allow)
  }
}
