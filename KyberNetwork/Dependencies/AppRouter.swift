//
//  AppRouter.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import SwapModule
import Dependencies

class AppRouter: AppRouterProtocol {
    
    func openWalletList() {
        
    }
    
    func openChainList() {
        
    }
    
    func createSwapViewController() -> UIViewController {
        return SwapModule.createSwapViewController()
    }
}
