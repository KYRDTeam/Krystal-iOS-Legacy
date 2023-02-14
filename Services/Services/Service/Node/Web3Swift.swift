//
//  Web3Swift.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import WebKit
import JavaScriptKit
import Result
import JavaScriptCore

class Web3Swift: NSObject {
    
    let webView = WKWebView()
    let url: URL
    var isLoaded = false
    
    init(url: URL = URL(string: "http://localhost:8545")!) {
        self.url = url
        super.init()
        self.start()
    }
    
    func start() {
        self.webView.navigationDelegate = self
        
        loadWeb3()
    }
    
    private func loadWeb3() {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.load(URLRequest(url: url))
        }
    }
    
    func request<T: Web3Request>(request: T, completion: @escaping (Swift.Result<T.Response, AnyError>) -> Void) {
        guard isLoaded else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 250)) {
                self.request(request: request, completion: completion)
            }
            return
        }
        
        switch request.type {
        case .function(let command):
            webView.evaluate(expression: JSFunction<T.Response>(command)) { result in
                switch result {
                case .success(let result):
                    NSLog("request function result \(result)")
                    completion(.success(result))
                case .failure(let error):
                    NSLog("request function error \(error)")
                    completion(.failure(AnyError(error)))
                }
            }
        case .variable(let command):
            webView.evaluate(expression: JSVariable<T.Response>(command)) { result in
                switch result {
                case .success(let result):
                    NSLog("variable \(result)")
                    completion(.success(result))
                case .failure(let error):
                    NSLog("variable error \(error)")
                    completion(.failure(AnyError(error)))
                }
            }
        case .script(let command):
            webView.evaluate(expression: JSScript<T.Response>(command)) { result in
                switch result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    NSLog("script error \(error)")
                    completion(.failure(AnyError(error)))
                }
            }
        }
    }
    
}

extension Web3Swift: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        
        webView.evaluate(expression: JSVariable<String>("web3.setProvider(new web3.providers.HttpProvider('\(url.absoluteString))"), completionHandler: nil)
    }
}
