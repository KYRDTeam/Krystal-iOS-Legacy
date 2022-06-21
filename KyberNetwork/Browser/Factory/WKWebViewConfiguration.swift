// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import WebKit
import JavaScriptCore
import TrustCore

enum WebViewType {
    case dappBrowser
    case tokenScriptRenderer
}

extension WKWebViewConfiguration {

    static func make(forType type: WebViewType, address: String, in messageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let webViewConfig = WKWebViewConfiguration()
        var js = ""

        switch type {
        case .dappBrowser:
            if let path = Bundle.main.path(forResource: "KrystalWallet-min", ofType: "js") {
                do {
                    js += try String(contentsOfFile: path)
                } catch { }
            }
            js += javaScriptForDappBrowser(address: address)
        case .tokenScriptRenderer:
//            js += javaScriptForTokenScriptRenderer(address: address)
//            js += """
//                  \n
//                  web3.tokens = {
//                      data: {
//                          currentInstance: {
//                          },
//                          token: {
//                          },
//                          card: {
//                          },
//                      },
//                      dataChanged: (old, updated, tokenCardId) => {
//                        console.log(\"web3.tokens.data changed. You should assign a function to `web3.tokens.dataChanged` to monitor for changes like this:\\n    `web3.tokens.dataChanged = (old, updated, tokenCardId) => { //do something }`\")
//                      }
//                  }
//                  """
          break
        }
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webViewConfig.userContentController.addUserScript(userScript)

        switch type {
        case .dappBrowser:
            break
        case .tokenScriptRenderer:
            //TODO enable content blocking rules to support whitelisting
            webViewConfig.setURLSchemeHandler(webViewConfig, forURLScheme: "tokenscript-resource")
        }

        HackToAllowUsingSafaryExtensionCodeInDappBrowser.injectJs(to: webViewConfig)

        webViewConfig.userContentController.add(messageHandler, name: Method.signTransaction.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: Method.signPersonalMessage.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: Method.signMessage.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: Method.signTypedMessage.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: Method.ethCall.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: AddCustomChainCommand.Method.walletAddEthereumChain.rawValue)
        webViewConfig.userContentController.add(messageHandler, name: SwitchChainCommand.Method.walletSwitchEthereumChain.rawValue)
//        webViewConfig.userContentController.add(messageHandler, name: BrowserViewController.locationChangedEventName)
        //TODO extract like `Method.signTypedMessage.rawValue` when we have more than 1
//        webViewConfig.userContentController.add(messageHandler, name: TokenInstanceWebView.SetProperties.setActionProps)
        return webViewConfig
    }

// swiftlint:disable function_body_length
    fileprivate static func javaScriptForDappBrowser(address: String) -> String {
        return """
               //Space is needed here because it is sometimes cut off by websites. 

               const addressHex = "\(address)"
               const rpcURL = "\(KNGeneralProvider.shared.customRPC.endpoint)"
               const chainID = "\(KNGeneralProvider.shared.customRPC.chainID)"

               function executeCallback (id, error, value) {
                   KrystalWallet.executeCallback(id, error, value)
               }

               KrystalWallet.init(rpcURL, {
                   getAccounts: function (cb) { cb(null, [addressHex]) },
                   processTransaction: function (tx, cb){
                       console.log('signing a transaction', tx)
                       const { id = 8888 } = tx
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.signTransaction.postMessage({"name": "signTransaction", "object":     tx, id: id})
                   },
                   signMessage: function (msgParams, cb) {
                       const { data } = msgParams
                       const { id = 8888 } = msgParams
                       console.log("signing a message", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.signMessage.postMessage({"name": "signMessage", "object": { data }, id:    id} )
                   },
                   signPersonalMessage: function (msgParams, cb) {
                       const { data } = msgParams
                       const { id = 8888 } = msgParams
                       console.log("signing a personal message", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.signPersonalMessage.postMessage({"name": "signPersonalMessage", "object":  { data }, id: id})
                   },
                   signTypedMessage: function (msgParams, cb) {
                       const { data } = msgParams
                       const { id = 8888 } = msgParams
                       console.log("signing a typed message", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.signTypedMessage.postMessage({"name": "signTypedMessage", "object":     { data }, id: id})
                   },
                   ethCall: function (msgParams, cb) {
                       const data = msgParams
                       const { id = Math.floor((Math.random() * 100000) + 1) } = msgParams
                       console.log("eth_call", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.ethCall.postMessage({"name": "ethCall", "object": data, id: id})
                   },
                   walletAddEthereumChain: function (msgParams, cb) {
                       const data = msgParams
                       const { id = Math.floor((Math.random() * 100000) + 1) } = msgParams
                       console.log("walletAddEthereumChain", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.walletAddEthereumChain.postMessage({"name": "walletAddEthereumChain", "object": data, id: id})
                   },
                   walletSwitchEthereumChain: function (msgParams, cb) {
                       const data = msgParams
                       const { id = Math.floor((Math.random() * 100000) + 1) } = msgParams
                       console.log("walletSwitchEthereumChain", msgParams)
                       KrystalWallet.addCallback(id, cb)
                       webkit.messageHandlers.walletSwitchEthereumChain.postMessage({"name": "walletSwitchEthereumChain", "object": data, id: id})
                   },
                   enable: function() {
                      return new Promise(function(resolve, reject) {
                          //send back the coinbase account as an array of one
                          resolve([addressHex])
                      })
                   }
               }, {
                   address: addressHex,
                   networkVersion: "0x" + parseInt(chainID).toString(16) || null
               })

               web3.setProvider = function () {
                   console.debug('KrystalWallet Wallet - overrode web3.setProvider')
               }

               web3.eth.defaultAccount = addressHex

               web3.version.getNetwork = function(cb) {
                   cb(null, chainID)
               }

              web3.eth.getCoinbase = function(cb) {
               return cb(null, addressHex)
             }
             window.ethereum = web3.currentProvider
               
             // So we can detect when sites use History API to generate the page location. Especially common with React and similar frameworks
             ;(function() {
               var pushState = history.pushState;
               var replaceState = history.replaceState;

               history.pushState = function() {
                 pushState.apply(history, arguments);
                 window.dispatchEvent(new Event('locationchange'));
               };

               history.replaceState = function() {
                 replaceState.apply(history, arguments);
                 window.dispatchEvent(new Event('locationchange'));
               };

               window.addEventListener('popstate', function() {
                 window.dispatchEvent(new Event('locationchange'))
               });
             })();

             """
    }

    fileprivate static func contentBlockingRulesJson() -> String {
        //TODO read from TokenScript, when it's designed and available
        let whiteListedUrls = [
            "https://unpkg.com/",
            "^tokenscript-resource://",
            "^http://stormbird.duckdns.org:8080/api/getChallenge$",
            "^http://stormbird.duckdns.org:8080/api/checkSignature"
        ]
        //Blocks everything, except the whitelisted URL patterns
        var json = """
                   [
                       {
                           "trigger": {
                               "url-filter": ".*"
                           },
                           "action": {
                               "type": "block"
                           }
                       }
                   """
        for each in whiteListedUrls {
            json += """
                    ,
                    {
                        "trigger": {
                            "url-filter": "\(each)"
                        },
                        "action": {
                            "type": "ignore-previous-rules"
                        }
                    }
                    """
        }
        json += "]"
        return json
    }
}

extension WKWebViewConfiguration: WKURLSchemeHandler {
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        if urlSchemeTask.request.url?.path != nil {
            if let fileExtension = urlSchemeTask.request.url?.pathExtension, fileExtension == "otf", let nameWithoutExtension = urlSchemeTask.request.url?.deletingPathExtension().lastPathComponent {
                //TODO maybe good to fail with didFailWithError(error:)
                guard let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: fileExtension) else { return }
                guard let data = try? Data(contentsOf: url) else { return }
                //mimeType doesn't matter. Blocking is done based on how browser intends to use it
                let response = URLResponse(url: urlSchemeTask.request.url!, mimeType: "font/opentype", expectedContentLength: data.count, textEncodingName: nil)
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                return
            }
        }
        //TODO maybe good to fail:
        //urlSchemeTask.didFailWithError(error:)
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        //Do nothing
    }
}

private struct HackToAllowUsingSafaryExtensionCodeInDappBrowser {
    private static func javaScriptForSafaryExtension() -> String {
        var js = String()

        if let filepath = Bundle.main.path(forResource: "config", ofType: "js"), let content = try? String(contentsOfFile: filepath) {
            js += content
        }
        if let filepath = Bundle.main.path(forResource: "helpers", ofType: "js"), let content = try? String(contentsOfFile: filepath) {
            js += content
        }
        return js
    }

    static func injectJs(to webViewConfig: WKWebViewConfiguration) {
        func encodeStringTo64(fromString: String) -> String? {
            let plainData = fromString.data(using: .utf8)
            return plainData?.base64EncodedString(options: [])
        }
        var js = javaScriptForSafaryExtension()
        js += """
                const overridenElementsForKrystalWalletExtension = new Map();
                function runOnStart() {
                    function applyURLsOverriding(options, url) {
                        let elements = overridenElementsForKrystalWalletExtension.get(url);
                        if (typeof elements != 'undefined') {
                            overridenElementsForKrystalWalletExtension(elements)
                        }

                        overridenElementsForKrystalWalletExtension.set(url, retrieveAllURLs(document, options));
                    }

                    const url = document.URL;
                    applyURLsOverriding(optionsByDefault, url);
                }

                if(document.readyState !== 'loading') {
                    runOnStart();
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        runOnStart()
                    });
                }
        """

        let jsStyle = """
            javascript:(function() {
            var parent = document.getElementsByTagName('body').item(0);
            var script = document.createElement('script');
            script.type = 'text/javascript';
            script.innerHTML = window.atob('\(encodeStringTo64(fromString: js)!)');
            parent.appendChild(script)})()
        """

        let userScript = WKUserScript(source: jsStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webViewConfig.userContentController.addUserScript(userScript)
    }
}
