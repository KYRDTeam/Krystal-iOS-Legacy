//
//  WKScriptMessage.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 12/12/2022.
//

import Foundation
import WebKit

extension WKScriptMessage {
    var json: [String: Any] {
        if let string = body as? String,
            let data = string.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let dict = object as? [String: Any] {
            return dict
        } else if let object = body as? [String: Any] {
            return object
        }
        return [:]
    }
}
