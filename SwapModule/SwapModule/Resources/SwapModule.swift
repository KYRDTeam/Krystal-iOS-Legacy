//
//  Bundle.swift
//  SwapModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation
import UIKit

public class SwapModule {
    static let bundle = Bundle(for: SwapModule.self)
    
    static func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
    
    public static func createSwapViewController() -> UIViewController {
        let viewModel = SwapV2ViewModel(actions: SwapV2ViewModelActions(
            onSelectSwitchChain: {
            
            }, onSelectOpenHistory: {
                
            }, openSwapConfirm: { _ in
                
            }, openApprove: { _, _ in
                
            }, openSettings: { _, _, _ in
                
            }))
        let vc = SwapV2ViewController.instantiateFromNib()
        vc.viewModel = viewModel
        return vc
    }
}
