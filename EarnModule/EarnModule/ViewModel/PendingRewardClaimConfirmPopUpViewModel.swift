//
//  PendingRewardClaimConfirmPopUpViewModel.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 12/12/2022.
//

import Foundation
import BaseModule
import TransactionModule
import Services
import BigInt
import Utilities

class PendingRewardClaimConfirmPopUpViewModel: BaseViewModel, TxConfirmViewModelProtocol {
    var title: String {
        return Strings.confirmClaim
    }
    
    var setting: TxSettingObject = .default
    
    var chain: ChainType {
        return ChainType.make(chainID: item.chain.id) ?? .all
    }
    
    var action: String {
        return Strings.youAreClaiming
    }
    
    var tokenIconURL: String {
        return item.rewardToken.tokenInfo.logo
    }
    
    var tokenAmountString: String {
        let amountString = BigInt(item.rewardToken.pendingReward.balance)?.shortString(decimals: item.rewardToken.tokenInfo.decimals) ?? "---"
        let amountDisplay = amountString == "0" ? "~0" : amountString
        return amountDisplay + " " + item.rewardToken.tokenInfo.symbol
    }
    
    var platformName: String {
        return item.platform.name
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
    
    func onTapConfirm() {
        sendTx(txObject: txObject)
    }
    
    func onSettingChanged(settingObject: TxSettingObject) {
        setting = settingObject
        onDataChanged?()
    }
    
    let item: RewardItem
    let txObject: TxObject
    
    init(item: RewardItem, txObject: TxObject) {
        self.item = item
        self.txObject = txObject
        if let gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16), gasLimit > 0 {
            setting.basic?.gasLimit = gasLimit
            onDataChanged?()
        }
    }
    
    var pendingUnstake: PendingUnstake {
        let platform = Platform(name: item.platform.name, logo: item.platform.logo)
        let extra = StakingExtraData(status: "")
        return PendingUnstake(chainID: item.chain.id, address: item.rewardToken.tokenInfo.address, symbol: item.rewardToken.tokenInfo.symbol, logo: item.rewardToken.tokenInfo.logo, balance: item.rewardToken.pendingReward.balance, decimals: item.rewardToken.tokenInfo.decimals, platform: platform, extraData: extra, priceUsd: 0)
    }
    
    func sendTx(txObject: TxObject) {
        TransactionManager.txProcessor.process(address: currentAddress, chain: chain, txObject: txObject, setting: setting) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let txResult):
                let trackingExtraData = ClaimTrackingExtraData(
                    token: self.item.rewardToken.tokenInfo.symbol,
                    amount: self.item.rewardToken.pendingReward.balance.toDouble() ?? 0,
                    amountUsd: 0
                )
                let pendingTx = PendingClaimTxInfo(pendingUnstake: self.pendingUnstake, legacyTx: txResult.legacyTx, eip1559Tx: txResult.eip1559Tx, chain: self.chain, date: Date(), hash: txResult.hash, trackingExtraData: trackingExtraData)
                TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                print(txResult)
                self.onSuccess(pendingTx)
            case .failure(let error):
                self.onError(error.message)
            }
        }
    }
    
    var networkFee: String {
        return "\(feeString) \(feeUSDString)"
    }
    
    var feeString: String {
        let string: String = NumberFormatUtils.gasFee(value: transactionFee)
        return "\(string) \(chain.quoteToken())"
    }
    
    var transactionFee: BigInt {
        if let basic = setting.basic {
            return setting.gasLimit * GasPriceManager.shared.getGasPrice(gasType: basic.gasType, chain: chain)
        } else if let advance = setting.advanced {
            return setting.gasLimit * advance.maxFee
        }
        return BigInt(0)
    }
    
    var feeUSDString: String {
        let usd = self.transactionFee * BigInt(quoteTokenUsdPrice * pow(10, 18)) / BigInt(10).power(18)
        let valueString = NumberFormatUtils.gasFee(value: usd)
        return "(~ $\(valueString))"
    }
    
    func onViewLoaded() {
        getQuoteTokenPrice()
    }
    
    var quoteTokenDetail: TokenDetailInfo?
    
    func getQuoteTokenPrice() {
        TokenService().getTokenDetail(address: chain.customRPC().quoteTokenAddress, chainPath: chain.customRPC().apiChainPath) { [weak self] tokenDetail in
            self?.quoteTokenDetail = tokenDetail
            self?.onDataChanged?()
        }
    }
    
    var quoteTokenUsdPrice: Double {
        return quoteTokenDetail?.markets["usd"]?.price ?? 0
    }
}
