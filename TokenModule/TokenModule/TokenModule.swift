//
//  TokenModule.swift
//  TokenModule
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import UIKit
import Utilities
import BaseWallet
import Dependencies
import Services
import ChainModule

public class TokenModule {
    static let bundle = Bundle(for: TokenModule.self)
    public static var apiURL: String!
    
    public static func createTokenDetailViewController(address: String, chain: ChainType, currencyMode: CurrencyMode) -> UIViewController? {
        let vc = TokenDetailViewController.instantiateFromNib()
        let viewModel = TokenDetailViewModel(address: address, chain: chain, currencyMode: currencyMode)
        vc.viewModel = viewModel
        return vc
    }
    
    public static func openTokenSearchV2(on viewController: UIViewController, walletAddress: String, chainID: Int, onTokenSelected: (ChainModule.Token) -> ()) {
        let viewModel = TokenSearchV2ViewModel(walletAddress: walletAddress, chainID: chainID)
        let vc = TokenSearchV2ViewController.instantiateFromNib()
        vc.viewModel = viewModel
        viewController.present(vc, animated: true, completion: nil)
    }
    
    public static func openSearchToken(walletAddress: String, chainID: Int, on viewController: UIViewController, onSelectToken: ((SearchToken) -> Void)?) {
        let viewModel = SearchTokenViewModel()
        let vc = SearchTokenViewController.instantiateFromNib()
        vc.viewModel = viewModel
        vc.modalPresentationStyle = .fullScreen
        vc.onSelectTokenCompletion = onSelectToken
        
        viewController.present(vc, animated: true, completion: nil)
    }
}
