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
import AppState
import BaseModule

class StakingConfirmClaimPopupViewModel: BaseViewModel, TxConfirmViewModelProtocol {
    
    var title: String {
        return Strings.confirmClaim
    }
    
    var chain: ChainType {
        return ChainType.make(chainID: pendingUnstake.chainID) ?? .all
    }
    
    var action: String {
        return Strings.youAreClaiming
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
        return Strings.confirm
    }
    
    var rows: [TxInfoRowData] {
        return [
            .init(title: Strings.networkFee,
                  value: networkFee,
                  rightButtonTitle: Strings.edit.uppercased(),
                  rightButtonClick: { [weak self] in
                      self?.onSelectOpenSetting?()
                  })
        ]
    }
    
    var isRequesting: Bool = false
    
    var onError: (String) -> Void = { _ in }
    var onSuccess: (PendingTxInfo) -> Void = { _ in }
    var onSelectOpenSetting: (() -> ())?
    var onDataChanged: (() -> ())?
    
    var quoteTokenDetail: TokenDetailInfo?
    let pendingUnstake: PendingUnstake
    let earnService = EarnServices()
    var setting: TxSettingObject = .default
    
    init(pendingUnstake: PendingUnstake) {
        self.pendingUnstake = pendingUnstake
    }
    
    var networkFee: String {
        return "\(feeString) \(feeUSDString)"
    }
    
    var transactionFee: BigInt {
        if let basic = setting.basic {
            return setting.gasLimit * GasPriceManager.shared.getGasPrice(gasType: basic.gasType, chain: currentChain)
          } else if let advance = setting.advanced {
            return setting.gasLimit * advance.maxFee
          }
        return BigInt(0)
    }
    
    var feeString: String {
        let string: String = NumberFormatUtils.gasFee(value: transactionFee)
        return "\(string) \(AppState.shared.currentChain.quoteToken())"
    }
    
    var quoteTokenUsdPrice: Double {
        return quoteTokenDetail?.markets["usd"]?.price ?? 0
    }
    
    var feeUSDString: String {
        let usd = self.transactionFee * BigInt(quoteTokenUsdPrice * pow(10, 18)) / BigInt(10).power(18)
        let valueString = NumberFormatUtils.gasFee(value: usd)
        return "(~ $\(valueString))"
    }

    func onTapConfirm() {
        let param = EarnParamBuilderFactory
            .create(platform: .init(name: pendingUnstake.platform.name))
            .buildClaimTxParam(pendingUnstake: pendingUnstake)
        earnService.buildClaimTx(param: param) { [weak self] result in
            switch result {
            case .success(let txObject):
                self?.sendTx(txObject: txObject)
            case .failure(let error):
                self?.onError(TxErrorParser.parse(error: error).message)
            }
        }
    }
    
    func sendTx(txObject: TxObject) {
        TransactionManager.txProcessor.process(address: currentAddress, chain: currentChain, txObject: txObject, setting: setting) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let txResult):
                let pendingTx = PendingClaimTxInfo(pendingUnstake: self.pendingUnstake, legacyTx: txResult.legacyTx, eip1559Tx: txResult.eip1559Tx, chain: self.currentChain, date: Date(), hash: txResult.hash)
                TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                self.onSuccess(pendingTx)
            case .failure(let error):
                self.onError(error.message)
            }
        }
    }
    
    func onSettingChanged(settingObject: TxSettingObject) {
        setting = settingObject
    }

    func getQuoteTokenPrice() {
        TokenService().getTokenDetail(address: currentChain.customRPC().quoteTokenAddress, chainPath: currentChain.customRPC().apiChainPath) { [weak self] tokenDetail in
            self?.quoteTokenDetail = tokenDetail
            self?.onDataChanged?()
        }
    }
    
}
