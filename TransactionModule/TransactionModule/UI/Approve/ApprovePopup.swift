//
//  ApprovePopup.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 19/12/2022.
//

import Foundation
import UIKit
import BigInt
import BaseWallet
import FittedSheets

public class ApprovePopup {
    
    public struct ApproveParam {
        public var symbol: String
        public var tokenAddress: String
        public var remain: BigInt
        public var toAddress: String
        public var chain: ChainType
        public var gasLimit: BigInt
        
        public init(symbol: String, tokenAddress: String, remain: BigInt, toAddress: String, chain: ChainType, gasLimit: BigInt) {
            self.symbol = symbol
            self.tokenAddress = tokenAddress
            self.remain = remain
            self.toAddress = toAddress
            self.chain = chain
            self.gasLimit = gasLimit
        }
    }
    
    public static func show(on vc: UIViewController, param: ApproveParam, onSuccess: @escaping (_ hash: String) -> ()) {
        let vm = ApproveTokenViewModel(symbol: param.symbol, tokenAddress: param.tokenAddress, remain: param.remain, toAddress: param.toAddress, chain: param.chain)
        let viewController = ApproveTokenViewController(viewModel: vm)
        viewController.updateGasLimit(param.gasLimit)
        viewController.onApproveSent = { hash in
            onSuccess(hash)
        }
        let sheet = SheetViewController(controller: viewController, sizes: [.intrinsic], options: .init(pullBarHeight: 0))
        sheet.allowPullingPastMaxHeight = false
        vc.present(sheet, animated: true)
    }
    
}
