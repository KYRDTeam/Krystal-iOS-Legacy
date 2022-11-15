//
//  StakingConfirmClaimPopup.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import TransactionModule
import Services
import Utilities
import BigInt

class StakingConfirmClaimPopup: TxConfirmViewModelProtocol {
    
    var title: String {
        return "Claim Confirm"
    }
    
    var chain: ChainType {
        return ChainType.make(chainID: pendingUnstake.chainID) ?? .all
    }
    
    var action: String {
        return "You are claiming"
    }
    
    var tokenIconURL: String {
        return pendingUnstake.logo
    }
    
    var tokenAmountString: String {
        let amount = BigInt(pendingUnstake.balance) ?? .zero
        let amountString = NumberFormatUtils.amount(value: amount, decimals: pendingUnstake.decimals)
        return amountString + " " + pendingUnstake.symbol
    }
    
    var platformName: String {
        return pendingUnstake.platform.name.uppercased()
    }
    
    var buttonTitle: String {
        return "Confirm"
    }
    
    var rows: [TxInfoRowData] {
        return [
            .init(title: "Network Fee",
                  value: "0,0 MATIC ($0,00)",
                  rightButtonTitle: "EDIT",
                  rightButtonClick: { [weak self] in
                      self?.onSelectOpenSetting?()
                  })
        ]
    }
    
    var isRequesting: Bool = false
    
    var onError: (String) -> Void = { _ in }
    
    var onSuccess: (PendingTxInfo) -> Void = { _ in }
    
    var onSelectOpenSetting: (() -> ())?
    
    let pendingUnstake: PendingUnstake
    let earnService = EarnServices()
    
    init(pendingUnstake: PendingUnstake) {
        self.pendingUnstake = pendingUnstake
    }
    
    private func buildClaimTxParams() -> JSONDictionary {
        return [:]
    }
    
    func onTapConfirm() {
        earnService.buildClaimTx(param: buildClaimTxParams()) { [weak self] result in
            switch result {
            case .success(let txObject):
                ()
            case .failure(let error):
                self?.onError(TxErrorParser.parse(error: error).message)
            }
        }
    }
    
    func onSettingChanged(settingObject: TxSettingObject) {
        
    }
    
    
}
