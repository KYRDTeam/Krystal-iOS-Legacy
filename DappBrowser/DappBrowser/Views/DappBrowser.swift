//
//  DappBrowser.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 13/12/2022.
//

import Foundation
import Utilities
import UIKit

public class DappBrowser {
    
    public static func openURL(navigationController: UINavigationController, url: URL) {
        let browser = BrowserViewController.instantiateFromNib()
        browser.loadViewIfNeeded()
        browser.loadNewPage(url: url)
        navigationController.pushViewController(browser, animated: true)
    }
    
}
