//
//  TxConfirmViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 08/11/2022.
//

import Foundation
import BaseWallet
import BaseModule
import UIKit

public protocol TxConfirmViewModelProtocol: AnyObject {
    var title: String { get }
    var setting: TxSettingObject { get }
    var chain: ChainType { get }
    var action: String { get }
    var tokenIconURL: String { get }
    var tokenAmountString: String { get }
    var platformName: String { get }
    var buttonTitle: String { get }
    var rows: [TxInfoRowData] { get }
    var isRequesting: Bool { get set }
    var onError: (String) -> Void { get set }
    var onSuccess: (PendingTxInfo) -> Void { get set }
    var onSelectOpenSetting: (() -> ())? { get set }
    var onDataChanged: (() -> ())? { get set }
    
    func onTapConfirm()
    func onSettingChanged(settingObject: TxSettingObject)
}

public extension TxConfirmViewModelProtocol {
    
    var chainIcon: UIImage {
        return chain.squareIcon()
    }
    
    var chainName: String {
        return chain.chainName()
    }
    
}
