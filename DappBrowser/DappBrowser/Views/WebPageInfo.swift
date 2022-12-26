//
//  PageInfo.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 15/12/2022.
//

import Foundation

struct WebPageInfo {
    var name: String?
    var url: String?
    
    var icon: String? {
        return "https://www.google.com/s2/favicons?sz=128&domain=\(self.url ?? "")/"
    }
}
