//
//  KrystalScriptHandler.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 14/12/2022.
//

import Foundation
import WebKit
import Dependencies

class KrystalScriptHandler: NSObject, WKScriptMessageHandler {
    
    var navigationController: UINavigationController!
    
    func setNavigationController(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let json = message.json
        guard let method = json["methodName"] as? String else { return }
        switch method {
        case "openSwap":
            AppDependencies.router.openSwap()
        default:
            return
        }
    }
    
}
