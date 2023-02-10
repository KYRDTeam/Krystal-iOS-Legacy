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
import KrystalWallets

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
  case openOption(url: String)
  case switchChain
  case addChainWallet(chainType: ChainType)
}

protocol BrowserViewControllerDelegate: class {
  func browserViewController(_ controller: BrowserViewController, run event: BrowserViewEvent)
  func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: BrowserViewController)
}

class BrowserViewModel {
  var url: URL
  var address: KAddress
  
  init(url: URL, address: KAddress) {
    self.url = url
    self.address = address
  }
  
  var webIconURL: String {
    return "https://www.google.com/s2/favicons?sz=128&domain=\(self.url.absoluteString)/"
  }
}

class BrowserViewController: KNBaseViewController {
  
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var webViewContainerView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!
  
  let viewModel: BrowserViewModel
  weak var delegate: BrowserViewControllerDelegate?
  
  lazy var config: WKWebViewConfiguration = {
    let config = WKWebViewConfiguration.make(forType: .dappBrowser, address: self.viewModel.address.addressString, in: ScriptMessageProxy(delegate: self))
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
  
  lazy var progressView: UIProgressView = {
    let progressView = UIProgressView(progressViewStyle: .default)
    progressView.translatesAutoresizingMaskIntoConstraints = false
    progressView.tintColor = UIColor(named: "buttonBackgroundColor")
    progressView.trackTintColor = .clear
    return progressView
  }()
  
  private var estimatedProgressObservation: NSKeyValueObservation?
  
  init(viewModel: BrowserViewModel) {
    self.viewModel = viewModel
    super.init(nibName: BrowserViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    estimatedProgressObservation?.invalidate()
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = self.viewModel.url.absoluteString
    self.updateUISwitchChain()
    webView.translatesAutoresizingMaskIntoConstraints = false
    self.webViewContainerView.addSubview(self.webView)
    self.webView.topAnchor.constraint(equalTo: self.webViewContainerView.topAnchor).isActive = true
    self.webView.bottomAnchor.constraint(equalTo: self.webViewContainerView.bottomAnchor).isActive = true
    self.webView.leftAnchor.constraint(equalTo: self.webViewContainerView.leftAnchor).isActive = true
    self.webView.rightAnchor.constraint(equalTo: self.webViewContainerView.rightAnchor).isActive = true

    webView.addSubview(progressView)
    webView.bringSubviewToFront(progressView)

    NSLayoutConstraint.activate([
        progressView.topAnchor.constraint(equalTo: self.webViewContainerView.topAnchor),
        progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
        progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
        progressView.heightAnchor.constraint(equalToConstant: 2)
    ])
    
    estimatedProgressObservation = webView.observe(\.estimatedProgress) { [weak self] webView, _ in
        guard let strongSelf = self else { return }

        let progress = Float(webView.estimatedProgress)

        strongSelf.progressView.progress = progress
        strongSelf.progressView.isHidden = progress == 1
    }

    webView.load(URLRequest(url: self.viewModel.url))

    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  @IBAction func dismissButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func optionsButtonTapped(_ sender: UIButton) {
    self.delegate?.browserViewController(self, run: .openOption(url: self.viewModel.url.absoluteString))
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
    Tracker.track(event: .dappBack, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
  }

  func coodinatorDidReceiveForwardEvent() {
    self.webView.goForward()
    Tracker.track(event: .dappForward, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
  }

  func coodinatorDidReceiveRefreshEvent() {
    self.webView.reload()
    Tracker.track(event: .dappRefresh, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
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
    Tracker.track(event: .dappShare, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
  }

  func coodinatorDidReceiveCopyEvent() {
    UIPasteboard.general.string = self.viewModel.url.absoluteString
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
    Tracker.track(event: .dappCopy, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
  }

  func coodinatorDidReceiveFavoriteEvent() {
    let item = BrowserItem(
      title: self.webView.title ?? "",
      url: self.viewModel.url.absoluteString,
      image: self.viewModel.webIconURL,
      time: Date().currentTimeMillis()
    )
    let isFaved = BrowserStorage.shared.isFaved(url: self.viewModel.url.absoluteString)
    
    if isFaved {
      BrowserStorage.shared.deleteFavoriteItem(item)
    } else {
      BrowserStorage.shared.addNewFavorite(item: item)
    }
    Tracker.track(event: .dappFavorite, customAttributes: ["title": self.navTitleLabel.text ?? "", "url": self.viewModel.url])
  }
  
  func coodinatorDidReceiveSwitchWalletEvent() {
    
  }
  
  private func saveBrowserIfNeeded() {
    guard self.viewModel.url.host != SearchEngine.default.host else { return }
    let item = BrowserItem(
      title: self.webView.title ?? "",
      url: self.viewModel.url.absoluteString,
      image: self.viewModel.webIconURL,
      time: Date().currentTimeMillis()
    )
    BrowserStorage.shared.addNewRecently(item: item)
  }
  
  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
  }
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { [weak self] selected in
      guard let self = self else { return }
      let addresses = WalletManager.shared.getAllAddresses(addressType: selected.addressType)
      if addresses.isEmpty {
        self.delegate?.browserViewController(self, run: .addChainWallet(chainType: selected))
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selected)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.present(popup, animated: true, completion: nil)
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else {
      return
    }
    self.updateUISwitchChain()
  }
  
  @objc private func keyboardWillShow(notification: NSNotification) {
      if let keyboardEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let _ = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue {
          webView.scrollView.contentInset.bottom = keyboardEndFrame.size.height
      }
  }

  @objc private func keyboardWillHide(notification: NSNotification) {
    guard let beginRect = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let endRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
    let isExternalKeyboard = beginRect.origin == endRect.origin && (beginRect.size.height == 0 || endRect.size.height == 0)
    let isEnteringEditModeWithExternalKeyboard: Bool
    if isExternalKeyboard {
      isEnteringEditModeWithExternalKeyboard = beginRect.size.height == 0 && endRect.size.height > 0
    } else {
      isEnteringEditModeWithExternalKeyboard = false
    }
    if !isExternalKeyboard || !isEnteringEditModeWithExternalKeyboard {
      webView.scrollView.contentInset.bottom = 0
    }
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
    self.navTitleLabel.text = webView.title
      if let unwrap = webView.url, unwrap.absoluteString != "about:blank" {
      self.viewModel.url = unwrap
      self.saveBrowserIfNeeded()
    }
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = navigationAction.request.url, let scheme = url.scheme else {
      return decisionHandler(.allow)
    }
    self.navTitleLabel.text = webView.title
      if url.absoluteString != "about:blank" {
          self.viewModel.url = url
      }
    
    let app = UIApplication.shared
    if ["tel", "mailto"].contains(scheme), app.canOpenURL(url) {
      app.open(url)
      return decisionHandler(.cancel)
    }

    if scheme == "itms-apps" {
      let urlString = url.absoluteString.replacingOccurrences(of: "itms-apps", with: "https")
      if let httpURL = URL(string: urlString), app.canOpenURL(httpURL) {
        app.open(httpURL)
      }
      return decisionHandler(.cancel)
    }
    if navigationAction.navigationType == .linkActivated {
      self.webView.load(URLRequest(url: url))
    }
    decisionHandler(.allow)
  }
}
