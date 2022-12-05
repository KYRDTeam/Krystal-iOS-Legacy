//
//  TransactionModule.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import FittedSheets
import UIKit

public class ModuleTransaction {
    
    public static func openTxRate(vc: UIViewController, currentRate: Int, txHash: String, delegate: RateTransactionPopupDelegate) {
        let popup = RateTxPopup.instantiateFromNib()
        popup.currentRate = currentRate
        popup.txHash = txHash
        popup.delegate = delegate
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(490)], options: .init(pullBarHeight: 0))
        vc.present(sheet, animated: true)
    }
    
}
