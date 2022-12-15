//
//  WebViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import UIKit
import WebKit
import TrustWeb3Provider
import AppState

class BrowserViewController: UIViewController {
    @IBOutlet weak var navigationBar: NavigationBar!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var webViewContainer: UIView!
    
    var webView: WKWebView!
    
    private var progressObservation: NSKeyValueObservation?
    private var pageTitleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    
    var current: TrustWeb3Provider!
    var krystalScriptHandler: KrystalScriptHandler!
    var web3ScriptHandler: Web3ScriptHandler!
    
    let krystalScriptHandlerName = "krystal"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initScriptHandlers()
        initNavigationBar()
        initWebView()
        observeNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        krystalScriptHandler?.setNavigationController(navigationController: navigationController!)
    }

    func observeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onAddressChange), name: .appAddressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onChainChange), name: .appChainChanged, object: nil)
    }
    
    @objc func onAddressChange() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onChainChange() {
        if AppState.shared.currentChain == .solana {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func initNavigationBar() {
        navigationBar.setLeftButtonAction {
            if self.webView.canGoBack {
                self.webView.goBack()
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func initScriptHandlers() {
        krystalScriptHandler = KrystalScriptHandler()
        web3ScriptHandler = Web3ScriptHandler()
        web3ScriptHandler.webview = webView
        web3ScriptHandler.viewController = self
    }
    
    func initConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        
        let source: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(script)
        
        userContentController.addUserScript(web3ScriptHandler.current.providerScript)
        userContentController.addUserScript(web3ScriptHandler.current.injectScript)
        userContentController.add(web3ScriptHandler, name: TrustWeb3Provider.scriptHandlerName)
        userContentController.add(krystalScriptHandler, name: krystalScriptHandlerName)
        configuration.userContentController = userContentController
        return configuration
    }
    
    func initWebView() {
        webView?.removeFromSuperview()
        webView = WKWebView(frame: .zero, configuration: initConfiguration())
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.uiDelegate = self
        webViewContainer.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor),
        ])
        
        web3ScriptHandler.webview = webView
        
        setupRefreshControl()
        setupObservations()
    }
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.white.withAlphaComponent(0.8)
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
    
    func loadNewPage(url: URL) {
        initWebView()
        webView.load(URLRequest(url: url))
    }
    
    deinit {
        progressObservation = nil
        pageTitleObservation = nil
        NotificationCenter.default.removeObserver(self, name: .appAddressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appChainChanged, object: nil)
    }
    
}

extension BrowserViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: completionHandler)
    }
    
}
